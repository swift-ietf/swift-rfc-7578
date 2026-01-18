// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-7578",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(
            name: "RFC 7578",
            targets: ["RFC 7578"]
        )
    ],
    dependencies: [
        .package(path: "../swift-ieee-754"),
        .package(path: "../swift-rfc-2045"),
        .package(path: "../swift-rfc-2046"),
        .package(path: "../swift-rfc-2183")
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
