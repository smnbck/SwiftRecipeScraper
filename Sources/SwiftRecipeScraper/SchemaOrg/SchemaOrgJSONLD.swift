import Foundation
import SwiftSoup

enum SchemaOrgJSONLD {
    static func findRecipeObject(in document: Document) throws -> JSONValue {
        let scripts = try document.select("script[type=\"application/ld+json\"]").array()
        guard !scripts.isEmpty else { throw ScraperError.missingSchemaOrgRecipe }

        for script in scripts {
            let raw = try script.html()
            let jsonText = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !jsonText.isEmpty else { continue }

            let value: JSONValue
            do {
                let data = Data(jsonText.utf8)
                value = try JSONDecoder().decode(JSONValue.self, from: data)
            } catch {
                // Skip invalid JSON-LD blocks; many sites embed multiple scripts.
                continue
            }

            if let recipe = findRecipe(in: value) {
                return recipe
            }
        }

        throw ScraperError.missingSchemaOrgRecipe
    }

    /// Depth-first search for a Schema.org Recipe object in JSON-LD.
    static func findRecipe(in value: JSONValue) -> JSONValue? {
        switch value {
        case .object(let obj):
            if isRecipeObject(obj) {
                return value
            }
            // Common pattern: {"@graph":[...]}
            if let graph = obj["@graph"]?.arrayValue {
                for node in graph {
                    if let found = findRecipe(in: node) { return found }
                }
            }
            // Walk all values for nested structures
            for (_, v) in obj {
                if let found = findRecipe(in: v) { return found }
            }
            return nil

        case .array(let arr):
            for item in arr {
                if let found = findRecipe(in: item) { return found }
            }
            return nil

        default:
            return nil
        }
    }

    static func isRecipeObject(_ obj: [String: JSONValue]) -> Bool {
        guard let type = obj["@type"] else { return false }
        return jsonLDTypeContainsRecipe(type)
    }

    static func jsonLDTypeContainsRecipe(_ type: JSONValue) -> Bool {
        switch type {
        case .string(let s):
            return s.caseInsensitiveCompare("Recipe") == .orderedSame
        case .array(let arr):
            return arr.contains { jsonLDTypeContainsRecipe($0) }
        case .object(let obj):
            // Occasionally sites embed {"@id": "...", "name": "..."} as type; ignore.
            if let s = obj["@type"] {
                return jsonLDTypeContainsRecipe(s)
            }
            return false
        default:
            return false
        }
    }
}
