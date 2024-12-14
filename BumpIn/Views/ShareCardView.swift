import SwiftUI
import CoreNFC
import MessageUI

struct ShareCardView: View {
    @EnvironmentObject var cardService: BusinessCardService
    @StateObject private var sharingService: CardSharingService
    @State private var isVertical = false
    @State private var interactionState = 0 // 0: card, 1: about me, 2: QR code
    @State private var showingPrompt = true
    @State private var showingScanner = false
    @State private var showingMessageComposer = false
    @State private var showingShareFallback = false
    @State private var shareText = ""
    
    init() {
        _sharingService = StateObject(wrappedValue: CardSharingService(cardService: BusinessCardService()))
    }
    
    private func calculateSize(for geometry: GeometryProxy) -> CGSize {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let padding: CGFloat = 32
        
        if isVertical {
            return CGSize(
                width: screenHeight - padding * 2,
                height: screenWidth - padding * 2
            )
        } else {
            return CGSize(
                width: screenWidth - padding * 2,
                height: (screenWidth - padding * 2) / 1.8
            )
        }
    }
    
    private func getPromptText() -> String {
        if isVertical {
            return "Hold phones close together to share cards"
        }
        
        switch interactionState {
        case 0:
            return "Tap the card to view more details"
        case 1:
            return "Tap again to show QR code"
        case 2:
            return "Tap to return to card view, or rotate to portrait (top right button) to share via NFC"
        default:
            return ""
        }
    }
    
