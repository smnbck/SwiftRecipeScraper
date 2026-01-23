import Foundation
import SwiftSoup

/// Example scraper for allrecipes.com showing how to override fields with CSS selectors.
public final class AllRecipesScraper: BaseScraper {
    private let schemaOrg: SchemaOrgScraper

    public init() {
        self.schemaOrg = SchemaOrgScraper(host: "allrecipes.com")
        super.init(host: "allrecipes.com")
    }

    public override func scrape(document: Document, url: URL) throws -> Recipe {
        // 1) Prefer Schema.org JSON-LD
        if let recipe = try? schemaOrg.scrape(document: document, url: url) {
            return try overrideFromHTML(recipe: recipe, document: document, url: url)
        }

        // 2) Fallback: CSS-only extraction (best-effort)
        let title = (try firstText("h1", in: document)) ?? ""
        let ingredients = (try? texts("[data-ingredient-name], .mntl-structured-ingredients__list-item, .ingredients-item-name", in: document)) ?? []
        let instructionsParts = (try? texts(".comp.mntl-sc-block-group--LI p, .instructions-section-item p, .recipe__steps-content p", in: document)) ?? []
        let instructions = instructionsParts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        let imageURL: URL? = {
            if let src = try? firstAttr("img", attr: "src", in: document) {
                return URL(string: src, relativeTo: url)?.absoluteURL
            }
            return nil
        }()

        if title.isEmpty, ingredients.isEmpty, instructions.isEmpty {
            throw ScraperError.missingRequiredField("Could not extract recipe from HTML (no JSON-LD, selectors empty).")
        }

        return Recipe(
            title: title.isEmpty ? "Untitled" : title,
            ingredients: ingredients,
            instructions: instructions,
            imageURL: imageURL,
            prepTime: nil,
            host: url.host ?? host
        )
    }

    private func overrideFromHTML(recipe: Recipe, document: Document, url: URL) throws -> Recipe {
        var r = recipe

        if r.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let title = try firstText("h1", in: document) {
            r.title = title
        }

        if r.ingredients.isEmpty {
            let ingredients = try texts("[data-ingredient-name], .mntl-structured-ingredients__list-item, .ingredients-item-name", in: document)
            if !ingredients.isEmpty { r.ingredients = ingredients }
        }

        if r.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let parts = try texts(".comp.mntl-sc-block-group--LI p, .instructions-section-item p, .recipe__steps-content p", in: document)
            let joined = parts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { r.instructions = joined }
        }

        if r.imageURL == nil,
           let src = try firstAttr("img", attr: "src", in: document) {
            r.imageURL = URL(string: src, relativeTo: url)?.absoluteURL
        }

        if r.host.isEmpty {
            r.host = url.host ?? host
        }

        return r
    }
}
