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
    
    init(id: String, username: String, card: BusinessCard? = nil, qrCodeURL: String? = nil) {
        self.id = id
        self.username = username
        self.card = card
        self.qrCodeURL = qrCodeURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        card = try container.decodeIfPresent(BusinessCard.self, forKey: .card)
        qrCodeURL = try container.decodeIfPresent(String.self, forKey: .qrCodeURL)
    }
} 