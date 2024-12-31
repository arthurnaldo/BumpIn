import Foundation

enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case networkError
    case unknown
    
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
        }
    }
} 