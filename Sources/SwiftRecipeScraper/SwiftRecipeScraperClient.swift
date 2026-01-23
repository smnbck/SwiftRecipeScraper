import Foundation

/// Convenience entry point for consumers of the library.
public struct SwiftRecipeScraperClient {
    private let registry: ScraperRegistry

    public init(registry: ScraperRegistry = ScraperRegistry()) {
        self.registry = registry
    }

    public func scrape(url: URL) async throws -> Recipe {
        let scraper = registry.scraper(for: url)
        return try await scraper.scrape(from: url)
    }
}
