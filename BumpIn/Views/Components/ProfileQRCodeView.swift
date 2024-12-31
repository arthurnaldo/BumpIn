import SwiftUI

struct ProfileQRCodeView: View {
    let username: String
    private let qrCodeService = QRCodeService()
    @State private var qrCode: UIImage?
    
    var body: some View {
        VStack(spacing: 20) {
            if let qrCode = qrCode {
                Image(uiImage: qrCode)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundColor(.gray)
            }
            
            Text("@\(username)")
                .font(.headline)
            
            Text("Scan to view profile")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .onAppear {
            if qrCode == nil {
                qrCode = qrCodeService.generateProfileQRCode(for: username)
            }
        }
    }
} 