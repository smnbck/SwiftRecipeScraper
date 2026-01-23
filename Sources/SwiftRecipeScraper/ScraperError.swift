import Foundation

public enum ScraperError: Error, Equatable, Sendable {
    case unsupportedHost(String)
    case httpStatus(code: Int, url: URL)
    case invalidResponseBody(url: URL)
    case invalidHTML(String)
    case missingSchemaOrgRecipe
    case invalidJSONLD(String)
    case missingRequiredField(String)
}
