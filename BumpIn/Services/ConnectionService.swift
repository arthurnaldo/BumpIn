import FirebaseFirestore
import FirebaseAuth

@MainActor
class ConnectionService: ObservableObject {
    private let db = Firestore.firestore()
    private let notificationService = NotificationService()
    @Published var connections: [User] = []
    @Published var pendingRequests: [ConnectionRequest] = []
    @Published var sentRequests: [ConnectionRequest] = []
    private var requestsListener: ListenerRegistration?
    
    func sendConnectionRequest(to user: User) async throws {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        print("🔄 Sending connection request:")
        print("- From user ID: \(currentUser.uid)")
        print("- To user ID: \(user.id)")
        
        // Prevent self-connection
        if currentUser.uid == user.id {
            print("❌ Attempted to send request to self")
            throw ConnectionError.invalidRequest
        }
        
        // Check if already connected
        let existingConnection = try await db.collection("users")
            .document(currentUser.uid)
            .collection("connections")
            .document(user.id)
            .getDocument()
        
        if existingConnection.exists {
            print("❌ Already connected")
            throw ConnectionError.alreadyConnected
        }
        
        // Check for existing requests
        let outgoingSnapshot = try await db.collection("users")
            .document(user.id)
            .collection("connectionRequests")
            .whereField("fromUserId", isEqualTo: currentUser.uid)
            .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
            .getDocuments()
        
        print("📝 Existing requests found: \(outgoingSnapshot.documents.count)")
        
        if !outgoingSnapshot.documents.isEmpty {
            print("❌ Request already exists")
            throw ConnectionError.requestAlreadyExists
        }
        
        // Get sender's username
        let senderDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        guard let senderData = senderDoc.data(),
              let senderUsername = senderData["username"] as? String else {
            print("❌ Could not get sender username")
            throw ConnectionError.invalidRequest
        }
        
        print("👤 Sender username: \(senderUsername)")
        print("👥 Recipient username: \(user.username)")
        
        // Create the request
        let request = ConnectionRequest(
            id: UUID().uuidString,
            fromUserId: currentUser.uid,
            toUserId: user.id,
            fromUsername: senderUsername,
            toUsername: user.username,
            status: .pending,
            timestamp: Date()
        )
        
        print("📨 Created request: \(request.id)")
        
        let requestData = try JSONEncoder().encode(request)
        guard let dict = try JSONSerialization.jsonObject(with: requestData) as? [String: Any] else {
            print("❌ Failed to encode request")
            throw ConnectionError.invalidRequest
        }
        
        // Use a batch write
        let batch = db.batch()
        
        // Add to recipient's requests
        let recipientRef = db.collection("users")
            .document(user.id)
            .collection("connectionRequests")
            .document(request.id)
        batch.setData(dict, forDocument: recipientRef)
        
        // Add to sender's sent requests
        let senderRef = db.collection("users")
            .document(currentUser.uid)
            .collection("sentRequests")
            .document(request.id)
        batch.setData(dict, forDocument: senderRef)
        
        try await batch.commit()
        print("✅ Request saved successfully")
        
        // Instead, add to sentRequests
        await MainActor.run {
            self.sentRequests.append(request)
        }
    }
    
    func handleConnectionRequest(_ request: ConnectionRequest, accept: Bool) async throws {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        let batch = db.batch()
        let status = accept ? ConnectionRequest.RequestStatus.accepted : ConnectionRequest.RequestStatus.rejected
        
        // Update in recipient's requests
        let recipientRef = db.collection("users")
            .document(currentUser.uid)
            .collection("connectionRequests")
            .document(request.id)
        batch.updateData(["status": status.rawValue], forDocument: recipientRef)
        
        // Update in sender's sent requests
        let senderRef = db.collection("users")
            .document(request.fromUserId)
            .collection("sentRequests")
            .document(request.id)
        batch.updateData(["status": status.rawValue], forDocument: senderRef)
        
        if accept {
            // Create connection for both users
            let connection: [String: Any] = [
                "userId": request.fromUserId,
                "username": request.fromUsername,
                "timestamp": Date()
            ]
            
            let userConnectionRef = db.collection("users")
                .document(currentUser.uid)
                .collection("connections")
                .document(request.fromUserId)
            batch.setData(connection, forDocument: userConnectionRef)
            
            let reverseConnection: [String: Any] = [
                "userId": currentUser.uid,
                "username": request.toUsername,
                "timestamp": Date()
            ]
            
            let otherUserConnectionRef = db.collection("users")
                .document(request.fromUserId)
                .collection("connections")
                .document(currentUser.uid)
            batch.setData(reverseConnection, forDocument: otherUserConnectionRef)
        }
        
        try await batch.commit()
        
        // Refresh lists
        try await fetchPendingRequests()
        try await fetchConnections()
    }
    
