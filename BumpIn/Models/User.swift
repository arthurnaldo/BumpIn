struct User: Codable, Identifiable {
    let id: String
    var username: String
    var card: BusinessCard?
    
    // For search functionality
    var searchableUsername: String {
        username.lowercased()
    }
} 