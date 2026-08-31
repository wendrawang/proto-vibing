// swift-tools-version: 6.0

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
        // Test target menyusul di langkah 8, bersama nextStep yang wajib diuji.
        .target(
            name: "TransactionKit",
            dependencies: ["DesignKit"]
        )
    ]
)