    func fetchPendingRequests() async throws {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        let snapshot = try await db.collection("users")
            .document(currentUser.uid)
            .collection("connectionRequests")
            .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let requests = try snapshot.documents.map { doc in
            let data = try JSONSerialization.data(withJSONObject: doc.data())
            return try JSONDecoder().decode(ConnectionRequest.self, from: data)
        }
        
        // Update on main thread
        self.pendingRequests = requests
    }
    
    func fetchConnections() async throws {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        let snapshot = try await db.collection("users")
            .document(currentUser.uid)
            .collection("connections")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let userIds = snapshot.documents.compactMap { doc -> String? in
            return doc.data()["userId"] as? String
        }
        
        var fetchedUsers: [User] = []
        for userId in userIds {
            if let user = try await fetchUser(userId: userId) {
                fetchedUsers.append(user)
            }
        }
        
        // Update on main thread
        self.connections = fetchedUsers
    }
    
    private func fetchUser(userId: String) async throws -> User? {
        print("🔄 Fetching user with ID: \(userId)")
        
        // Check cache first
        if let cachedUser = await CacheManager.shared.getCachedUser(id: userId) {
            print("✅ Found user in cache")
            return cachedUser
        }
        
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data() else {
            print("❌ No data found for user \(userId)")
            return nil
        }
        
        print("📄 Raw user data: \(data)")
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        print("🔄 Converting to JSON data")
        
        do {
            var user = try JSONDecoder().decode(User.self, from: jsonData)
            print("✅ Successfully decoded user")
            
            // Fetch user's card
            print("🔄 Fetching user's card")
            if let cardDoc = try? await db.collection("cards")
                .document(userId)
                .getDocument(),
                let cardData = cardDoc.data() {
                print("📄 Raw card data: \(cardData)")
                let cardJsonData = try JSONSerialization.data(withJSONObject: cardData)
                user.card = try JSONDecoder().decode(BusinessCard.self, from: cardJsonData)
                print("✅ Successfully decoded card")
            } else {
                print("⚠️ No card found for user")
            }
            
            // Cache the user
            await CacheManager.shared.cacheUser(user)
            print("✅ Cached user data")
            return user
        } catch {
            print("❌ Failed to decode user: \(error.localizedDescription)")
            print("❌ JSON data: \(String(data: jsonData, encoding: .utf8) ?? "invalid UTF8")")
            throw error
        }
    }
    
    func removeConnection(with userId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        let batch = db.batch()
        
        // Delete connection documents for both users
        let currentUserRef = db.collection("users").document(currentUser.uid).collection("connections").document(userId)
        let otherUserRef = db.collection("users").document(userId).collection("connections").document(currentUser.uid)
        
        // Delete any pending requests between the users
        let currentUserRequests = db.collection("users").document(currentUser.uid).collection("connectionRequests")
        let otherUserRequests = db.collection("users").document(userId).collection("connectionRequests")
        
        // Get all requests between these users
        let outgoingSnapshot = try await currentUserRequests
            .whereField("fromUserId", isEqualTo: userId)
            .getDocuments()
        
        let incomingSnapshot = try await otherUserRequests
            .whereField("fromUserId", isEqualTo: currentUser.uid)
            .getDocuments()
        
        // Delete connections
        batch.deleteDocument(currentUserRef)
        batch.deleteDocument(otherUserRef)
        
        // Delete all requests
        for doc in outgoingSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        for doc in incomingSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        
        // Commit all changes
        try await batch.commit()
        
        // Update local state
        await MainActor.run {
            connections.removeAll { $0.id == userId }
            pendingRequests.removeAll { $0.fromUserId == userId || $0.toUserId == userId }
        }
    }
    
