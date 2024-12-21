import Foundation

struct ConnectionRequest: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let fromUsername: String
    let toUsername: String
    let status: RequestStatus
    let timestamp: Date
    
    enum RequestStatus: String, Codable {
        case pending
        case accepted
        case rejected
    }
} 