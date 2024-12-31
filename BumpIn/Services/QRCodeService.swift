import Foundation
import CoreImage.CIFilterBuiltins
import UIKit
import FirebaseStorage
import FirebaseAuth

class QRCodeService {
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    private var cache: [String: UIImage] = [:]
    private let storage = Storage.storage()
    
    func generateQRCode(from string: String, size: CGFloat = 200) -> UIImage? {
        if let cached = cache[string] {
            return cached
        }
        
        filter.message = Data(string.utf8)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scale = size / outputImage.extent.width
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        guard let scaledImage = outputImage.transformed(by: transform) else { return nil }
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        let image = UIImage(cgImage: cgImage)
        cache[string] = image
        return image
    }
    
    func generateAndSaveProfileQRCode(for username: String) async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let qrCode = generateProfileQRCode(for: username),
              let imageData = qrCode.pngData() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate QR code"])
        }
        
        let storageRef = storage.reference()
        let qrCodeRef = storageRef.child("qr_codes/\(currentUser.uid).png")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        
        _ = try await qrCodeRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await qrCodeRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func generateProfileQRCode(for username: String, size: CGFloat = 200) -> UIImage? {
        let profileLink = "bumpin://profile/\(username)"
        return generateQRCode(from: profileLink, size: size)
    }
} 