    func hasPendingRequest(for userId: String) async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("connectionRequests")
            .whereField("fromUserId", isEqualTo: currentUser.uid)
            .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
            .limit(to: 1)
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    func hasIncomingRequest(from userId: String) async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        let snapshot = try await db.collection("users")
            .document(currentUser.uid)
            .collection("connectionRequests")
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
            .limit(to: 1)
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    func findPendingRequest(from userId: String) async throws -> ConnectionRequest? {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        let snapshot = try await db.collection("users")
            .document(currentUser.uid)
            .collection("connectionRequests")
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = snapshot.documents.first else { return nil }
        
        let data = try JSONSerialization.data(withJSONObject: doc.data())
        return try JSONDecoder().decode(ConnectionRequest.self, from: data)
    }
    
    func cancelConnectionRequest(to userId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        let batch = db.batch()
        
        // Delete from recipient's requests
        let recipientRequests = try await db.collection("users")
            .document(userId)
            .collection("connectionRequests")
            .whereField("fromUserId", isEqualTo: currentUser.uid)
            .getDocuments()
        
        // Delete from sender's sent requests
        let senderRequests = try await db.collection("users")
            .document(currentUser.uid)
            .collection("sentRequests")
            .whereField("toUserId", isEqualTo: userId)
            .getDocuments()
        
        for doc in recipientRequests.documents {
            batch.deleteDocument(doc.reference)
        }
        
        for doc in senderRequests.documents {
            batch.deleteDocument(doc.reference)
        }
        
        try await batch.commit()
        
        // Update local state
        await MainActor.run {
            self.pendingRequests.removeAll { $0.toUserId == userId }
        }
    }
    
    func startRequestsListener() {
        guard let currentUser = Auth.auth().currentUser else { return }
        print("🎧 Starting requests listener for user: \(currentUser.uid)")
        
        // Remove existing listener if any
        requestsListener?.remove()
        
        // Listen for incoming requests only
        requestsListener = db.collection("users")
            .document(currentUser.uid)
            .collection("connectionRequests")
            .whereField("toUserId", isEqualTo: currentUser.uid)
            .whereField("fromUserId", isNotEqualTo: currentUser.uid)
            .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let snapshot = snapshot else {
                    print("❌ Error fetching requests: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                
                do {
                    let requests = try snapshot.documents.compactMap { doc -> ConnectionRequest? in
                        let data = try JSONSerialization.data(withJSONObject: doc.data())
                        let request = try JSONDecoder().decode(ConnectionRequest.self, from: data)
                        
                        // Double check we're not including self-requests
                        guard request.fromUserId != currentUser.uid else {
                            print("⚠️ Filtered out self-request")
                            return nil
                        }
                        
                        return request
                    }
                    
                    print("📬 Found \(requests.count) pending incoming requests")
                    self?.pendingRequests = requests
                } catch {
                    print("❌ Error decoding requests: \(error.localizedDescription)")
                }
            }
    }
    
    func stopRequestsListener() {
        requestsListener?.remove()
        requestsListener = nil
    }
    
    enum ConnectionError: LocalizedError {
        case requestAlreadyExists
        case requestNotFound
        case invalidRequest
        case alreadyConnected
        
        var errorDescription: String? {
            switch self {
            case .requestAlreadyExists:
                return "A connection request already exists"
            case .requestNotFound:
                return "Connection request not found"
            case .invalidRequest:
                return "Invalid connection request"
            case .alreadyConnected:
                return "You are already connected with this user"
            }
        }
    }
    
    enum AuthError: LocalizedError {
        case notAuthenticated
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "User not authenticated"
            }
        }
    }
} 