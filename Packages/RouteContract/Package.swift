// swift-tools-version: 5.9

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
