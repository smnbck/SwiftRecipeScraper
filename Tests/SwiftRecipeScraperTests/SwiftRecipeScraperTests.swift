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
        let html = """
        <html><head></head><body>
        <script type="application/ld+json">
        {
          "@context":"https://schema.org",
          "@type":"Recipe",
          "name":"Pancakes",
          "recipeIngredient":["1 cup flour","1 egg"],
          "recipeInstructions":[
            {"@type":"HowToStep","text":"Mix ingredients."},
            {"@type":"HowToStep","text":"Cook on a pan."}
          ],
          "image":"https://example.com/p.jpg",
          "prepTime":"PT10M"
        }
        </script>
        </body></html>
        """

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
        let html = """
        <html><head></head><body>
        <script type="application/ld+json">
        {
          "@context":"https://schema.org",
          "@graph":[
            {"@type":"WebPage","name":"Some page"},
            {"@type":"Recipe","name":"Graph Recipe","recipeIngredient":["a"],"recipeInstructions":"Do it."}
          ]
        }
        </script>
        </body></html>
        """

        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/x")!)

        XCTAssertEqual(recipe.title, "Graph Recipe")
        XCTAssertEqual(recipe.ingredients, ["a"])
        XCTAssertEqual(recipe.instructions, "Do it.")
    }

    func testSchemaOrgScraperSkipsInvalidJSONLDBlocks() throws {
        let html = try FixtureLoader.loadString("jsonld_multiple_scripts", fileExtension: "html")
        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/fixture")!)

        XCTAssertEqual(recipe.title, "Fixture Recipe")
        XCTAssertEqual(recipe.ingredients, ["a", "b"])
        XCTAssertEqual(recipe.prepTime, 300)
        XCTAssertEqual(recipe.imageURL?.absoluteString, "https://example.com/a.jpg")
        XCTAssertTrue(recipe.instructions.contains("Step 1"))
        XCTAssertTrue(recipe.instructions.contains("Step 2"))
    }

    func testSchemaOrgScraperGraphSectionInstructionsAndRelativeImage() throws {
        let html = try FixtureLoader.loadString("jsonld_graph_instructions_section", fileExtension: "html")
        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/base/path")!)

        XCTAssertEqual(recipe.title, "Graph Fixture")
        XCTAssertEqual(recipe.ingredients, ["x"])
        XCTAssertEqual(recipe.prepTime, 3600)
        XCTAssertEqual(recipe.imageURL?.absoluteString, "https://example.com/relative.jpg")
        XCTAssertTrue(recipe.instructions.contains("Do A"))
        XCTAssertTrue(recipe.instructions.contains("Do B"))
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
