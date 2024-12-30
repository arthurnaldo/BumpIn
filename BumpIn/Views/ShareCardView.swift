import SwiftUI

struct ShareCardView: View {
    @EnvironmentObject var cardService: BusinessCardService
    @EnvironmentObject var userService: UserService
    @StateObject private var sharingService: CardSharingService
    
    init() {
        _sharingService = StateObject(wrappedValue: CardSharingService(cardService: BusinessCardService()))
    }
    
    var body: some View {
        VStack {
            if let card = cardService.userCard {
                BusinessCardPreview(card: card, showFull: true, selectedImage: nil)
                    .padding()
                
                if let currentUser = userService.currentUser {
                    Button {
                        sharingService.copyProfileLinkToClipboard(for: currentUser.username)
                    } label: {
                        Label("Share Profile", systemImage: "person.crop.circle.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Share")
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