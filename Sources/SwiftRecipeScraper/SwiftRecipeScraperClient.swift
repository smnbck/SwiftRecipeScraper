import Foundation

/// Convenience entry point for consumers of the library.
///
/// The public API is intentionally small and stable: use this client to scrape `Recipe` data
/// from a URL (or from already fetched HTML), and handle errors via `ScraperError`.
public struct SwiftRecipeScraperClient {
    private let registry: ScraperRegistry

    public init() { self.registry = ScraperRegistry() }

    public func scrape(url: URL) async throws -> Recipe {
        let scraper = registry.scraper(for: url)
        return try await scraper.scrape(from: url)
    }

    /// Scrape a recipe from HTML that was fetched by the caller.
    ///
    /// This is useful if you want to control networking, caching, cookies, or custom headers in your app.
    public func scrape(html: String, url: URL) throws -> Recipe {
        let scraper = registry.scraper(for: url)
        return try scraper.scrape(html: html, url: url)
    }
}
