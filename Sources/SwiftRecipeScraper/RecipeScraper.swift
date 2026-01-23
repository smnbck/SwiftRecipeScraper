import Foundation
import SwiftSoup

/// Internal contract for recipe scrapers.
///
/// Note: This is intentionally not public. The library's public API is centered around
/// `SwiftRecipeScraperClient`, `Recipe`, and `ScraperError` to keep the surface stable.
protocol RecipeScraper {
    /// Hostname this scraper supports (e.g. "allrecipes.com").
    var host: String { get }

    /// Scrape a recipe from a URL (networking + parsing).
    func scrape(from url: URL) async throws -> Recipe

    /// Scrape a recipe from an already loaded `SwiftSoup.Document`.
    func scrape(document: Document, url: URL) throws -> Recipe
}

extension RecipeScraper {
    /// Scrape a recipe from HTML that was fetched by the caller.
    func scrape(html: String, url: URL) throws -> Recipe {
        do {
            let document = try SwiftSoup.parse(html)
            return try scrape(document: document, url: url)
        } catch {
            throw ScraperError.invalidHTML(String(describing: error))
        }
    }
}
