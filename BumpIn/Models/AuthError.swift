import Foundation

enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case networkError
    case unknown
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidCredentials:
            return "Invalid credentials"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        case .userNotFound:
            return "User data not found"
        }
    }
} 