import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserService: ObservableObject {
    private let db = Firestore.firestore()
    private let qrCodeService = QRCodeService()
    @Published var currentUser: User?
    @Published var searchResults: [User] = []
    @Published var isSearching = false
    @Published var blockedUsers: Set<String> = []
    private var signupUsername: String?  // Add storage for signup username
    private var isCreatingUser = false  // Add flag for user creation state
    private var pendingUser: User?  // Add storage for pending user
    
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
        isCreatingUser = true  // Set flag when starting user creation
        defer { isCreatingUser = false }  // Reset flag when done
        
        print("📝 Starting createUser with username: \(username)")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found in createUser")
            throw AuthError.notAuthenticated
        }
        
        print("👤 User ID: \(userId)")
        signupUsername = username
        print("✅ Stored signup username: \(username)")
        
        // Validate username before creating user
        try await validateUsername(username)
        print("✅ Username validated successfully")
        
        // Generate and save QR code
        let qrCodeURL = try await qrCodeService.generateAndSaveProfileQRCode(for: username)
        print("✅ Generated QR code URL: \(qrCodeURL)")
        
        // Create the user object
        let user = User(
            id: userId,
            username: username.lowercased(),
            card: BusinessCard(
                id: UUID().uuidString,
                userId: userId,
                name: "",
                title: "",
                company: "",
                email: "",
                phone: "",
                linkedin: "",
                website: "",
                aboutMe: "",
                profilePictureURL: nil,
                qrCodeURL: qrCodeURL,
                colorScheme: CardColorScheme(),
                fontStyle: .modern,
                layoutStyle: .classic,
                textScale: 1.0,
                backgroundStyle: .gradient,
                showSymbols: false,
                isVertical: false
            ),
            qrCodeURL: qrCodeURL
        )
        
        print("✅ Created user object with username: \(user.username)")
        
        // Store the pending user before Firestore operations
        pendingUser = user
        print("✅ Stored pending user object")
        
        // Encode and save to Firestore
        let userData = try JSONEncoder().encode(user)
        let cardData = try JSONEncoder().encode(user.card)
        
        guard let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any],
              let cardDict = try JSONSerialization.jsonObject(with: cardData) as? [String: Any] else {
            print("❌ Failed to encode user or card data")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode data"])
        }
        
        print("✅ Encoded user and card data")
        
        // Use a batch write to save both user and card
        let batch = db.batch()
        let userRef = db.collection("users").document(userId)
        let cardRef = db.collection("cards").document(userId)
        
        batch.setData(userDict, forDocument: userRef)
        batch.setData(cardDict, forDocument: cardRef)
        
        try await batch.commit()
        print("✅ Successfully saved user and card to Firestore")
        
        // Set currentUser after successful write
        await MainActor.run {
            self.currentUser = user
            print("✅ Set currentUser after successful write")
        }
    }
    
    func updateUser(_ user: User) async throws {
        let data = try JSONEncoder().encode(user)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        try await db.collection("users").document(user.id).setData(dict, merge: true)
        if user.id == Auth.auth().currentUser?.uid {
            self.currentUser = user
        }
    }
    
    func fetchCurrentUser() async throws {
        print("\n🔍 Starting fetchCurrentUser")
        
        guard let userId = Auth.auth().currentUser?.uid,
              let email = Auth.auth().currentUser?.email else {
            print("❌ No authenticated user found in fetchCurrentUser")
            throw AuthError.notAuthenticated
        }
        
        // If we have a pending user, use it
        if let pending = pendingUser {
            print("✅ Found pending user: \(pending.username)")
            self.currentUser = pending
            pendingUser = nil  // Clear pending user
            return
        }
        
        // If we're currently creating a user, wait a bit
        if isCreatingUser {
            print("⏳ Waiting for user creation to complete...")
            for _ in 0..<5 {  // Try up to 5 times
                try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 second delay
                if !isCreatingUser {
                    break
                }
            }
        }
        
        print("👤 User ID: \(userId)")
        print("📧 Email: \(email)")
        
        // First check if we already have the user in memory
        if let existingUser = currentUser {
            print("✅ Found existing user in memory: \(existingUser.username)")
            return
        }
        print("ℹ️ No user found in memory, checking Firestore")
        
        let document = try await db.collection("users").document(userId).getDocument()
        if let data = document.data() {
            print("✅ Found user data in Firestore")
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let user = try JSONDecoder().decode(User.self, from: jsonData)
            print("✅ Successfully decoded user: \(user.username)")
            await MainActor.run { 
                self.currentUser = user
                print("✅ Set currentUser from Firestore data")
            }
        } else {
            print("⚠️ No user data found in Firestore")
            // Add a small delay and try one more time
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            let retryDocument = try await db.collection("users").document(userId).getDocument()
            if let retryData = retryDocument.data() {
                print("✅ Found user data in Firestore on retry")
                let jsonData = try JSONSerialization.data(withJSONObject: retryData)
                let user = try JSONDecoder().decode(User.self, from: jsonData)
                print("✅ Successfully decoded user: \(user.username)")
                await MainActor.run { 
                    self.currentUser = user
                    print("✅ Set currentUser from Firestore data")
                }
                return
            }
            
            if let username = signupUsername {
                print("✅ Found signup username: \(username), creating new user")
                // Create an empty card
                let card = BusinessCard(
                    id: UUID().uuidString,
                    userId: userId,
                    name: "",
                    title: "",
                    company: "",
                    email: email,
                    phone: "",
                    linkedin: "",
                    website: "",
                    aboutMe: "",
                    profilePictureURL: nil,
                    qrCodeURL: nil,
                    colorScheme: CardColorScheme(),
                    fontStyle: .modern,
                    layoutStyle: .classic,
                    textScale: 1.0,
                    backgroundStyle: .gradient,
                    showSymbols: false,
                    isVertical: false
                )
                
                // Save the empty card
                let cardData = try JSONEncoder().encode(card)
                guard let cardDict = try JSONSerialization.jsonObject(with: cardData) as? [String: Any] else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode card"])
                }
                
                // Generate QR code
                let qrCodeURL = try await qrCodeService.generateAndSaveProfileQRCode(for: username)
                
                let user = User(
                    id: userId,
                    username: username,
                    card: card,
                    qrCodeURL: qrCodeURL
                )
                
                let userData = try JSONEncoder().encode(user)
                guard let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode user"])
                }
                
                // Use a batch write to save both user and card
                let batch = db.batch()
                let userRef = db.collection("users").document(userId)
                let cardRef = db.collection("cards").document(userId)
                
                batch.setData(userDict, forDocument: userRef)
                batch.setData(cardDict, forDocument: cardRef)
                
                try await batch.commit()
                await MainActor.run { self.currentUser = user }
            } else {
                print("❌ No signup username found")
                throw AuthError.userNotFound
            }
        }
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
            await MainActor.run { self.searchResults = [] }
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
    
    func ensureUserHasQRCode() async throws {
        guard let currentUser = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        if currentUser.qrCodeURL == nil {
            // Generate and save QR code
            let qrCodeURL = try await qrCodeService.generateAndSaveProfileQRCode(for: currentUser.username)
            
            var updatedUser = currentUser
            updatedUser.qrCodeURL = qrCodeURL
            
            try await updateUser(updatedUser)
            
            // Fetch the updated user data to ensure we have the latest
            try await fetchCurrentUser()
        }
    }
} 