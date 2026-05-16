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
            path: "Sources/ProductTemplateBuilder",
            resources: [
                .copy("Resources/UrunYuklemeSablonu.xlsx"),
                .copy("Resources/Tip1Onyazi.html"),
                .copy("Resources/Tip2Onyazi.html"),
                .copy("Resources/Tip3Onyazi.html"),
                .copy("Resources/Tip4Onyazi.html"),
                .copy("Resources/Tip5Onyazi.html"),
            ]
        ),
        .testTarget(
            name: "ProductTemplateBuilderTests",
            dependencies: ["ProductTemplateBuilder"]
        )
    ]
)
