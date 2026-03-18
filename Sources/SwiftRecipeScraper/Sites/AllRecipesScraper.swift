import Foundation
import SwiftSoup

/// Example scraper for allrecipes.com showing how to override fields with CSS selectors.
final class AllRecipesScraper: BaseScraper {
    private let schemaOrg: SchemaOrgScraper

    init() {
        self.schemaOrg = SchemaOrgScraper(host: "allrecipes.com")
        super.init(host: "allrecipes.com")
    }

    override func scrape(document: Document, url: URL) throws -> Recipe {
        // 1) Prefer Schema.org JSON-LD
        if let recipe = try? schemaOrg.scrape(document: document, url: url) {
            return try overrideFromHTML(recipe: recipe, document: document, url: url)
        }

        // 2) Fallback: CSS-only extraction (best-effort)
        let title = try firstText("h1", in: document)
        let ingredients = (try? texts("[data-ingredient-name], .mntl-structured-ingredients__list-item, .ingredients-item-name", in: document)) ?? []
        let instructions = (try? texts(".comp.mntl-sc-block-group--LI p, .instructions-section-item p, .recipe__steps-content p", in: document)) ?? []

        let imageURLs: [URL] = {
            if let src = try? firstAttr("img", attr: "src", in: document),
               let url = URL(string: src, relativeTo: url)?.absoluteURL {
                return [url]
            }
            return []
        }()

        if title == nil, ingredients.isEmpty, instructions.isEmpty {
            throw ScraperError.missingRequiredField("Could not extract recipe from HTML (no JSON-LD, selectors empty).")
        }

        return Recipe(
            title: title,
            imageURLs: imageURLs,
            ingredients: ingredients,
            instructions: instructions,
            host: url.host ?? host
        )
    }

    private func overrideFromHTML(recipe: Recipe, document: Document, url: URL) throws -> Recipe {
        var r = recipe

        if r.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false,
           let title = try firstText("h1", in: document) {
            r.title = title
        }

        if r.ingredients.isEmpty {
            let ingredients = try texts("[data-ingredient-name], .mntl-structured-ingredients__list-item, .ingredients-item-name", in: document)
            if !ingredients.isEmpty { r.ingredients = ingredients }
        }

        if r.instructions.isEmpty {
            let parts = try texts(".comp.mntl-sc-block-group--LI p, .instructions-section-item p, .recipe__steps-content p", in: document)
            if !parts.isEmpty { r.instructions = parts }
        }

        if r.imageURLs.isEmpty,
           let src = try firstAttr("img", attr: "src", in: document),
           let imageURL = URL(string: src, relativeTo: url)?.absoluteURL {
            r.imageURLs = [imageURL]
        }

        if r.host.isEmpty {
            r.host = url.host ?? host
        }

        return r
    }
}
