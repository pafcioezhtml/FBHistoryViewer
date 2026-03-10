import GRDB

enum Migrations {
    static func registerMigrations(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS threads (
                    id                INTEGER PRIMARY KEY AUTOINCREMENT,
                    thread_slug       TEXT NOT NULL UNIQUE,
                    thread_path       TEXT NOT NULL,
                    category          TEXT NOT NULL,
                    title             TEXT NOT NULL,
                    is_group_chat     INTEGER NOT NULL DEFAULT 0,
                    participant_names TEXT NOT NULL,
                    message_count     INTEGER NOT NULL DEFAULT 0,
                    first_message_at  INTEGER,
                    last_message_at   INTEGER
                )
                """)

            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_threads_category ON threads(category)
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_threads_last_message ON threads(last_message_at DESC)
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS messages (
                    id              INTEGER PRIMARY KEY AUTOINCREMENT,
                    thread_id       INTEGER NOT NULL REFERENCES threads(id) ON DELETE CASCADE,
                    sender_name     TEXT NOT NULL,
                    timestamp_ms    INTEGER NOT NULL,
                    content         TEXT,
                    has_photos      INTEGER NOT NULL DEFAULT 0,
                    has_videos      INTEGER NOT NULL DEFAULT 0,
                    has_audio       INTEGER NOT NULL DEFAULT 0,
                    has_gifs        INTEGER NOT NULL DEFAULT 0,
                    has_files       INTEGER NOT NULL DEFAULT 0,
                    has_share       INTEGER NOT NULL DEFAULT 0,
                    share_url       TEXT,
                    reaction_count  INTEGER NOT NULL DEFAULT 0
                )
                """)

            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_messages_thread_id ON messages(thread_id)
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp_ms)
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_name)
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_messages_day ON messages((timestamp_ms / 86400000))
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS reactions (
                    id              INTEGER PRIMARY KEY AUTOINCREMENT,
                    message_id      INTEGER NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
                    reaction_emoji  TEXT NOT NULL,
                    actor_name      TEXT NOT NULL
                )
                """)

            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_reactions_message_id ON reactions(message_id)
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_reactions_emoji ON reactions(reaction_emoji)
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS posts (
                    id           INTEGER PRIMARY KEY AUTOINCREMENT,
                    source       TEXT NOT NULL,
                    timestamp    INTEGER NOT NULL,
                    title        TEXT,
                    content      TEXT,
                    external_url TEXT,
                    group_name   TEXT,
                    has_media    INTEGER NOT NULL DEFAULT 0
                )
                """)

            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_posts_timestamp ON posts(timestamp DESC)
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS likes (
                    id            INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp     INTEGER NOT NULL,
                    title         TEXT NOT NULL,
                    reaction_type TEXT NOT NULL
                )
                """)

            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_likes_timestamp ON likes(timestamp DESC)
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS comments (
                    id           INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp    INTEGER NOT NULL,
                    title        TEXT,
                    comment_text TEXT
                )
                """)

            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_comments_timestamp ON comments(timestamp DESC)
                """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS import_state (
                    id             INTEGER PRIMARY KEY CHECK (id = 1),
                    import_date    INTEGER NOT NULL,
                    export_root    TEXT NOT NULL,
                    thread_count   INTEGER NOT NULL DEFAULT 0,
                    message_count  INTEGER NOT NULL DEFAULT 0,
                    post_count     INTEGER NOT NULL DEFAULT 0,
                    like_count     INTEGER NOT NULL DEFAULT 0
                )
                """)
        }

        migrator.registerMigration("v2") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS profile (
                    id              INTEGER PRIMARY KEY CHECK (id = 1),
                    name            TEXT NOT NULL DEFAULT '',
                    username        TEXT NOT NULL DEFAULT '',
                    about_me        TEXT NOT NULL DEFAULT '',
                    birthday        TEXT NOT NULL DEFAULT '',
                    city            TEXT NOT NULL DEFAULT '',
                    hometown        TEXT NOT NULL DEFAULT '',
                    gender          TEXT NOT NULL DEFAULT '',
                    friends_count   INTEGER NOT NULL DEFAULT 0,
                    followers_count INTEGER NOT NULL DEFAULT 0
                )
                """)
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS profile_work (
                    id       INTEGER PRIMARY KEY AUTOINCREMENT,
                    employer TEXT NOT NULL,
                    title    TEXT,
                    location TEXT,
                    period   TEXT
                )
                """)
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS profile_education (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    school      TEXT NOT NULL,
                    degree      TEXT,
                    field       TEXT,
                    school_type TEXT
                )
                """)
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS profile_websites (
                    id      INTEGER PRIMARY KEY AUTOINCREMENT,
                    address TEXT NOT NULL
                )
                """)
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS profile_screen_names (
                    id       INTEGER PRIMARY KEY AUTOINCREMENT,
                    service  TEXT NOT NULL,
                    username TEXT NOT NULL
                )
                """)
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS profile_family (
                    id       INTEGER PRIMARY KEY AUTOINCREMENT,
                    name     TEXT NOT NULL,
                    relation TEXT NOT NULL
                )
                """)
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS profile_photos (
                    id        INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp INTEGER NOT NULL,
                    filename  TEXT NOT NULL
                )
                """)
        }

        migrator.registerMigration("v3") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS post_tags (
                    id      INTEGER PRIMARY KEY AUTOINCREMENT,
                    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
                    name    TEXT NOT NULL
                )
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_post_tags_name ON post_tags(name)
                """)
        }

        migrator.registerMigration("v4") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS friends (
                    id        INTEGER PRIMARY KEY AUTOINCREMENT,
                    name      TEXT NOT NULL,
                    timestamp INTEGER NOT NULL,
                    status    TEXT NOT NULL DEFAULT 'current'
                )
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_friends_timestamp ON friends(timestamp)
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_friends_status ON friends(status)
                """)
        }

        migrator.registerMigration("v5") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS logins (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp   INTEGER NOT NULL,
                    action      TEXT NOT NULL,
                    ip_address  TEXT NOT NULL DEFAULT '',
                    user_agent  TEXT NOT NULL DEFAULT '',
                    city        TEXT NOT NULL DEFAULT '',
                    region      TEXT NOT NULL DEFAULT '',
                    country     TEXT NOT NULL DEFAULT '',
                    device_type TEXT NOT NULL DEFAULT 'Other'
                )
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_logins_timestamp ON logins(timestamp DESC)
                """)
        }

        migrator.registerMigration("v6") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS searches (
                    id        INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp INTEGER NOT NULL,
                    query     TEXT NOT NULL,
                    title     TEXT NOT NULL DEFAULT ''
                )
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_searches_timestamp ON searches(timestamp DESC)
                """)
        }

        migrator.registerMigration("v7") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS profile_updates (
                    id        INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp INTEGER NOT NULL,
                    title     TEXT NOT NULL,
                    detail    TEXT,
                    image_uri TEXT
                )
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_profile_updates_timestamp ON profile_updates(timestamp DESC)
                """)
        }

        migrator.registerMigration("v8") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS notifications (
                    id        INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp INTEGER NOT NULL,
                    text      TEXT NOT NULL,
                    href      TEXT NOT NULL DEFAULT '',
                    unread    INTEGER NOT NULL DEFAULT 0
                )
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON notifications(timestamp DESC)
                """)
        }

        migrator.registerMigration("v9") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS visits (
                    id        INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp INTEGER NOT NULL DEFAULT 0,
                    name      TEXT NOT NULL,
                    uri       TEXT NOT NULL DEFAULT '',
                    category  TEXT NOT NULL
                )
                """)
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_visits_category_timestamp ON visits(category, timestamp DESC)
                """)
        }

        try migrator.migrate(dbQueue)
    }
}
