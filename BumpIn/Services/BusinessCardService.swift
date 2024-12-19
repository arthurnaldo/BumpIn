import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

@MainActor
class BusinessCardService: ObservableObject {
    @Published var userCard: BusinessCard?
    @Published var contacts: [BusinessCard] = []
    @Published var recentContacts: [BusinessCard] = []
    
    private let db = Firestore.firestore()
    
    func saveCard(_ card: BusinessCard, userId: String) async throws {
        var updatedCard = card
        updatedCard.userId = userId
        
        let data = try JSONEncoder().encode(updatedCard)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode card"])
        }
        
        try await db.collection("cards").document(userId).setData(dict)
        userCard = updatedCard
    }
    
    func fetchUserCard(userId: String) async throws -> BusinessCard? {
        let document = try await db.collection("cards").document(userId).getDocument()
        guard let data = document.data() else { 
            userCard = nil
            return nil 
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let card = try JSONDecoder().decode(BusinessCard.self, from: jsonData)
        userCard = card
        return card
    }
    
    func addContact(card: BusinessCard, userId: String) async throws {
        let data = try JSONEncoder().encode(card)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode card"])
        }
        
        try await db.collection("users").document(userId).collection("contacts").addDocument(data: dict)
    }
    
    func fetchContacts(userId: String) async throws {
        let snapshot = try await db.collection("users").document(userId).collection("contacts").getDocuments()
        
        var fetchedContacts: [BusinessCard] = []
        for document in snapshot.documents {
            let jsonData = try JSONSerialization.data(withJSONObject: document.data())
            let contact = try JSONDecoder().decode(BusinessCard.self, from: jsonData)
            fetchedContacts.append(contact)
        }
        
        contacts = fetchedContacts
        recentContacts = Array(fetchedContacts.prefix(3))
    }
    
    func addCard(_ card: BusinessCard) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Check if trying to add own card
        if card.id == userCard?.id {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot add your own card"])
        }
        
        // Check for duplicates
        if contacts.contains(where: { $0.id == card.id }) {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Card already in contacts"])
        }
        
        try await addContact(card: card, userId: currentUser.uid)
        contacts.append(card)
        
        if recentContacts.count >= 3 {
            recentContacts.removeLast()
        }
        recentContacts.insert(card, at: 0)
    }
    
    func removeContact(cardId: String, userId: String) async throws {
        let snapshot = try await db.collection("users").document(userId).collection("contacts")
            .whereField("id", isEqualTo: cardId)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return }
        try await document.reference.delete()
        
        if let index = contacts.firstIndex(where: { $0.id == cardId }) {
            contacts.remove(at: index)
        }
        if let index = recentContacts.firstIndex(where: { $0.id == cardId }) {
            recentContacts.remove(at: index)
        }
    }
    
    func uploadCardProfilePicture(cardId: String, image: UIImage) async throws -> String {
        // Check if user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("Authenticated user ID: \(currentUser.uid)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let storageRef = Storage.storage().reference()
        let profilePicRef = storageRef.child("card_profile_pictures").child("\(cardId).jpg")
        
        print("Attempting to upload to path: \(profilePicRef.fullPath)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            let _ = try await profilePicRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await profilePicRef.downloadURL()
            
            // Update the card document with the profile picture URL on the main actor
            await MainActor.run {
                Task {
                    try? await db.collection("cards").document(cardId).updateData([
                        "profilePictureURL": downloadURL.absoluteString
                    ])
                }
            }
            
            print("Successfully uploaded image to: \(downloadURL.absoluteString)")
            return downloadURL.absoluteString
        } catch {
            print("Storage error: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("Storage error domain: \(nsError.domain), code: \(nsError.code)")
            }
            throw error
        }
    }
    
    func fetchCardById(_ cardId: String) async throws -> BusinessCard? {
        print("\n🔍 FETCH CARD ATTEMPT")
        print("1️⃣ Checking Firestore for card: \(cardId)")
        
        let snapshot = try await db.collection("cards")
            .whereField("id", isEqualTo: cardId)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            print("❌ No card found with ID: \(cardId)")
            return nil
        }
        
        let data = document.data()
        print("2️⃣ Found data: \(data)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let card = try JSONDecoder().decode(BusinessCard.self, from: jsonData)
            print("✅ Successfully decoded card: \(card.name)")
            return card
        } catch {
            print("❌ Error decoding card: \(error.localizedDescription)")
            throw error
        }
    }
} 