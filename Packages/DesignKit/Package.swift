// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"])
    ],
    dependencies: [
        .package(path: "../RouteContract")
    ],
    targets: [
        .target(
            name: "DesignKit",
            dependencies: ["RouteContract"],
            exclude: ["Tokens/README.md"],
            resources: [
                // Font tidak terdaftar otomatis dari SPM — lihat DesignKitFonts.register().
                .process("Resources/Fonts")
            ]
        ),
        .testTarget(
            name: "DesignKitTests",
            dependencies: ["DesignKit"]
        )
    ]
)
