// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DogSwipeCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "DogSwipeCore", targets: ["DogSwipeCore"])
    ],
    targets: [
        .target(name: "DogSwipeCore"),
        .testTarget(name: "DogSwipeCoreTests", dependencies: ["DogSwipeCore"])
    ]
)
