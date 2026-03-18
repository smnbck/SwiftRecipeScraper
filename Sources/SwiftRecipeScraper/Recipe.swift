import Foundation

/// A normalized representation of a recipe across different sources,
/// aligned with the Schema.org Recipe type (https://schema.org/Recipe).
public struct Recipe: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID

    // MARK: - Thing Properties

    /// Recipe title (Schema.org `name` or `headline`). May be `nil` if the source did not provide one.
    public var title: String?
    /// Full description or summary of the recipe (Schema.org `description`).
    public var description: String?
    /// Full source URL of the recipe (Schema.org `url`).
    public var sourceURL: URL?
    /// Image URLs (Schema.org `image`). Many sites provide multiple images.
    public var imageURLs: [URL]

    // MARK: - CreativeWork Properties

    /// Author name (Schema.org `author` – Person, Organization, or plain text).
    public var author: String?
    /// Keywords or tags for search and filtering (Schema.org `keywords`).
    public var keywords: [String]
    /// Aggregate user rating (Schema.org `aggregateRating`).
    public var aggregateRating: RecipeAggregateRating?
    /// Date the recipe was first published (Schema.org `datePublished`).
    public var datePublished: Date?
    /// Date the recipe was last modified (Schema.org `dateModified`).
    public var dateModified: Date?
    /// Video instruction URL (Schema.org `video`).
    public var videoURL: URL?
    /// Language code, e.g. "en", "de" (Schema.org `inLanguage`).
    public var language: String?

    // MARK: - HowTo Properties

    /// Preparation time in seconds (Schema.org `prepTime`, ISO 8601 duration).
    public var prepTime: TimeInterval?
    /// Active cooking time in seconds (Schema.org `cookTime`, ISO 8601 duration).
    public var cookTime: TimeInterval?
    /// Total time in seconds (Schema.org `totalTime`, ISO 8601 duration).
    public var totalTime: TimeInterval?
    /// Equipment needed (Schema.org `tool` from HowTo).
    public var tools: [String]

    // MARK: - Recipe Properties

    /// Ingredient list (Schema.org `recipeIngredient`).
    public var ingredients: [String]
    /// Preparation instructions as individual steps (Schema.org `recipeInstructions`).
    public var instructions: [String]
    /// Yield / servings, e.g. "4 servings" (Schema.org `recipeYield`).
    public var recipeYield: String?
    /// Category like appetizer, main course, dessert (Schema.org `recipeCategory`).
    public var recipeCategory: [String]
    /// Cuisine style like Italian, Mexican (Schema.org `recipeCuisine`).
    public var recipeCuisine: [String]
    /// Cooking method like baking, frying (Schema.org `cookingMethod`).
    public var cookingMethod: String?
    /// Dietary restrictions, e.g. "GlutenFreeDiet", "VeganDiet" (Schema.org `suitableForDiet`).
    public var suitableForDiet: [String]
    /// Nutritional information (Schema.org `nutrition`).
    public var nutrition: NutritionInfo?

    // MARK: - Scraper Metadata

    /// Hostname of the source website (e.g. "allrecipes.com").
    public var host: String

    public init(
        id: UUID = UUID(),
        title: String? = nil,
        description: String? = nil,
        sourceURL: URL? = nil,
        imageURLs: [URL] = [],
        author: String? = nil,
        keywords: [String] = [],
        aggregateRating: RecipeAggregateRating? = nil,
        datePublished: Date? = nil,
        dateModified: Date? = nil,
        videoURL: URL? = nil,
        language: String? = nil,
        prepTime: TimeInterval? = nil,
        cookTime: TimeInterval? = nil,
        totalTime: TimeInterval? = nil,
        tools: [String] = [],
        ingredients: [String] = [],
        instructions: [String] = [],
        recipeYield: String? = nil,
        recipeCategory: [String] = [],
        recipeCuisine: [String] = [],
        cookingMethod: String? = nil,
        suitableForDiet: [String] = [],
        nutrition: NutritionInfo? = nil,
        host: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.sourceURL = sourceURL
        self.imageURLs = imageURLs
        self.author = author
        self.keywords = keywords
        self.aggregateRating = aggregateRating
        self.datePublished = datePublished
        self.dateModified = dateModified
        self.videoURL = videoURL
        self.language = language
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.tools = tools
        self.ingredients = ingredients
        self.instructions = instructions
        self.recipeYield = recipeYield
        self.recipeCategory = recipeCategory
        self.recipeCuisine = recipeCuisine
        self.cookingMethod = cookingMethod
        self.suitableForDiet = suitableForDiet
        self.nutrition = nutrition
        self.host = host
    }
}
