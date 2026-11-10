// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YAN",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "YAN", targets: ["YAN"])
    ],
    targets: [
        .executableTarget(
            name: "YAN",
            path: "Sources",
            exclude: ["Info.plist"]
        )
    ]
)
