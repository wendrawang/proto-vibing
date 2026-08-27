// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"])
    ],
    targets: [
        .target(
            name: "DesignKit",
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
