// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftRecipeScraper",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "SwiftRecipeScraper",
            targets: ["SwiftRecipeScraper"]
        ),
        .executable(
            name: "swift-recipe-scrape",
            targets: ["SwiftRecipeScraperCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", exact: "2.13.1"),
    ],
    targets: [
        .target(
            name: "SwiftRecipeScraper",
            dependencies: [
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ]
        ),
        .executableTarget(
            name: "SwiftRecipeScraperCLI",
            dependencies: ["SwiftRecipeScraper"]
        ),
        .testTarget(
            name: "SwiftRecipeScraperTests",
            dependencies: ["SwiftRecipeScraper"],
            path: "Tests/SwiftRecipeScraperTests",
            resources: [
                .process("Fixtures")
            ]
        ),
    ]
)
