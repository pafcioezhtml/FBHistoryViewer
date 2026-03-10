import Foundation

enum ImportPhase: String, CaseIterable {
    case discovering = "Discovering threads"
    case messages    = "Importing messages"
    case posts       = "Importing posts"
    case groupPosts  = "Importing group posts"
    case likes       = "Importing likes & reactions"
    case comments    = "Importing comments"
    case friends     = "Importing friends"
    case logins      = "Importing login activity"
    case searches       = "Importing search history"
    case notifications  = "Importing notifications"
    case visits         = "Importing visit history"
    case profile        = "Importing profile"
    case finishing   = "Finishing up"
    case done        = "Done"

    var displayName: String { rawValue }
}

struct ImportProgress {
    var phase: ImportPhase = .discovering
    var totalThreads: Int = 0
    var completedThreads: Int = 0
    var currentThreadName: String = ""
    var totalMessages: Int = 0
    var totalPosts: Int = 0
    var totalLikes: Int = 0
    var totalComments: Int = 0
    var totalFriends: Int = 0
    var totalLogins: Int = 0
    var totalSearches: Int = 0
    var totalNotifications: Int = 0
    var totalVisits: Int = 0
    var errorCount: Int = 0

    var overallFraction: Double {
        switch phase {
        case .discovering: return 0.0
        case .messages:
            guard totalThreads > 0 else { return 0.05 }
            return 0.05 + 0.70 * Double(completedThreads) / Double(totalThreads)
        case .posts:      return 0.75
        case .groupPosts: return 0.80
        case .likes:      return 0.85
        case .comments:   return 0.90
        case .friends:    return 0.91
        case .logins:     return 0.92
        case .searches:      return 0.93
        case .notifications: return 0.94
        case .visits:        return 0.95
        case .profile:       return 0.96
        case .finishing:  return 0.98
        case .done:       return 1.00
        }
    }
}
