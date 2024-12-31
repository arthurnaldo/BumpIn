struct User: Identifiable, Codable, Hashable {
    let id: String
    var username: String
    var card: BusinessCard?
    var qrCodeURL: String?
    
    // For search functionality
    var searchableUsername: String {
        username.lowercased()
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case card
        case qrCodeURL
    }
} 