import Foundation

/// A normalized representation of a recipe across different sources.
public struct Recipe: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var ingredients: [String]
    public var instructions: String
    public var imageURL: URL?
    /// Preparation time in seconds (if known).
    public var prepTime: TimeInterval?
    /// Hostname of the source website (e.g. "allrecipes.com").
    public var host: String

    public init(
        id: UUID = UUID(),
        title: String,
        ingredients: [String],
        instructions: String,
        imageURL: URL? = nil,
        prepTime: TimeInterval? = nil,
        host: String
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.imageURL = imageURL
        self.prepTime = prepTime
        self.host = host
    }
}
