// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "QRCodeSwift",
    platforms: [.iOS("8.0")],
    products: [.library(name: "QRCodeSwift", targets: ["QRCodeSwift"])],
    targets: [
        .target(
            name: "QRCodeSwift",
            path: "QRCodeSwift",
            sources: ["Classes"],
            resources: [.process("Resources")]
        )
    ],
    swiftLanguageVersions: [.v5]
)
