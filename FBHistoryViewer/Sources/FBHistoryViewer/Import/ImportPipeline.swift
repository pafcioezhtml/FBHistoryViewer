import Foundation
import Observation

@Observable
final class ImportPipeline {
    var progress: ImportProgress = ImportProgress()
    var isImporting: Bool = false

    private var importTask: Task<Void, Never>?

    func start(exportRoot: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        importTask = Task { @MainActor in
            self.isImporting = true
            do {
                try await self.runImport(exportRoot: exportRoot)
                completion(.success(()))
            } catch is CancellationError {
                // silently cancelled
            } catch {
                completion(.failure(error))
            }
            self.isImporting = false
        }
    }

    func cancel() {
        importTask?.cancel()
    }

    // MARK: - Folder discovery

    /// Returns ALL Facebook activity roots found inside `selectedFolder`.
    ///
    /// Facebook data exports can have several layouts:
    ///   a) `facebook-name-date/your_facebook_activity/`  (standard zip extract)
    ///   b) `your_facebook_activity/`  (user unpacked directly)
    ///   c) `your_facebook_activity-2/`  (numbered variant — Facebook splits large exports)
    ///   d) Any of the above nested one level deeper (user picked a parent folder)
    ///
    /// This method scans up to two directory levels and collects every folder
    /// that looks like a valid activity root (contains `messages/`, `posts/`,
    /// or `comments_and_reactions/`), including all numbered variants.
    static func findActivityRoots(in selectedFolder: URL) -> [URL] {
        let fm = FileManager.default

        func isActivityRoot(_ url: URL) -> Bool {
            fm.fileExists(atPath: url.appendingPathComponent("messages").path) ||
            fm.fileExists(atPath: url.appendingPathComponent("posts").path) ||
            fm.fileExists(atPath: url.appendingPathComponent("comments_and_reactions").path)
        }

        func subdirs(of url: URL) -> [URL] {
            (try? fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            ))?.filter {
                (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }.sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
        }

        var roots: Set<URL> = []

        // Case 1: the selected folder itself is an activity root
        if isActivityRoot(selectedFolder) {
            roots.insert(selectedFolder)
            return Array(roots).sorted { $0.path < $1.path }
        }

        // Search immediate children and their children (two levels)
        for child in subdirs(of: selectedFolder) {
            if isActivityRoot(child) {
                roots.insert(child)
            } else {
                // e.g. child is `facebook-name-date/` — look inside it
                for grandchild in subdirs(of: child) {
                    if isActivityRoot(grandchild) {
                        roots.insert(grandchild)
                    }
                }
            }
        }

        return Array(roots).sorted { $0.path < $1.path }
    }

    // MARK: - Main import

    @MainActor
    private func runImport(exportRoot: URL) async throws {
        let activityRoots = ImportPipeline.findActivityRoots(in: exportRoot)
        guard !activityRoots.isEmpty else {
            throw ImportError.noActivityFolderFound(exportRoot.path)
        }

        let db = DatabaseManager.shared
        try db.eraseDatabase()

        // Phase 1: Discover ALL threads across ALL roots
        progress.phase = .discovering
        let categories: [(String, String)] = [
            (ThreadCategory.inbox.rawValue,    "inbox"),
            (ThreadCategory.archived.rawValue, "archived_threads"),
            (ThreadCategory.filtered.rawValue, "filtered_threads"),
            (ThreadCategory.requests.rawValue, "message_requests"),
            (ThreadCategory.e2ee.rawValue,     "e2ee_cutover"),
        ]

        // Group thread dirs by slug so we can merge data from multiple exports
        var threadsBySlug: [String: [(url: URL, category: String)]] = [:]

        for activityRoot in activityRoots {
            let messagesRoot = activityRoot.appendingPathComponent("messages")
            for (category, dirName) in categories {
                let catURL = messagesRoot.appendingPathComponent(dirName)
                guard FileManager.default.fileExists(atPath: catURL.path) else { continue }
                let contents = (try? FileManager.default.contentsOfDirectory(
                    at: catURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: .skipsHiddenFiles
                )) ?? []
                for url in contents {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                       isDir.boolValue {
                        let slug = url.lastPathComponent
                        threadsBySlug[slug, default: []].append((url: url, category: category))
                    }
                }
            }
        }
        progress.totalThreads = threadsBySlug.count

        // Phase 2: Import messages — merge all dirs for the same slug
        progress.phase = .messages
        let threads = Array(threadsBySlug.values)
        let msgImporter = MessageImporter(dbQueue: db.dbQueue)
        try await msgImporter.importAll(threadGroups: threads) { [weak self] update in
            DispatchQueue.main.async {
                self?.progress.completedThreads = update.completed
                self?.progress.totalMessages += update.addedMessages
            }
        }

        try Task.checkCancellation()

        // Phase 3–6: Posts / group posts / likes / comments from ALL roots
        progress.phase = .posts
        let postImporter    = PostImporter(dbQueue: db.dbQueue)
        let groupImporter   = GroupPostImporter(dbQueue: db.dbQueue)
        let likeImporter    = LikeImporter(dbQueue: db.dbQueue)
        let commentImporter = CommentImporter(dbQueue: db.dbQueue)

        for activityRoot in activityRoots {
            let postsDir     = activityRoot.appendingPathComponent("posts")
            let groupsDir    = activityRoot.appendingPathComponent("groups")
            let reactionsDir = activityRoot.appendingPathComponent("comments_and_reactions")

            progress.totalPosts += try await postImporter.importAll(postsDirectory: postsDir)

            try Task.checkCancellation()
            progress.phase = .groupPosts
            progress.totalPosts += try await groupImporter.importAll(groupsDirectory: groupsDir)

            try Task.checkCancellation()
            progress.phase = .likes
            progress.totalLikes += try await likeImporter.importAll(reactionsDirectory: reactionsDir)

            try Task.checkCancellation()
            progress.phase = .comments
            progress.totalComments += try await commentImporter.importAll(reactionsDirectory: reactionsDir)
        }

        // Phase 7: Profile (import from first root that has personal_information/)
        progress.phase = .profile
        let profileImporter = ProfileImporter(dbQueue: db.dbQueue)
        for activityRoot in activityRoots {
            let exportParent = activityRoot.deletingLastPathComponent()
            let profileInfoPath = exportParent
                .appendingPathComponent("personal_information")
                .appendingPathComponent("profile_information")
                .appendingPathComponent("profile_information.json")
            if FileManager.default.fileExists(atPath: profileInfoPath.path) {
                try await profileImporter.importProfile(activityRoot: activityRoot)
                break
            }
        }

        try Task.checkCancellation()

        // Phase 8: Write import_state
        progress.phase = .finishing
        let threadCount  = threadsBySlug.count
        let messageCount = progress.totalMessages
        let totalPosts   = progress.totalPosts
        let totalLikes   = progress.totalLikes

        try await db.dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO import_state
                        (id, import_date, export_root, thread_count, message_count, post_count, like_count)
                    VALUES (1, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    Int64(Date().timeIntervalSince1970),
                    exportRoot.path,
                    threadCount,
                    messageCount,
                    totalPosts,
                    totalLikes,
                ]
            )
        }

        progress.phase = .done
    }
}

enum ImportError: LocalizedError {
    case noActivityFolderFound(String)

    var errorDescription: String? {
        switch self {
        case .noActivityFolderFound(let path):
            return """
                Could not find Facebook activity data in:
                \(path)

                Make sure you selected a valid Facebook data export folder.
                """
        }
    }
}
