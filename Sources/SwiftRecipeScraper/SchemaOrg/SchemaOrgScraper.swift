import Foundation
import SwiftSoup

/// Scrapes recipes via Schema.org JSON-LD embedded in HTML.
public final class SchemaOrgScraper: BaseScraper {
    public override init(host: String = "*") {
        super.init(host: host)
    }

    public override func scrape(document: Document, url: URL) throws -> Recipe {
        let recipeObject = try SchemaOrgJSONLD.findRecipeObject(in: document)
        return try SchemaOrgMapper.mapRecipe(from: recipeObject, url: url)
    }
}
