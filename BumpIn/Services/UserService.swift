import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var currentUser: User?
    @Published var searchResults: [User] = []
    @Published var isSearching = false
    @Published var blockedUsers: Set<String> = []
    
    private let cache = CacheManager.shared
    
    // Username validation rules
    private struct UsernameRules {
        static let minLength = 3
        static let maxLength = 30
        static let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._")
        static let forbiddenUsernames = [
            "admin", "support", "help", "moderator", "mod", "system",
            "bumpin", "official", "staff", "team", "security"
        ]
        
        static func validate(_ username: String) throws {
            // Check length
            guard username.count >= minLength else {
                throw ValidationError.tooShort
            }
            guard username.count <= maxLength else {
                throw ValidationError.tooLong
            }
            
            // Check if username contains only allowed characters
            let usernameSet = CharacterSet(charactersIn: username)
            guard allowedCharacters.isSuperset(of: usernameSet) else {
                throw ValidationError.invalidCharacters
            }
            
            // Check if username starts/ends with allowed characters
            guard !username.hasPrefix(".") && !username.hasPrefix("_") &&
                  !username.hasSuffix(".") && !username.hasSuffix("_") else {
                throw ValidationError.invalidStartOrEnd
            }
            
            // Check for consecutive special characters
            guard !username.contains("..") && !username.contains("__") &&
                  !username.contains("._") && !username.contains("_.") else {
                throw ValidationError.consecutiveSpecialCharacters
            }
            
            // Check reserved usernames
            guard !forbiddenUsernames.contains(username) else {
                throw ValidationError.reserved
            }
        }
    }
    
    enum ValidationError: LocalizedError {
        case tooShort
        case tooLong
        case invalidCharacters
        case invalidStartOrEnd
        case consecutiveSpecialCharacters
        case reserved
        case alreadyTaken
        
        var errorDescription: String? {
            switch self {
            case .tooShort:
                return "Username must be at least \(UsernameRules.minLength) characters long"
            case .tooLong:
                return "Username cannot exceed \(UsernameRules.maxLength) characters"
            case .invalidCharacters:
                return "Username can only contain letters, numbers, dots, and underscores"
            case .invalidStartOrEnd:
                return "Username cannot start or end with dots or underscores"
            case .consecutiveSpecialCharacters:
                return "Username cannot contain consecutive dots or underscores"
            case .reserved:
                return "This username is reserved"
            case .alreadyTaken:
                return "This username is already taken"
            }
        }
    }
    
    func validateUsername(_ username: String) async throws {
        // First apply validation rules
        try UsernameRules.validate(username.lowercased())
        
        // Then check availability
        let isAvailable = try await isUsernameAvailable(username)
        if !isAvailable {
            throw ValidationError.alreadyTaken
        }
    }
    
    func createUser(username: String) async throws {
        guard let authUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        // Validate username before creating user
        try await validateUsername(username)
        
        let user = User(
            id: authUser.uid,
            username: username.lowercased(), // Always store lowercase
            card: nil
        )
        
        let userData = try JSONEncoder().encode(user)
        guard let dict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode user"])
        }
        
        try await db.collection("users").document(authUser.uid).setData(dict)
        currentUser = user
    }
    
    func fetchCurrentUser() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        currentUser = try JSONDecoder().decode(User.self, from: jsonData)
    }
    
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username.lowercased())
            .getDocuments()
        return snapshot.documents.isEmpty
    }
    
    // Search users by username
    func searchUsers(query: String) async throws {
        guard !query.isEmpty else {
            await MainActor.run { searchResults = [] }
            return
        }
        
        await MainActor.run { isSearching = true }
        defer { Task { @MainActor in isSearching = false } }
        
        let lowercaseQuery = query.lowercased()
        let snapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("username", isLessThan: lowercaseQuery + "z")
            .limit(to: 20)
            .getDocuments()
        
        var users: [User] = []
        for doc in snapshot.documents {
            // Check cache first
            if let cachedUser = await cache.getCachedUser(id: doc.documentID) {
                users.append(cachedUser)
                continue
            }
            
            let data = try JSONSerialization.data(withJSONObject: doc.data())
            var user = try JSONDecoder().decode(User.self, from: data)
            
            // Don't show current user or blocked users in search results
            guard user.id != currentUser?.id && !blockedUsers.contains(user.id) else {
                continue
            }
            
            // Fetch user's card
            if let cardDoc = try? await db.collection("cards")
                .document(user.id)
                .getDocument(),
                let cardData = cardDoc.data() {
                let cardJsonData = try JSONSerialization.data(withJSONObject: cardData)
                user.card = try JSONDecoder().decode(BusinessCard.self, from: cardJsonData)
            }
            
            // Cache the user
            await cache.cacheUser(user)
            users.append(user)
        }
        
        await MainActor.run {
            searchResults = users
        }
    }
    
    // MARK: - Blocking Functions
    func blockUser(_ userId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let blockData: [String: Any] = [
            "userId": userId,
            "timestamp": Date()
        ]
        
        // Add to blocked collection
        try await db.collection("users")
            .document(currentUser.uid)
            .collection("blockedUsers")
            .document(userId)
            .setData(blockData)
        
        // Remove any existing connections
        try await db.collection("users")
            .document(currentUser.uid)
            .collection("connections")
            .document(userId)
            .delete()
        
        await MainActor.run {
            blockedUsers.insert(userId)
        }
    }
    
    func unblockUser(_ userId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        try await db.collection("users")
            .document(currentUser.uid)
            .collection("blockedUsers")
            .document(userId)
            .delete()
        
        await MainActor.run {
            blockedUsers.remove(userId)
        }
    }
    
    func fetchBlockedUsers() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let snapshot = try await db.collection("users")
            .document(currentUser.uid)
            .collection("blockedUsers")
            .getDocuments()
        
        let userIds = Set(snapshot.documents.compactMap { $0.data()["userId"] as? String })
        
        await MainActor.run {
            blockedUsers = userIds
        }
    }
} 