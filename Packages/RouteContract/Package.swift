// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RouteContract",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "RouteContract", targets: ["RouteContract"])
    ],
    targets: [
        .target(name: "RouteContract")
    ]
)
