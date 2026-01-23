# SwiftRecipeScraper

Native Swift recipe scraping, inspired by the Python `recipe-scrapers` ecosystem.

## Features

- Schema.org / JSON-LD (`application/ld+json`) recipe extraction with `@graph` support
- Site-specific scrapers (example: AllRecipes) with CSS selector fallbacks
- Async/await networking
- Codable `Recipe` model

## Installation (Swift Package Manager)

Add this package to your project in Xcode (File → Add Packages…) or via `Package.swift`:

```swift
.package(url: "https://github.com/<your-org-or-user>/SwiftRecipeScraper.git", from: "0.1.0"),
```

## Usage (Library)

```swift
import SwiftRecipeScraper

let client = SwiftRecipeScraperClient()
let recipe = try await client.scrape(url: URL(string: "https://www.allrecipes.com/recipe/...")!)
print(recipe.title)
print(recipe.ingredients)
print(recipe.instructions)
```

## Manual Testing (CLI)

This repository ships a small CLI for quick smoke-testing against real websites.

### Run

```bash
swift run swift-recipe-scrape "https://www.allrecipes.com/recipe/..."
```

The CLI prints the scraped `Recipe` as pretty-printed JSON to stdout.

### Notes

- Be mindful of website terms of service and rate limits.
- For reproducible tests, prefer saving HTML as fixtures and running unit tests offline.

## Testing

```bash
swift test
```

The test suite uses fixture HTML files under `Tests/SwiftRecipeScraperTests/Fixtures`.

## Project Structure

- `Sources/SwiftRecipeScraper/` – library code
- `Sources/SwiftRecipeScraperCLI/` – CLI entry point
- `Tests/SwiftRecipeScraperTests/` – unit tests + fixtures


