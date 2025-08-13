// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux)
let plugins: [Target.PluginUsage] = [
    .plugin(name: "PackageBuildInfoPlugin", package: "PackageBuildInfo")
]
#else
let plugins: [Target.PluginUsage] = [
    .plugin(name: "SwiftLint", package: "SwiftLintPlugin"),
    .plugin(name: "PackageBuildInfoPlugin", package: "PackageBuildInfo")
]
#endif

let package = Package(
    name: "Callisto",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/lukepistrol/SwiftLintPlugin", from: "0.59.1"),
        .package(url: "https://github.com/jpsim/Yams", from: "4.0.0"),
        .package(url: "https://github.com/Patrick-Kladek/PackageBuildInfo", branch: "develop")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Callisto",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
                .targetItem(name: "SlackKit", condition: .none),
                .targetItem(name: "GithubKit", condition: .none),
                .targetItem(name: "Common", condition: .none),
                .targetItem(name: "MarkdownKit", condition: .none)
            ],
            plugins: plugins
        ),
        .testTarget(
            name: "CallistoTest",
            dependencies: [
                .byName(name: "Callisto")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(name: "Common"),
        .target(name: "SlackKit", dependencies: [
            .targetItem(name: "Common", condition: .none)
        ]),
        .target(
            name: "GithubKit",
            dependencies: [
                .targetItem(name: "Common", condition: .none)
            ]
        ),
        .target(
            name: "MarkdownKit"
        ),
        .testTarget(
            name: "MarkdownKitTest",
            dependencies: [
                .byName(name: "MarkdownKit")
            ]
        )
    ]
)