    private func handleMessageShare(card: BusinessCard) {
        if MFMessageComposeViewController.canSendText() {
            showingMessageComposer = true
        } else {
            // Fallback for simulator or when messages are not available
            shareText = sharingService.generateShareText(from: card)
            showingShareFallback = true
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    if let card = cardService.userCard {
                        let size = calculateSize(for: geometry)
                        
                        // Top Action Buttons
                        VStack {
                            HStack {
                                // QR Scanner Button
                                Button(action: { showingScanner = true }) {
                                    Image(systemName: "qrcode.viewfinder")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding(.leading, 20)
                                
                                Spacer()
                                
                                // Text Message Share Button
                                Button(action: { handleMessageShare(card: card) }) {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding(.horizontal, 8)
                                
                                // Orientation Toggle Button
                                Button(action: {
                                    withAnimation {
                                        if !isVertical && interactionState == 2 {
                                            isVertical = true
                                            showingPrompt = true
                                        } else {
                                            isVertical.toggle()
                                            if !isVertical {
                                                interactionState = 0
                                            }
                                            showingPrompt = true
                                        }
                                    }
                                    
                                    if isVertical {
                                        sharingService.startScanning()
                                    }
                                }) {
                                    Image(systemName: isVertical ? "iphone.circle.fill" : (interactionState == 2 ? "rectangle.portrait.fill" : "rectangle"))
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 20)
                            }
                            .padding(.top, 10)
                            
                            Spacer()
                        }
                        .zIndex(1)
                        
                        // Card Content
                        ZStack {
                            // Card View
                            if interactionState == 0 || isVertical {
                                BusinessCardPreview(card: card, showFull: true, selectedImage: nil)
                                    .frame(width: size.width, height: size.height)
                                    .background(
                                        LinearGradient(
                                            colors: [card.colorScheme.primary, card.colorScheme.secondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(15)
                            }
                            
                            // About Me View
                            if interactionState == 1 && !isVertical {
                                VStack(spacing: 20) {
                                    Text(card.aboutMe)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                                .frame(width: size.width, height: size.height)
                                .background(
                                    LinearGradient(
                                        colors: [card.colorScheme.primary, card.colorScheme.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(15)
                            }
                            
                            // QR Code View
                            if interactionState == 2 && !isVertical {
                                VStack(spacing: 20) {
                                    if let qrImage = sharingService.generateQRCode(from: card) {
                                        Image(uiImage: qrImage)
                                            .interpolation(.none)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: min(size.width, size.height) * 0.6)
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(10)
                                    }
                                    
                                    Text("Scan to add card")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .frame(width: size.width, height: size.height)
                                .background(
                                    LinearGradient(
                                        colors: [card.colorScheme.primary, card.colorScheme.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(15)
                            }
                        }
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .rotationEffect(Angle(degrees: isVertical ? 90 : 0), anchor: .center)
                        .animation(
                            Animation.spring(response: 0.6, dampingFraction: 0.8),
                            value: isVertical
                        )
                        .onTapGesture {
                            if !isVertical {
                                withAnimation {
                                    interactionState = (interactionState + 1) % 3
                                    showingPrompt = true
                                }
                            }
                        }
                        
                        // Prompt Overlay
                        if showingPrompt {
                            VStack {
                                Spacer()
                                Text(getPromptText())
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)
                                    .padding(.bottom, 50)
                            }
                            .transition(.move(edge: .bottom))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        showingPrompt = false
                                    }
                                }
                            }
                        }
                        
                        // NFC Error Display
                        if isVertical, let error = sharingService.error {
                            VStack {
                                Text(error.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)
                            }
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.9)
                        }
                    } else {
                        Text("Create a card to share")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Share Card")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                sharingService.updateCardService(cardService)
            }
            .sheet(isPresented: $showingScanner) {
                QRCodeScannerView(cardService: cardService)
            }
            .sheet(isPresented: $showingMessageComposer) {
                if let card = cardService.userCard {
                    MessageComposerView(messageText: sharingService.generateShareText(from: card))
                }
            }
            .alert("Share Card", isPresented: $showingShareFallback) {
                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = shareText
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Messages are not available on this device. You can copy the share text to clipboard instead.")
            }
        }
    }
}

struct QRCodeView: View {
    let card: BusinessCard
    @StateObject private var sharingService: CardSharingService
    @Environment(\.dismiss) private var dismiss
    
    init(card: BusinessCard, cardService: BusinessCardService) {
        self.card = card
        _sharingService = StateObject(wrappedValue: CardSharingService(cardService: cardService))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let qrImage = sharingService.generateQRCode(from: card) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                } else {
                    Image(systemName: "qrcode")
                        .resizable()
                        .frame(width: 200, height: 200)
                        .padding()
                }
                
                Text("Scan this code to add card")
                    .font(.headline)
                    .padding()
            }
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NFCScannerView: View {
    @ObservedObject var cardService: BusinessCardService
    @StateObject private var sharingService: CardSharingService
    @Environment(\.dismiss) private var dismiss
    
    init(cardService: BusinessCardService) {
        self.cardService = cardService
        _sharingService = StateObject(wrappedValue: CardSharingService(cardService: cardService))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "iphone.circle")
                    .font(.system(size: 100))
                    .padding()
                
                Text("Hold phones close together")
                    .font(.headline)
                    .padding()
                
                Text("Make sure NFC is enabled on both devices")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                
                if let error = sharingService.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Share Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                sharingService.startScanning()
            }
        }
    }
}

struct MessageComposerView: UIViewControllerRepresentable {
    let messageText: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = messageText
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposerView
        
        init(_ parent: MessageComposerView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    let mockCardService = BusinessCardService()
    mockCardService.userCard = BusinessCard(
        name: "John Doe",
        title: "Software Engineer",
        company: "Tech Corp",
        email: "john@example.com",
        phone: "123-456-7890",
        linkedin: "linkedin.com/in/johndoe",
        website: "johndoe.com",
        aboutMe: "Passionate about creating great software",
        colorScheme: CardColorScheme(
            primary: Color(red: 0.1, green: 0.3, blue: 0.5),
            secondary: Color(red: 0.2, green: 0.4, blue: 0.6)
        )
    )
    
    return ShareCardView()
        .environmentObject(mockCardService)
} 