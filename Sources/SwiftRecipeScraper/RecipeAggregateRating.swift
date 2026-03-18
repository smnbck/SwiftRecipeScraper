import Foundation

/// Aggregate rating for a recipe, mapped from Schema.org `AggregateRating`.
public struct RecipeAggregateRating: Codable, Equatable, Sendable {
    /// Average rating value (e.g. 4.5).
    public var ratingValue: Double?
    /// Total number of ratings.
    public var ratingCount: Int?
    /// Total number of reviews (may differ from ratingCount).
    public var reviewCount: Int?
    /// Highest possible rating value (e.g. 5).
    public var bestRating: Double?
    /// Lowest possible rating value (e.g. 1).
    public var worstRating: Double?

    public init(
        ratingValue: Double? = nil,
        ratingCount: Int? = nil,
        reviewCount: Int? = nil,
        bestRating: Double? = nil,
        worstRating: Double? = nil
    ) {
        self.ratingValue = ratingValue
        self.ratingCount = ratingCount
        self.reviewCount = reviewCount
        self.bestRating = bestRating
        self.worstRating = worstRating
    }
}
