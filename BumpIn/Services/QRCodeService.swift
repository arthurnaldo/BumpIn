import Foundation
import CoreImage.CIFilterBuiltins
import UIKit
import FirebaseStorage
import FirebaseAuth

class QRCodeService {
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    private let storage = Storage.storage()
    
    func generateQRCode(from string: String, size: CGFloat = 200) -> UIImage? {
        filter.message = Data(string.utf8)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scale = size / outputImage.extent.width
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func generateProfileQRCode(for username: String) -> UIImage? {
        let profileLink = "bumpin://profile/\(username)"
        return generateQRCode(from: profileLink)
    }
    
    func generateAndSaveProfileQRCode(for username: String) async throws -> String {
        guard let qrImage = generateProfileQRCode(for: username),
              let imageData = qrImage.pngData() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate QR code"])
        }
        
        let filename = "qr_codes/\(username).png"
        let qrRef = storage.reference().child(filename)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        
        _ = try await qrRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await qrRef.downloadURL()
        return downloadURL.absoluteString
    }
} 