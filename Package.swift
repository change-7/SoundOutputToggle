// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SoundOutputToggle",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SoundOutputToggle", targets: ["SoundOutputToggle"])
    ],
    targets: [
        .executableTarget(
            name: "SoundOutputToggle",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
