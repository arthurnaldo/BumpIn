import Foundation
import CoreNFC
import UIKit

class CardSharingService: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var error: Error?
    
    private var session: NFCNDEFReaderSession?
    private var cardService: BusinessCardService
    
    init(cardService: BusinessCardService) {
        self.cardService = cardService
        super.init()
    }
    
    func updateCardService(_ newCardService: BusinessCardService) {
        self.cardService = newCardService
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
        guard let cardData = try? JSONEncoder().encode(card),
              let cardString = String(data: cardData, encoding: .utf8) else {
            return nil
        }
        
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
    
    func decodeQRCode(from image: UIImage) -> BusinessCard? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options) else { return nil }
        
        let features = detector.features(in: ciImage)
        
        guard let qrFeature = features.first as? CIQRCodeFeature,
              let messageString = qrFeature.messageString,
              let data = messageString.data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(BusinessCard.self, from: data)
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
              let data = payload.data(using: .utf8),
              let card = try? JSONDecoder().decode(BusinessCard.self, from: data) else {
            return
        }
        
        Task {
            do {
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