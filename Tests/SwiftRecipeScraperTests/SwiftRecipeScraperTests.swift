import XCTest
import SwiftSoup
@testable import SwiftRecipeScraper

final class SwiftRecipeScraperTests: XCTestCase {

    // MARK: - Recipe Codability

    func testRecipeIsCodable() throws {
        let recipe = Recipe(
            title: "Test",
            description: "A test recipe",
            sourceURL: URL(string: "https://example.com/recipe"),
            imageURLs: [URL(string: "https://example.com/image.jpg")!],
            author: "Chef Test",
            keywords: ["easy", "quick"],
            aggregateRating: RecipeAggregateRating(ratingValue: 4.5, ratingCount: 100),
            datePublished: Date(timeIntervalSince1970: 1_700_000_000),
            videoURL: URL(string: "https://example.com/video.mp4"),
            language: "en",
            prepTime: 60,
            cookTime: 1800,
            totalTime: 1860,
            tools: ["Mixer"],
            ingredients: ["1 cup flour"],
            instructions: ["Mix."],
            recipeYield: "4 servings",
            recipeCategory: ["Dessert"],
            recipeCuisine: ["Italian"],
            cookingMethod: "Baking",
            suitableForDiet: ["GlutenFreeDiet"],
            nutrition: NutritionInfo(calories: "500 calories", proteinContent: "20 g"),
            host: "example.com"
        )

        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        XCTAssertEqual(decoded.title, recipe.title)
        XCTAssertEqual(decoded.description, recipe.description)
        XCTAssertEqual(decoded.sourceURL, recipe.sourceURL)
        XCTAssertEqual(decoded.ingredients, recipe.ingredients)
        XCTAssertEqual(decoded.instructions, recipe.instructions)
        XCTAssertEqual(decoded.imageURLs, recipe.imageURLs)
        XCTAssertEqual(decoded.author, recipe.author)
        XCTAssertEqual(decoded.keywords, recipe.keywords)
        XCTAssertEqual(decoded.aggregateRating, recipe.aggregateRating)
        XCTAssertEqual(decoded.datePublished, recipe.datePublished)
        XCTAssertEqual(decoded.videoURL, recipe.videoURL)
        XCTAssertEqual(decoded.language, recipe.language)
        XCTAssertEqual(decoded.prepTime, recipe.prepTime)
        XCTAssertEqual(decoded.cookTime, recipe.cookTime)
        XCTAssertEqual(decoded.totalTime, recipe.totalTime)
        XCTAssertEqual(decoded.tools, recipe.tools)
        XCTAssertEqual(decoded.recipeYield, recipe.recipeYield)
        XCTAssertEqual(decoded.recipeCategory, recipe.recipeCategory)
        XCTAssertEqual(decoded.recipeCuisine, recipe.recipeCuisine)
        XCTAssertEqual(decoded.cookingMethod, recipe.cookingMethod)
        XCTAssertEqual(decoded.suitableForDiet, recipe.suitableForDiet)
        XCTAssertEqual(decoded.nutrition, recipe.nutrition)
        XCTAssertEqual(decoded.host, recipe.host)
    }

