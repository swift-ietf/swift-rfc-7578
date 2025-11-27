// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-7578",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RFC 7578",
            targets: ["RFC 7578"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-ieee-754", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2045", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2046", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-2183", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "RFC 7578",
            dependencies: [
                .product(name: "IEEE 754", package: "swift-ieee-754"),
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "RFC 2046", package: "swift-rfc-2046"),
                .product(name: "RFC 2183", package: "swift-rfc-2183")
            ]
        ),
        .testTarget(
            name: "RFC 7578".tests,
            dependencies: ["RFC 7578"]
        )
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
