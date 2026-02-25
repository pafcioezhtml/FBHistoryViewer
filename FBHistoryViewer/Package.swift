// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FBHistoryViewer",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "FBHistoryViewer",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/FBHistoryViewer",
            exclude: ["Info.plist"],
            swiftSettings: [
                // Use Swift 5 concurrency mode so GRDB 7 types don't require
                // full Sendable annotations throughout our codebase.
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                // Embed Info.plist in the binary so macOS can find the bundle
                // identifier (required for window tabs, Handoff, state restoration).
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/FBHistoryViewer/Info.plist",
                ])
            ]
        )
    ]
)
