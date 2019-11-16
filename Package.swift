// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApolloDeveloperKit",
    products: [
        .library(
            name: "ApolloDeveloperKit",
            targets: ["ApolloDeveloperKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios", from: "0.9.1")
    ],
    targets: [
        .target(
            name: "ApolloDeveloperKit",
            dependencies: ["Apollo"]),
        .testTarget(
            name: "ApolloDeveloperKitTests",
            dependencies: ["ApolloDeveloperKit"])
    ]
)
