# SwiftRecipeScraper

SwiftRecipeScraper is a native Swift (SwiftPM) library that extracts structured recipe data from cooking websites.

It focuses on **Schema.org JSON-LD** and provides a small, typed API you can use in apps, CLIs, or backend services.

## Dependencies / Prior art

- **HTML parsing**: Powered by [`SwiftSoup`](https://github.com/scinfu/SwiftSoup)
- **Inspiration / reference implementation (Python)**: [`hhursev/recipe-scrapers`](https://github.com/hhursev/recipe-scrapers)

## Features

- Schema.org JSON-LD scraping (supports both single JSON-LD objects and `@graph`)
- Site-specific overrides (example: AllRecipes)
- Modern Swift: async/await networking, typed models

## Installation

Add the package to your project via Swift Package Manager.

### Option A: Add via `Package.swift` (SwiftPM)

Add the dependency:

```swift
dependencies: [
    .package(url: "https://github.com/smnbck/swift-recipe-scraper.git", from: "0.1.0")
]
```

Then add the product to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "SwiftRecipeScraper", package: "SwiftRecipeScraper")
        ]
    )
]
```

### Option B: Add via Xcode

- In Xcode: **File → Add Packages…**
- Paste the repository URL and follow the prompts

## Quick start

```swift
import SwiftRecipeScraper

let client = SwiftRecipeScraperClient()
let url = URL(string: "https://www.allrecipes.com/recipe/123")!
let recipe = try await client.scrape(url: url)
print(recipe.title)
```

## Manual website testing (CLI)

This package also ships a small CLI executable for quick manual testing:

```bash
swift run swift-recipe-scrape "https://www.allrecipes.com/recipe/123"
```

It prints the scraped `Recipe` as pretty-printed JSON to stdout.

## Supported sites

- `allrecipes.com` (example implementation; may evolve as AllRecipes changes)

For other sites, the library falls back to the Schema.org JSON-LD scraper when available.

## Notes / limitations

- This project does **not** aim to bypass bot protection or paywalls.
- Scraping reliability depends on the target site and its structured data quality.

## Extending to new sites

If a site has incomplete or non-standard structured data, add a site-specific scraper and register it (see the `Sites/` and registry code for the AllRecipes example).

## Testing

Run unit tests:

```bash
swift test
```

### Fixtures

Tests are primarily offline and use HTML fixtures located under `Tests/SwiftRecipeScraperTests/Fixtures/`.
This makes parsing tests reproducible and avoids flaky network dependencies.
