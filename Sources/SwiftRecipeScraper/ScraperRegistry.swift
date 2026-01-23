import Foundation

/// Selects the most appropriate scraper for a given URL.
public struct ScraperRegistry {
    private var entries: [AnyHostRecipeScraper]
    private var fallback: AnyHostRecipeScraper

    public init(
        scrapers: [any RecipeScraper] = [AllRecipesScraper()],
        fallback: any RecipeScraper = SchemaOrgScraper()
    ) {
        self.entries = scrapers.map { AnyHostRecipeScraper($0) }
        self.fallback = AnyHostRecipeScraper(fallback)
    }

    /// Returns a scraper suitable for the URL's host.
    public func scraper(for url: URL) -> any RecipeScraper {
        guard let host = url.host?.lowercased(), !host.isEmpty else {
            return fallback.base
        }

        if let match = entries.first(where: { $0.matches(host: host) }) {
            return match.base
        }
        return fallback.base
    }
}

/// A minimal type eraser that keeps host matching logic independent of concrete scraper type.
private struct AnyHostRecipeScraper {
    let base: any RecipeScraper
    private let hostPattern: String

    init(_ base: any RecipeScraper) {
        self.base = base
        self.hostPattern = base.host.lowercased()
    }

    func matches(host: String) -> Bool {
        // "*" means "any host"
        if hostPattern == "*" { return true }

        // Exact match or subdomain match (e.g. "www.allrecipes.com" matches "allrecipes.com")
        if host == hostPattern { return true }
        return host.hasSuffix("." + hostPattern)
    }
}
