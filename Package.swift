// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ProductTemplateBuilder",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ProductTemplateBuilder", targets: ["ProductTemplateBuilder"])
    ],
    targets: [
        .executableTarget(
            name: "ProductTemplateBuilder",
            path: "Sources/ProductTemplateBuilder"
        )
    ]
)
