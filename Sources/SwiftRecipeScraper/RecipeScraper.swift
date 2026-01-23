import Foundation
import SwiftSoup

/// Contract for a site-specific recipe scraper.
public protocol RecipeScraper {
    /// Hostname this scraper supports (e.g. "allrecipes.com").
    var host: String { get }

    /// Scrape a recipe from a URL (networking + parsing).
    func scrape(from url: URL) async throws -> Recipe

    /// Scrape a recipe from an already loaded `SwiftSoup.Document`.
    func scrape(document: Document, url: URL) throws -> Recipe
}
