import Foundation
import SwiftUI
import UIKit

class CardSharingService: ObservableObject {
    private let cardService: BusinessCardService
    @Published var showCopyConfirmation = false
    
    init(cardService: BusinessCardService) {
        self.cardService = cardService
    }
    
    func generateShareableLink(for card: BusinessCard) -> String {
        return "bumpin://add-card/\(card.id)"
    }
    
    func copyLinkToClipboard(for card: BusinessCard) {
        let link = generateShareableLink(for: card)
        UIPasteboard.general.string = link
        showCopyConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showCopyConfirmation = false
        }
    }
} 