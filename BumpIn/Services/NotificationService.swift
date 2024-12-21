import FirebaseMessaging
import UserNotifications
import FirebaseFirestore
import FirebaseAuth

class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var hasPermission = false
    private let db = Firestore.firestore()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.hasPermission = granted
                if granted {
                    self.updateFCMToken()
                }
            }
        }
    }
    
    private func updateFCMToken() {
        Messaging.messaging().token { [weak self] token, error in
            if let token = token {
                self?.saveFCMToken(token)
            }
        }
    }
    
    private func saveFCMToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            try? await db.collection("users").document(userId).updateData([
                "fcmToken": token
            ])
        }
    }
    
    func sendConnectionRequestNotification(to userId: String, fromUsername: String) async throws {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let fcmToken = userDoc.data()?["fcmToken"] as? String else { return }
        
        // Send FCM notification
        let url = URL(string: "YOUR_CLOUD_FUNCTION_URL")! // You'll need to create a Cloud Function
        let payload: [String: Any] = [
            "token": fcmToken,
            "notification": [
                "title": "New Connection Request",
                "body": "@\(fromUsername) wants to connect with you"
            ],
            "data": [
                "type": "connection_request",
                "fromUsername": fromUsername
            ]
        ]
        
        // Send the notification via your Cloud Function
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to send notification"])
        }
    }
} 