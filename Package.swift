// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScrapSquad",
    platforms: [.iOS(.v17)],
    products: [.library(name: "ScrapCore", targets: ["ScrapCore"])],
    targets: [
        .target(name: "ScrapCore", resources: [.process("Resources")]),
        .testTarget(name: "ScrapCoreTests", dependencies: ["ScrapCore"])
    ]
)
