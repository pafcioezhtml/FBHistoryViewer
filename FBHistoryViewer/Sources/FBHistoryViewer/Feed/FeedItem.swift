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
