// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TransactionKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "TransactionKit", targets: ["TransactionKit"])
    ],
    dependencies: [
        .package(path: "../DesignKit")
    ],
    targets: [
        .target(
            name: "TransactionKit",
            dependencies: ["DesignKit"]
        ),
        .testTarget(
            name: "TransactionKitTests",
            dependencies: ["TransactionKit"]
        )
    ]
)
