import Foundation

/// Nutritional information for a recipe, mapped from Schema.org `NutritionInformation`.
///
/// All values are optional strings because Schema.org delivers them as text
/// (e.g. "500 calories", "25 g") rather than structured numeric values.
public struct NutritionInfo: Codable, Equatable, Sendable {
    /// Total energy content (e.g. "500 calories").
    public var calories: String?
    /// Total fat (e.g. "25 g").
    public var fatContent: String?
    /// Saturated fat (e.g. "10 g").
    public var saturatedFatContent: String?
    /// Trans fat (e.g. "0 g").
    public var transFatContent: String?
    /// Unsaturated fat (e.g. "15 g").
    public var unsaturatedFatContent: String?
    /// Cholesterol (e.g. "50 mg").
    public var cholesterolContent: String?
    /// Sodium (e.g. "300 mg").
    public var sodiumContent: String?
    /// Total carbohydrates (e.g. "60 g").
    public var carbohydrateContent: String?
    /// Dietary fiber (e.g. "5 g").
    public var fiberContent: String?
    /// Sugar (e.g. "10 g").
    public var sugarContent: String?
    /// Protein (e.g. "20 g").
    public var proteinContent: String?
    /// Serving size description (e.g. "1 cup", "100g").
    public var servingSize: String?

    public init(
        calories: String? = nil,
        fatContent: String? = nil,
        saturatedFatContent: String? = nil,
        transFatContent: String? = nil,
        unsaturatedFatContent: String? = nil,
        cholesterolContent: String? = nil,
        sodiumContent: String? = nil,
        carbohydrateContent: String? = nil,
        fiberContent: String? = nil,
        sugarContent: String? = nil,
        proteinContent: String? = nil,
        servingSize: String? = nil
    ) {
        self.calories = calories
        self.fatContent = fatContent
        self.saturatedFatContent = saturatedFatContent
        self.transFatContent = transFatContent
        self.unsaturatedFatContent = unsaturatedFatContent
        self.cholesterolContent = cholesterolContent
        self.sodiumContent = sodiumContent
        self.carbohydrateContent = carbohydrateContent
        self.fiberContent = fiberContent
        self.sugarContent = sugarContent
        self.proteinContent = proteinContent
        self.servingSize = servingSize
    }
}
