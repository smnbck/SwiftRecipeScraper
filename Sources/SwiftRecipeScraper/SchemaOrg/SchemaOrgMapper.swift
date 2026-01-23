import Foundation

enum SchemaOrgMapper {
    static func mapRecipe(from recipeObject: JSONValue, url: URL) throws -> Recipe {
        guard case .object(let obj) = recipeObject else {
            throw ScraperError.invalidJSONLD("Recipe JSON-LD was not an object.")
        }

        let host = url.host ?? ""

        let title = firstNonEmptyString(
            obj["name"],
            obj["headline"]
        )
        guard let title else { throw ScraperError.missingRequiredField("title") }

        let ingredients = parseIngredients(obj["recipeIngredient"])
        let instructions = parseInstructions(obj["recipeInstructions"]) ?? ""

        let imageURL = parseImageURL(obj["image"], baseURL: url)
        let prepTime = parsePrepTimeSeconds(obj)

        return Recipe(
            title: title,
            ingredients: ingredients,
            instructions: instructions,
            imageURL: imageURL,
            prepTime: prepTime,
            host: host
        )
    }

    private static func firstNonEmptyString(_ values: JSONValue?...) -> String? {
        for v in values {
            if let s = v?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                return s
            }
        }
        return nil
    }

    private static func parseIngredients(_ value: JSONValue?) -> [String] {
        guard let value else { return [] }
        switch value {
        case .array(let arr):
            return arr.compactMap { $0.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]
        default:
            return []
        }
    }

    private static func parseInstructions(_ value: JSONValue?) -> String? {
        guard let value else { return nil }

        switch value {
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed

        case .array(let arr):
            let parts = arr.flatMap { instructionParts(from: $0) }
            let joined = parts.joined(separator: "\n")
            return joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : joined

        case .object:
            let parts = instructionParts(from: value)
            let joined = parts.joined(separator: "\n")
            return joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : joined

        default:
            return nil
        }
    }

    private static func instructionParts(from value: JSONValue) -> [String] {
        switch value {
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]

        case .object(let obj):
            // HowToStep / HowToSection commonly uses "text"; sometimes "name".
            if let text = obj["text"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty {
                return [text]
            }
            if let name = obj["name"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
               !name.isEmpty {
                return [name]
            }
            // Nested steps: {"itemListElement":[...]}
            if let nested = obj["itemListElement"]?.arrayValue {
                return nested.flatMap { instructionParts(from: $0) }
            }
            return []

        case .array(let arr):
            return arr.flatMap { instructionParts(from: $0) }

        default:
            return []
        }
    }

    private static func parseImageURL(_ value: JSONValue?, baseURL: URL) -> URL? {
        guard let value else { return nil }
        switch value {
        case .string(let s):
            return URL(string: s.trimmingCharacters(in: .whitespacesAndNewlines), relativeTo: baseURL)?.absoluteURL
        case .array(let arr):
            for item in arr {
                if let url = parseImageURL(item, baseURL: baseURL) {
                    return url
                }
            }
            return nil
        case .object(let obj):
            if let s = obj["url"]?.stringValue {
                return URL(string: s.trimmingCharacters(in: .whitespacesAndNewlines), relativeTo: baseURL)?.absoluteURL
            }
            return nil
        default:
            return nil
        }
    }

    private static func parsePrepTimeSeconds(_ obj: [String: JSONValue]) -> TimeInterval? {
        // Prefer explicit prepTime; fall back to totalTime/cookTime if that's what's available.
        let candidates: [JSONValue?] = [obj["prepTime"], obj["totalTime"], obj["cookTime"]]
        for c in candidates {
            if let s = c?.stringValue, let seconds = ISO8601DurationParser.parseSeconds(s) {
                return seconds
            }
        }
        return nil
    }
}
