import SwiftUI

struct ShareCardView: View {
    @EnvironmentObject var cardService: BusinessCardService
    @StateObject private var sharingService: CardSharingService
    
    init() {
        _sharingService = StateObject(wrappedValue: CardSharingService(cardService: BusinessCardService()))
    }
    
    var body: some View {
        VStack {
            if let card = cardService.userCard {
                BusinessCardPreview(card: card, showFull: true, selectedImage: nil)
                    .padding()
                
                Button {
                    sharingService.copyLinkToClipboard(for: card)
                } label: {
                    Label("Copy Link", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Share Card")
        .overlay {
            if sharingService.showCopyConfirmation {
                Text("Link copied!")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
            }
        }
    }
}