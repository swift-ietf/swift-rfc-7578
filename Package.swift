// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-rfc-7578",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "RFC 7578",
            targets: ["RFC 7578"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-2045", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2046", branch: "main")
    ],
    targets: [
        .target(
            name: "RFC 7578",
            dependencies: [
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046")
            ]
        ),
        .testTarget(
            name: "RFC 7578 Tests",
            dependencies: ["RFC 7578"]
        )
    ]
)

for target in package.targets {
    target.swiftSettings?.append(
        contentsOf: [
            .enableUpcomingFeature("MemberImportVisibility")
        ]
    )
}
