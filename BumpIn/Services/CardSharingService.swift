import Foundation
import SwiftUI
import UIKit

class CardSharingService: ObservableObject {
    private let cardService: BusinessCardService
    @Published var showCopyConfirmation = false
    
    init(cardService: BusinessCardService) {
        self.cardService = cardService
    }
    
    func generateProfileLink(for username: String) -> String {
        return "bumpin://profile/\(username)"
    }
    
    func copyProfileLinkToClipboard(for username: String) {
        let link = generateProfileLink(for: username)
        UIPasteboard.general.string = link
        showCopyConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showCopyConfirmation = false
        }
    }
} 