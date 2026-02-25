// Schema.swift
// Table name constants used across the codebase.

enum TableName {
    static let threads = "threads"
    static let messages = "messages"
    static let reactions = "reactions"
    static let posts = "posts"
    static let likes = "likes"
    static let comments = "comments"
    static let importState = "import_state"
}

enum ThreadCategory: String {
    case inbox = "inbox"
    case archived = "archived_threads"
    case filtered = "filtered_threads"
    case requests = "message_requests"
    case e2ee = "e2ee_cutover"
}

enum PostSource: String {
    case timeline = "timeline"
    case group = "group"
}
