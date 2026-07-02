// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Charmera",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Charmera",
            path: "Sources/Charmera",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
