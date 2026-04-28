// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClipSpot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClipSpot", targets: ["ClipboardShelf"])
    ],
    targets: [
        .executableTarget(
            name: "ClipboardShelf"
        ),
        .testTarget(
            name: "ClipboardShelfTests",
            dependencies: ["ClipboardShelf"]
        )
    ]
)
