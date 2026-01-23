import XCTest
import SwiftSoup
@testable import SwiftRecipeScraper

final class SwiftRecipeScraperTests: XCTestCase {
    func testRecipeIsCodable() throws {
        let recipe = Recipe(
            title: "Test",
            ingredients: ["1 cup flour"],
            instructions: "Mix.",
            imageURL: URL(string: "https://example.com/image.jpg"),
            prepTime: 60,
            host: "example.com"
        )

        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        XCTAssertEqual(decoded.title, recipe.title)
        XCTAssertEqual(decoded.ingredients, recipe.ingredients)
        XCTAssertEqual(decoded.instructions, recipe.instructions)
        XCTAssertEqual(decoded.imageURL, recipe.imageURL)
        XCTAssertEqual(decoded.prepTime, recipe.prepTime)
        XCTAssertEqual(decoded.host, recipe.host)
    }

    func testSchemaOrgScraperSingleObject() throws {
        let html = try TestFixtures.loadString(named: "schema_single_object")

        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/pancakes")!)

        XCTAssertEqual(recipe.title, "Pancakes")
        XCTAssertEqual(recipe.ingredients, ["1 cup flour", "1 egg"])
        XCTAssertTrue(recipe.instructions.contains("Mix ingredients."))
        XCTAssertEqual(recipe.imageURL?.absoluteString, "https://example.com/p.jpg")
        XCTAssertEqual(recipe.prepTime, 600)
        XCTAssertEqual(recipe.host, "example.com")
    }

    func testSchemaOrgScraperGraph() throws {
        let html = try TestFixtures.loadString(named: "schema_graph")

        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/x")!)

        XCTAssertEqual(recipe.title, "Graph Recipe")
        XCTAssertEqual(recipe.ingredients, ["a"])
        XCTAssertEqual(recipe.instructions, "Do it.")
    }

    func testSchemaOrgScraperSkipsInvalidJSONLDScripts() throws {
        let html = try TestFixtures.loadString(named: "schema_multiple_scripts_one_invalid")

        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/x")!)

        XCTAssertEqual(recipe.title, "Second Script Recipe")
        XCTAssertEqual(recipe.ingredients, ["x", "y"])
        XCTAssertEqual(recipe.instructions, "Just do it.")
    }

    func testRegistrySelectsAllRecipesForHost() throws {
        let registry = ScraperRegistry()
        let scraper = registry.scraper(for: URL(string: "https://www.allrecipes.com/recipe/123")!)
        XCTAssertTrue(scraper is AllRecipesScraper)
    }

    func testRegistryFallsBackToSchemaOrg() throws {
        let registry = ScraperRegistry()
        let scraper = registry.scraper(for: URL(string: "https://example.com/recipe")!)
        XCTAssertTrue(scraper is SchemaOrgScraper)
    }
}
