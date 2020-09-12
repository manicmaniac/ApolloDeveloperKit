// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApolloDeveloperKit",
    platforms: [.iOS(.v9), .macOS(.v10_10)],
    products: [
        .library(
            name: "ApolloDeveloperKit",
            targets: ["ApolloDeveloperKit"]),
    ],
    dependencies: [
        .package(name: "Apollo", url: "https://github.com/apollographql/apollo-ios.git", "0.29.0"..<"0.33.0")
    ],
    targets: [
        .target(
            name: "ApolloDeveloperKit",
            dependencies: ["Apollo"],
            resources: [.copy("Assets")]),
        .testTarget(
            name: "ApolloDeveloperKitTests",
            dependencies: ["ApolloDeveloperKit"],
            exclude: ["ApolloDeveloperKitTests.swift"]),
    ]
)
