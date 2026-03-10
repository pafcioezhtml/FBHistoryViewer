import Foundation

enum FeedItem: Identifiable {
    case post(PostRecord)
    case like(LikeRecord)
    case comment(CommentRecord)

    var id: String {
        switch self {
        case .post(let r):    return "post-\(r.id ?? 0)"
        case .like(let r):    return "like-\(r.id ?? 0)"
        case .comment(let r): return "comment-\(r.id ?? 0)"
        }
    }

    var timestamp: Int64 {
        switch self {
        case .post(let r):    return r.timestamp
        case .like(let r):    return r.timestamp
        case .comment(let r): return r.timestamp
        }
    }
}

enum FeedFilter: String, CaseIterable {
    case all      = "All"
    case posts    = "Posts"
    case likes    = "Likes"
    case comments = "Comments"
}

enum PostSubFilter: String, CaseIterable, Identifiable {
    case own   = "own"
    case wall  = "wall"
    case group = "group"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .own:   return "My Posts"
        case .wall:  return "Wall Posts"
        case .group: return "Group Posts"
        }
    }

    var icon: String {
        switch self {
        case .own:   return "doc.text.fill"
        case .wall:  return "person.fill.viewfinder"
        case .group: return "person.3.fill"
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .own:   return .teal
        case .wall:  return .blue
        case .group: return .purple
        }
    }
}

import SwiftUI
