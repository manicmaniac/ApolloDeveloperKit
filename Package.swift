// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ApolloDeveloperKit",
    platforms: [.iOS(.v9), .macOS(.v10_10)],
    products: [
        .library(
            name: "ApolloDeveloperKit",
            targets: ["ApolloDeveloperKit"])
    ],
    dependencies: [
        .package(name: "Apollo", url: "https://github.com/apollographql/apollo-ios.git", "0.34.0"..<"0.35.0")
    ],
    targets: [
        .target(
            name: "ApolloDeveloperKit",
            dependencies: ["Apollo"],
            exclude: ["Info.plist"],
            resources: [.copy("Assets")]),
        .testTarget(
            name: "ApolloDeveloperKitTests",
            dependencies: ["ApolloDeveloperKit"],
            exclude: ["ApolloDeveloperKitTests.swift", "Info.plist"])
    ]
)
