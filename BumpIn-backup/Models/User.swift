struct User: Codable, Identifiable, Hashable {
    let id: String
    var username: String
    var card: BusinessCard?
    
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
} 