import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class BusinessCardService: ObservableObject {
    @Published var userCard: BusinessCard?
    @Published var contacts: [BusinessCard] = []
    @Published var recentContacts: [BusinessCard] = []
    
    private let db = Firestore.firestore()
    
    func saveCard(_ card: BusinessCard, userId: String) async throws {
        let data = try JSONEncoder().encode(card)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode card"])
        }
        
        try await db.collection("cards").document(userId).setData(dict)
    }
    
    func fetchUserCard(userId: String) async throws -> BusinessCard? {
        let document = try await db.collection("cards").document(userId).getDocument()
        guard let data = document.data() else { return nil }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(BusinessCard.self, from: jsonData)
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
} 