import Foundation
import CoreNFC
import UIKit
import MessageUI
import FirebaseFirestore

class CardSharingService: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var error: Error?
    @Published var showShareSheet = false
    
    private var session: NFCNDEFReaderSession?
    private var cardService: BusinessCardService
    private let db = Firestore.firestore()
    
    init(cardService: BusinessCardService) {
        self.cardService = cardService
        super.init()
    }
    
    func updateCardService(_ newCardService: BusinessCardService) {
        self.cardService = newCardService
    }
    
    // MARK: - Text Message Sharing
    
    func generateShareText(from card: BusinessCard) -> String {
        return """
        🪪 Business Card from \(card.name)
        
        \(card.title)\(card.company.isEmpty ? "" : " at \(card.company)")
        
        📱 \(card.phone)
        📧 \(card.email)
        \(card.linkedin.isEmpty ? "" : "🔗 \(card.linkedin)\n")
        \(card.website.isEmpty ? "" : "🌐 \(card.website)\n")
        
        Add this card to your BumpIn contacts:
        bumpin://add-card/\(card.id)
        """
    }
    
    // MARK: - Card Processing
    
    func processSharedCardURL(_ url: URL) {
        print("Processing URL: \(url)")
        
        // Extract card ID from URL
        let urlString = url.absoluteString
        guard let cardId = urlString.components(separatedBy: "/").last else {
            print("Could not extract card ID from URL")
            return
        }
        
        print("Found card ID: \(cardId)")
        
        // Create a task to fetch the card
        Task {
            do {
                print("Fetching card from Firestore...")
                
                // Add retry logic for network issues
                var attempts = 0
                let maxAttempts = 3
                
                while attempts < maxAttempts {
                    do {
                        let snapshot = try await db.collection("cards").document(cardId).getDocument()
                        guard let data = snapshot.data() else {
                            print("No data found for card ID: \(cardId)")
                            return
                        }
                        
                        print("Card data found, decoding...")
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let card = try JSONDecoder().decode(BusinessCard.self, from: jsonData)
                        print("Successfully decoded card for: \(card.name)")
                        
                        // Post notification with the card
                        DispatchQueue.main.async {
                            print("Posting CardFound notification")
                            NotificationCenter.default.post(
                                name: Notification.Name("CardFound"),
                                object: nil,
                                userInfo: ["card": card]
                            )
                        }
                        return
                    } catch {
                        attempts += 1
                        if attempts >= maxAttempts {
                            print("Final error processing card after \(maxAttempts) attempts: \(error.localizedDescription)")
                            // Show error to user
                            DispatchQueue.main.async {
                                self.error = error
                                NotificationCenter.default.post(
                                    name: Notification.Name("CardError"),
                                    object: nil,
                                    userInfo: ["error": "Failed to load card. Please try again."]
                                )
                            }
                        } else {
                            print("Attempt \(attempts) failed, retrying...")
                            try await Task.sleep(nanoseconds: UInt64(1_000_000_000)) // Wait 1 second before retry
                        }
                    }
                }
            } catch {
                print("Error in card processing task: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.error = error
                    NotificationCenter.default.post(
                        name: Notification.Name("CardError"),
                        object: nil,
                        userInfo: ["error": "Failed to process card. Please check your internet connection and try again."]
                    )
                }
            }
        }
    }
    
    // MARK: - NFC Methods
    
    func startScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "NFC is not available on this device"])
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your phone near another device to share cards"
        session?.begin()
    }
    
    // MARK: - QR Code Methods
    
    func generateQRCode(from card: BusinessCard) -> UIImage? {
        let cardString = "bumpin://add-card/\(card.id)"
        print("Generating QR code for URL: \(cardString)")
        
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let data = cardString.data(using: .utf8)
        qrFilter.setValue(data, forKey: "inputMessage")
        
        guard let qrImage = qrFilter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQrImage = qrImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledQrImage, from: scaledQrImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func decodeQRCode(from image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        
        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options) else { return }
        
        let features = detector.features(in: ciImage)
        
        guard let qrFeature = features.first as? CIQRCodeFeature,
              let messageString = qrFeature.messageString else {
            return
        }
        
        print("Decoded QR code URL: \(messageString)")
        
        // Process URL to get card ID
        if let cardId = messageString.components(separatedBy: "/").last {
            Task {
                do {
                    print("Fetching card from QR code...")
                    let snapshot = try await db.collection("cards").document(cardId).getDocument()
                    guard let data = snapshot.data() else { return }
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let card = try JSONDecoder().decode(BusinessCard.self, from: jsonData)
                    print("Successfully decoded QR card for: \(card.name)")
                    
                    // Post notification with the card
                    DispatchQueue.main.async {
                        print("Posting CardFound notification from QR")
                        NotificationCenter.default.post(
                            name: Notification.Name("CardFound"),
                            object: nil,
                            userInfo: ["card": card]
                        )
                    }
                } catch {
                    print("Error processing QR card: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - NFCNDEFReaderSession Delegate

extension CardSharingService: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            self.error = error
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first,
              let payload = String(data: record.payload, encoding: .utf8),
              let cardId = payload.components(separatedBy: "/").last else {
            return
        }
        
        Task {
            do {
                let snapshot = try await db.collection("cards").document(cardId).getDocument()
                guard let data = snapshot.data() else { return }
                
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let card = try JSONDecoder().decode(BusinessCard.self, from: jsonData)
                
                try await cardService.addCard(card)
                DispatchQueue.main.async {
                    self.isScanning = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isScanning = false
                }
            }
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        DispatchQueue.main.async {
            self.isScanning = true
        }
    }
} 