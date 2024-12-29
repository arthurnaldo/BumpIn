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
        
        // Check if already connected
        let existingConnection = try await db.collection("users")
            .document(currentUser.uid)
            .collection("connections")
            .document(user.id)
            .getDocument()
        
        if existingConnection.exists {
            throw ConnectionError.alreadyConnected
        }
        
        // Only check outgoing requests (we sent to them)
        let outgoingSnapshot = try await db.collection("users")
            .document(user.id)
            .collection("connectionRequests")
            .whereField("fromUserId", isEqualTo: currentUser.uid)
            .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
            .getDocuments()
        
        if !outgoingSnapshot.documents.isEmpty {
            throw ConnectionError.requestAlreadyExists
        }
        
        // Get sender's username
        let senderDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        guard let senderData = senderDoc.data(),
              let senderUsername = senderData["username"] as? String else {
            throw ConnectionError.invalidRequest
        }
        
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
        
        let requestData = try JSONEncoder().encode(request)
        guard let dict = try JSONSerialization.jsonObject(with: requestData) as? [String: Any] else {
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
        
        // Update local state
        await MainActor.run {
            self.pendingRequests.append(request)
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
        // Check cache first
        if let cachedUser = await CacheManager.shared.getCachedUser(id: userId) {
            return cachedUser
        }
        
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data() else { return nil }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        var user = try JSONDecoder().decode(User.self, from: jsonData)
        
        // Fetch user's card
        if let cardDoc = try? await db.collection("cards")
            .document(userId)
            .getDocument(),
            let cardData = cardDoc.data() {
            let cardJsonData = try JSONSerialization.data(withJSONObject: cardData)
            user.card = try JSONDecoder().decode(BusinessCard.self, from: cardJsonData)
        }
        
        // Cache the user
        await CacheManager.shared.cacheUser(user)
        return user
    }
    
    func removeConnection(with userId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        
        let batch = db.batch()
        
        // Remove connection from current user's connections
        let userConnectionRef = db.collection("users")
            .document(currentUser.uid)
            .collection("connections")
            .document(userId)
        batch.deleteDocument(userConnectionRef)
        
        // Remove connection from other user's connections
        let otherUserConnectionRef = db.collection("users")
            .document(userId)
            .collection("connections")
            .document(currentUser.uid)
        batch.deleteDocument(otherUserConnectionRef)
        
        try await batch.commit()
        
        // Refresh connections list
        try await fetchConnections()
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
        
        // Remove existing listener if any
        requestsListener?.remove()
        
        // Listen for incoming requests
        requestsListener = db.collection("users")
            .document(currentUser.uid)
            .collection("connectionRequests")
            .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let snapshot = snapshot else {
                    print("❌ Error fetching requests: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                
                do {
                    let requests = try snapshot.documents.compactMap { doc -> ConnectionRequest? in
                        let data = try JSONSerialization.data(withJSONObject: doc.data())
                        return try JSONDecoder().decode(ConnectionRequest.self, from: data)
                    }
                    
                    print("📬 Found \(requests.count) pending requests")
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