    // MARK: - Schema.org Basic Parsing

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
        XCTAssertEqual(recipe.instructions, ["Mix ingredients.", "Cook on a pan."])
        XCTAssertEqual(recipe.imageURLs.first?.absoluteString, "https://example.com/p.jpg")
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
        XCTAssertEqual(recipe.instructions, ["Do it."])
    }

    func testSchemaOrgScraperSkipsInvalidJSONLDBlocks() throws {
        let html = try FixtureLoader.loadString("jsonld_multiple_scripts", fileExtension: "html")
        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/fixture")!)

        XCTAssertEqual(recipe.title, "Fixture Recipe")
        XCTAssertEqual(recipe.ingredients, ["a", "b"])
        XCTAssertEqual(recipe.prepTime, 300)
        XCTAssertEqual(recipe.imageURLs.first?.absoluteString, "https://example.com/a.jpg")
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
        // totalTime is now separate from prepTime
        XCTAssertNil(recipe.prepTime)
        XCTAssertEqual(recipe.totalTime, 3600)
        XCTAssertEqual(recipe.imageURLs.first?.absoluteString, "https://example.com/relative.jpg")
        XCTAssertTrue(recipe.instructions.contains("Do A"))
        XCTAssertTrue(recipe.instructions.contains("Do B"))
    }

    // MARK: - Registry

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

    // MARK: - Time Fields Are Separate

    func testTimeFieldsAreSeparate() throws {
        let html = """
        <html><body>
        <script type="application/ld+json">
        {
          "@context":"https://schema.org",
          "@type":"Recipe",
          "name":"Time Test",
          "recipeIngredient":["a"],
          "recipeInstructions":"Do it.",
          "prepTime":"PT10M",
          "cookTime":"PT30M",
          "totalTime":"PT40M"
        }
        </script>
        </body></html>
        """

        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/t")!)

        XCTAssertEqual(recipe.prepTime, 600)   // 10 min
        XCTAssertEqual(recipe.cookTime, 1800)  // 30 min
        XCTAssertEqual(recipe.totalTime, 2400) // 40 min
    }

    func testOnlyCookTimePresent() throws {
        let html = """
        <html><body>
        <script type="application/ld+json">
        {
          "@context":"https://schema.org",
          "@type":"Recipe",
          "name":"Cook Only",
          "recipeIngredient":["a"],
          "recipeInstructions":"Do it.",
          "cookTime":"PT20M"
        }
        </script>
        </body></html>
        """

        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/t")!)

        XCTAssertNil(recipe.prepTime)
        XCTAssertEqual(recipe.cookTime, 1200)
        XCTAssertNil(recipe.totalTime)
    }

    // MARK: - Full Recipe with All Properties

    func testFullRecipeFromFixture() throws {
        let html = try FixtureLoader.loadString("jsonld_full_recipe", fileExtension: "html")
        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        let recipe = try scraper.scrape(document: doc, url: URL(string: "https://example.com/full")!)

        // Basic
        XCTAssertEqual(recipe.title, "Full Schema Recipe")
        XCTAssertEqual(recipe.description, "A comprehensive test recipe.")
        XCTAssertEqual(recipe.sourceURL?.absoluteString, "https://example.com/full-recipe")
        XCTAssertEqual(recipe.author, "Chef John")
        XCTAssertEqual(recipe.language, "en")
        XCTAssertEqual(recipe.host, "example.com")

        // Time
        XCTAssertEqual(recipe.prepTime, 900)    // PT15M
        XCTAssertEqual(recipe.cookTime, 2700)   // PT45M
        XCTAssertEqual(recipe.totalTime, 3600)  // PT1H

        // Recipe-specific
        XCTAssertEqual(recipe.ingredients, ["2 cups flour", "1 cup sugar", "3 eggs"])
        XCTAssertTrue(recipe.instructions.contains("Preheat oven to 350F."))
        XCTAssertEqual(recipe.instructions.count, 4)
        XCTAssertEqual(recipe.recipeYield, "8 servings")
        XCTAssertEqual(recipe.recipeCategory, ["Dessert"])
        XCTAssertEqual(recipe.recipeCuisine, ["American"])
        XCTAssertEqual(recipe.cookingMethod, "Baking")
        XCTAssertEqual(recipe.suitableForDiet, ["VegetarianDiet"])

        // Keywords
        XCTAssertEqual(recipe.keywords, ["cake", "easy", "birthday"])

        // Image
        XCTAssertEqual(recipe.imageURLs.first?.absoluteString, "https://example.com/cake.jpg")

        // Video
        XCTAssertEqual(recipe.videoURL?.absoluteString, "https://example.com/cake-video.mp4")

        // Rating
        XCTAssertNotNil(recipe.aggregateRating)
        XCTAssertEqual(recipe.aggregateRating?.ratingValue, 4.8)
        XCTAssertEqual(recipe.aggregateRating?.ratingCount, 250)
        XCTAssertEqual(recipe.aggregateRating?.bestRating, 5)

        // Nutrition
        XCTAssertNotNil(recipe.nutrition)
        XCTAssertEqual(recipe.nutrition?.calories, "350 calories")
        XCTAssertEqual(recipe.nutrition?.fatContent, "12 g")
        XCTAssertEqual(recipe.nutrition?.proteinContent, "5 g")
        XCTAssertEqual(recipe.nutrition?.carbohydrateContent, "55 g")

        // Tools
        XCTAssertEqual(recipe.tools, ["Mixing Bowl", "Whisk"])

        // Dates
        XCTAssertNotNil(recipe.datePublished)
        XCTAssertNotNil(recipe.dateModified)
    }

    // MARK: - Multi-Type Author Parsing

    func testAuthorAsString() throws {
        let html = recipeHTML(extras: "\"author\": \"Jane Doe\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.author, "Jane Doe")
    }

    func testAuthorAsPerson() throws {
        let html = recipeHTML(extras: "\"author\": {\"@type\":\"Person\",\"name\":\"Jane Doe\"}")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.author, "Jane Doe")
    }

    func testAuthorAsOrganization() throws {
        let html = recipeHTML(extras: "\"author\": {\"@type\":\"Organization\",\"name\":\"Food Network\"}")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.author, "Food Network")
    }

    func testAuthorAsArray() throws {
        let html = recipeHTML(extras: """
        "author": [
          {"@type":"Person","name":"Alice"},
          {"@type":"Person","name":"Bob"}
        ]
        """)
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.author, "Alice, Bob")
    }

    // MARK: - Multi-Type Keywords Parsing

    func testKeywordsAsCommaSeparatedString() throws {
        let html = recipeHTML(extras: "\"keywords\": \"easy, quick, dinner\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.keywords, ["easy", "quick", "dinner"])
    }

    func testKeywordsAsArray() throws {
        let html = recipeHTML(extras: "\"keywords\": [\"easy\", \"quick\"]")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.keywords, ["easy", "quick"])
    }

    func testKeywordsAsDefinedTermArray() throws {
        let html = recipeHTML(extras: """
        "keywords": [
          {"@type":"DefinedTerm","name":"easy"},
          {"@type":"DefinedTerm","name":"quick"}
        ]
        """)
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.keywords, ["easy", "quick"])
    }

    // MARK: - Multi-Type Image Parsing

    func testImageAsString() throws {
        let html = recipeHTML(extras: "\"image\": \"https://example.com/img.jpg\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.imageURLs, [URL(string: "https://example.com/img.jpg")!])
    }

    func testImageAsImageObject() throws {
        let html = recipeHTML(extras: "\"image\": {\"@type\":\"ImageObject\",\"url\":\"https://example.com/img.jpg\"}")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.imageURLs, [URL(string: "https://example.com/img.jpg")!])
    }

    func testImageAsImageObjectWithContentUrl() throws {
        let html = recipeHTML(extras: "\"image\": {\"@type\":\"ImageObject\",\"contentUrl\":\"https://example.com/img.jpg\"}")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.imageURLs, [URL(string: "https://example.com/img.jpg")!])
    }

    func testImageAsArray() throws {
        let html = recipeHTML(extras: "\"image\": [\"https://example.com/a.jpg\", \"https://example.com/b.jpg\"]")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.imageURLs.count, 2)
        XCTAssertEqual(recipe.imageURLs[0].absoluteString, "https://example.com/a.jpg")
        XCTAssertEqual(recipe.imageURLs[1].absoluteString, "https://example.com/b.jpg")
    }

    // MARK: - Multi-Type Video Parsing

    func testVideoAsString() throws {
        let html = recipeHTML(extras: "\"video\": \"https://example.com/video.mp4\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.videoURL?.absoluteString, "https://example.com/video.mp4")
    }

    func testVideoAsVideoObject() throws {
        let html = recipeHTML(extras: "\"video\": {\"@type\":\"VideoObject\",\"contentUrl\":\"https://example.com/video.mp4\"}")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.videoURL?.absoluteString, "https://example.com/video.mp4")
    }

    func testVideoAsVideoObjectWithEmbedUrl() throws {
        let html = recipeHTML(extras: "\"video\": {\"@type\":\"VideoObject\",\"embedUrl\":\"https://youtube.com/embed/123\"}")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.videoURL?.absoluteString, "https://youtube.com/embed/123")
    }

    // MARK: - Multi-Type RecipeYield Parsing

    func testRecipeYieldAsString() throws {
        let html = recipeHTML(extras: "\"recipeYield\": \"4 servings\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.recipeYield, "4 servings")
    }

    func testRecipeYieldAsNumber() throws {
        let html = recipeHTML(extras: "\"recipeYield\": 4")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.recipeYield, "4")
    }

    func testRecipeYieldAsQuantitativeValue() throws {
        let html = recipeHTML(extras: """
        "recipeYield": {"@type":"QuantitativeValue","value":4,"unitText":"servings"}
        """)
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.recipeYield, "4 servings")
    }

    // MARK: - Multi-Type Ingredients Parsing

    func testIngredientsAsItemList() throws {
        let html = """
        <html><body>
        <script type="application/ld+json">
        {
          "@context":"https://schema.org",
          "@type":"Recipe",
          "name":"Test Recipe",
          "recipeIngredient": {
            "@type":"ItemList",
            "itemListElement":[
              {"@type":"ListItem","name":"1 cup flour"},
              {"@type":"ListItem","name":"2 eggs"}
            ]
          },
          "recipeInstructions":"Do it."
        }
        </script>
        </body></html>
        """
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.ingredients, ["1 cup flour", "2 eggs"])
    }

    func testIngredientsAsSingleString() throws {
        let html = """
        <html><body>
        <script type="application/ld+json">
        {
          "@context":"https://schema.org",
          "@type":"Recipe",
          "name":"Test Recipe",
          "recipeIngredient": "1 cup flour",
          "recipeInstructions":"Do it."
        }
        </script>
        </body></html>
        """
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.ingredients, ["1 cup flour"])
    }

    // MARK: - Multi-Type RecipeCategory / RecipeCuisine Parsing

    func testRecipeCategoryAsString() throws {
        let html = recipeHTML(extras: "\"recipeCategory\": \"Dessert\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.recipeCategory, ["Dessert"])
    }

    func testRecipeCategoryAsArray() throws {
        let html = recipeHTML(extras: "\"recipeCategory\": [\"Dessert\", \"Snack\"]")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.recipeCategory, ["Dessert", "Snack"])
    }

    func testRecipeCuisineAsString() throws {
        let html = recipeHTML(extras: "\"recipeCuisine\": \"Italian\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.recipeCuisine, ["Italian"])
    }

    // MARK: - SuitableForDiet Parsing

    func testSuitableForDietStripsSchemaOrgPrefix() throws {
        let html = recipeHTML(extras: "\"suitableForDiet\": \"https://schema.org/GlutenFreeDiet\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.suitableForDiet, ["GlutenFreeDiet"])
    }

    func testSuitableForDietAsArray() throws {
        let html = recipeHTML(extras: "\"suitableForDiet\": [\"https://schema.org/VeganDiet\", \"GlutenFreeDiet\"]")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.suitableForDiet, ["VeganDiet", "GlutenFreeDiet"])
    }

    // MARK: - Nutrition Parsing

    func testNutritionParsing() throws {
        let html = recipeHTML(extras: """
        "nutrition": {
          "@type":"NutritionInformation",
          "calories":"500 calories",
          "fatContent":"20 g",
          "proteinContent":"15 g",
          "servingSize":"1 slice"
        }
        """)
        let recipe = try parseRecipe(html)
        XCTAssertNotNil(recipe.nutrition)
        XCTAssertEqual(recipe.nutrition?.calories, "500 calories")
        XCTAssertEqual(recipe.nutrition?.fatContent, "20 g")
        XCTAssertEqual(recipe.nutrition?.proteinContent, "15 g")
        XCTAssertEqual(recipe.nutrition?.servingSize, "1 slice")
        XCTAssertNil(recipe.nutrition?.sugarContent)
    }

    func testNutritionReturnsNilWhenEmpty() throws {
        let html = recipeHTML(extras: "\"nutrition\": {\"@type\":\"NutritionInformation\"}")
        let recipe = try parseRecipe(html)
        XCTAssertNil(recipe.nutrition)
    }

    // MARK: - AggregateRating Parsing

    func testAggregateRatingWithStringValues() throws {
        let html = recipeHTML(extras: """
        "aggregateRating": {
          "@type":"AggregateRating",
          "ratingValue":"4.5",
          "ratingCount":"120",
          "bestRating":"5"
        }
        """)
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.aggregateRating?.ratingValue, 4.5)
        XCTAssertEqual(recipe.aggregateRating?.ratingCount, 120)
        XCTAssertEqual(recipe.aggregateRating?.bestRating, 5)
    }

    func testAggregateRatingWithNumericValues() throws {
        let html = recipeHTML(extras: """
        "aggregateRating": {
          "@type":"AggregateRating",
          "ratingValue":4.2,
          "ratingCount":50,
          "reviewCount":30
        }
        """)
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.aggregateRating?.ratingValue, 4.2)
        XCTAssertEqual(recipe.aggregateRating?.ratingCount, 50)
        XCTAssertEqual(recipe.aggregateRating?.reviewCount, 30)
    }

    // MARK: - Date Parsing

    func testDatePublishedDateOnly() throws {
        let html = recipeHTML(extras: "\"datePublished\": \"2024-06-15\"")
        let recipe = try parseRecipe(html)
        XCTAssertNotNil(recipe.datePublished)
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: recipe.datePublished!)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
    }

    func testDatePublishedISO8601() throws {
        let html = recipeHTML(extras: "\"datePublished\": \"2024-06-15T10:30:00+00:00\"")
        let recipe = try parseRecipe(html)
        XCTAssertNotNil(recipe.datePublished)
    }

    // MARK: - Tools Parsing

    func testToolsAsStringArray() throws {
        let html = recipeHTML(extras: "\"tool\": [\"Mixer\", \"Whisk\"]")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.tools, ["Mixer", "Whisk"])
    }

    func testToolsAsHowToToolArray() throws {
        let html = recipeHTML(extras: """
        "tool": [
          {"@type":"HowToTool","name":"Mixer"},
          {"@type":"HowToTool","name":"Oven"}
        ]
        """)
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.tools, ["Mixer", "Oven"])
    }

    func testToolsAsSingleString() throws {
        let html = recipeHTML(extras: "\"tool\": \"Mixer\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.tools, ["Mixer"])
    }

    // MARK: - Source URL

    func testSourceURLParsed() throws {
        let html = recipeHTML(extras: "\"url\": \"https://example.com/my-recipe\"")
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.sourceURL?.absoluteString, "https://example.com/my-recipe")
    }

    // MARK: - Instructions Multi-Type

    func testInstructionsAsCreativeWork() throws {
        let html = """
        <html><body>
        <script type="application/ld+json">
        {
          "@context":"https://schema.org",
          "@type":"Recipe",
          "name":"Test Recipe",
          "recipeIngredient":["a"],
          "recipeInstructions": {"@type":"CreativeWork","text":"Mix everything and bake."}
        }
        </script>
        </body></html>
        """
        let recipe = try parseRecipe(html)
        XCTAssertEqual(recipe.instructions, ["Mix everything and bake."])
    }

    // MARK: - Helpers

    /// Creates a minimal valid Recipe JSON-LD HTML with optional extra fields.
    private func recipeHTML(extras: String) -> String {
        """
        <html><body>
        <script type="application/ld+json">
        {
          "@context":"https://schema.org",
          "@type":"Recipe",
          "name":"Test Recipe",
          "recipeIngredient":["a"],
          "recipeInstructions":"Do it.",
          \(extras)
        }
        </script>
        </body></html>
        """
    }

    private func parseRecipe(_ html: String) throws -> Recipe {
        let doc = try SwiftSoup.parse(html)
        let scraper = SchemaOrgScraper()
        return try scraper.scrape(document: doc, url: URL(string: "https://example.com/test")!)
    }
}
