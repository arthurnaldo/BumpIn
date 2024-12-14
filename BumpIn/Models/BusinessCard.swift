import SwiftUI

struct BusinessCard: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var title: String = ""
    var company: String = ""
    var email: String = ""
    var phone: String = ""
    var linkedin: String = ""
    var website: String = ""
    var profileImageURL: String?
    var colorScheme: CardColorScheme = CardColorScheme()
}

struct CardColorScheme: Codable {
    var primary: Color = Color(red: 0.1, green: 0.3, blue: 0.5)
    var secondary: Color = Color(red: 0.2, green: 0.4, blue: 0.6)
} 