import Foundation

actor CacheManager {
    static let shared = CacheManager()
    
    private var userCache: [String: (user: User, timestamp: Date)] = [:]
    private var cardCache: [String: (card: BusinessCard, timestamp: Date)] = [:]
    private let cacheLifetime: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    func cacheUser(_ user: User) {
        userCache[user.id] = (user, Date())
    }
    
    func getCachedUser(id: String) -> User? {
        guard let cached = userCache[id],
              Date().timeIntervalSince(cached.timestamp) < cacheLifetime else {
            userCache[id] = nil
            return nil
        }
        return cached.user
    }
    
    func cacheCard(_ card: BusinessCard) {
        cardCache[card.id] = (card, Date())
    }
    
    func getCachedCard(id: String) -> BusinessCard? {
        guard let cached = cardCache[id],
              Date().timeIntervalSince(cached.timestamp) < cacheLifetime else {
            cardCache[id] = nil
            return nil
        }
        return cached.card
    }
    
    func clearCache() {
        userCache.removeAll()
        cardCache.removeAll()
    }
} 