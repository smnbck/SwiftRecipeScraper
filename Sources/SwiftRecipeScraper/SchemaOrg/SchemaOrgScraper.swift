import Foundation
import SwiftSoup

/// Scrapes recipes via Schema.org JSON-LD embedded in HTML.
final class SchemaOrgScraper: BaseScraper {
    override init(host: String = "*") {
        super.init(host: host)
    }

    override func scrape(document: Document, url: URL) throws -> Recipe {
        let recipeObject = try SchemaOrgJSONLD.findRecipeObject(in: document)
        return try SchemaOrgMapper.mapRecipe(from: recipeObject, url: url)
    }
}
