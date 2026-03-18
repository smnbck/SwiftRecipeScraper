import Foundation

enum SchemaOrgMapper {
    static func mapRecipe(from recipeObject: JSONValue, url: URL) throws -> Recipe {
        guard case .object(let obj) = recipeObject else {
            throw ScraperError.invalidJSONLD("Recipe JSON-LD was not an object.")
        }

        let host = url.host ?? ""

        // MARK: - Title (optional)

        let title = firstNonEmptyString(
            obj["name"],
            obj["headline"]
        )

        let ingredients = parseIngredients(obj["recipeIngredient"])
        let instructions = parseInstructions(obj["recipeInstructions"])
        let imageURLs = parseImageURLs(obj["image"], baseURL: url)
        let recipeYield = parseRecipeYield(obj["recipeYield"])
        let recipeCategory = parseStringOrArray(obj["recipeCategory"])
        let recipeCuisine = parseStringOrArray(obj["recipeCuisine"])
        let cookingMethod = firstNonEmptyString(obj["cookingMethod"])
        let suitableForDiet = parseSuitableForDiet(obj["suitableForDiet"])
        let nutrition = parseNutrition(obj["nutrition"])
        let prepTime = parseDuration(obj["prepTime"])
        let cookTime = parseDuration(obj["cookTime"])
        let totalTime = parseDuration(obj["totalTime"])
        let description = firstNonEmptyString(obj["description"])
        let sourceURL = parseSourceURL(obj["url"], baseURL: url)
        let author = parseAuthor(obj["author"])
        let keywords = parseKeywords(obj["keywords"])
        let aggregateRating = parseAggregateRating(obj["aggregateRating"])
        let datePublished = parseDate(obj["datePublished"])
        let dateModified = parseDate(obj["dateModified"])
        let videoURL = parseVideoURL(obj["video"], baseURL: url)
        let language = firstNonEmptyString(obj["inLanguage"])
        let tools = parseTools(obj["tool"])

        return Recipe(
            title: title,
            description: description,
            sourceURL: sourceURL,
            imageURLs: imageURLs,
            author: author,
            keywords: keywords,
            aggregateRating: aggregateRating,
            datePublished: datePublished,
            dateModified: dateModified,
            videoURL: videoURL,
            language: language,
            prepTime: prepTime,
            cookTime: cookTime,
            totalTime: totalTime,
            tools: tools,
            ingredients: ingredients,
            instructions: instructions,
            recipeYield: recipeYield,
            recipeCategory: recipeCategory,
            recipeCuisine: recipeCuisine,
            cookingMethod: cookingMethod,
            suitableForDiet: suitableForDiet,
            nutrition: nutrition,
            host: host
        )
    }

    // MARK: - Shared Helpers

    private static func firstNonEmptyString(_ values: JSONValue?...) -> String? {
        for v in values {
            if let s = v?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                return s
            }
        }
        return nil
    }

    /// Extracts a non-empty trimmed string from a single JSONValue.
    private static func trimmedString(_ value: JSONValue?) -> String? {
        guard let s = value?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !s.isEmpty else { return nil }
        return s
    }

    // MARK: - Ingredients (Text | [Text] | ItemList | PropertyValue)

    private static func parseIngredients(_ value: JSONValue?) -> [String] {
        guard let value else { return [] }
        switch value {
        case .array(let arr):
            return arr.compactMap { trimmedString($0) }
                .filter { !$0.isEmpty }
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]
        case .object(let obj):
            // ItemList: {"@type":"ItemList","itemListElement":[...]}
            if let items = obj["itemListElement"]?.arrayValue {
                return items.compactMap { item -> String? in
                    if let s = item.stringValue { return s.trimmingCharacters(in: .whitespacesAndNewlines) }
                    if let o = item.objectValue {
                        return trimmedString(o["name"]) ?? trimmedString(o["item"])
                    }
                    return nil
                }.filter { !$0.isEmpty }
            }
            // PropertyValue: {"@type":"PropertyValue","value":"..."}
            if let v = trimmedString(obj["value"]) {
                return [v]
            }
            return []
        default:
            return []
        }
    }

    // MARK: - Instructions (Text | [Text] | CreativeWork | ItemList | [HowToStep/HowToSection])

    private static func parseInstructions(_ value: JSONValue?) -> [String] {
        guard let value else { return [] }

        switch value {
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]

        case .array(let arr):
            return arr.flatMap { instructionParts(from: $0) }

        case .object:
            return instructionParts(from: value)

        default:
            return []
        }
    }

    private static func instructionParts(from value: JSONValue) -> [String] {
        switch value {
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]

        case .object(let obj):
            // ItemList / HowToSection: {"itemListElement":[...]}
            if let nested = obj["itemListElement"]?.arrayValue {
                let nestedParts = nested.flatMap { instructionParts(from: $0) }
                if !nestedParts.isEmpty {
                    // HowToSection with name
                    if let name = trimmedString(obj["name"]) {
                        return [name] + nestedParts
                    }
                    return nestedParts
                }
            }
            // CreativeWork / HowToStep: prefer "text", fallback to "name"
            if let text = trimmedString(obj["text"]) {
                return [text]
            }
            if let name = trimmedString(obj["name"]) {
                return [name]
            }
            return []

        case .array(let arr):
            return arr.flatMap { instructionParts(from: $0) }

        default:
            return []
        }
    }

    // MARK: - Image (URL | ImageObject | [URL] | [ImageObject])

    private static func parseImageURLs(_ value: JSONValue?, baseURL: URL) -> [URL] {
        guard let value else { return [] }
        switch value {
        case .string(let s):
            if let url = URL(string: s.trimmingCharacters(in: .whitespacesAndNewlines), relativeTo: baseURL)?.absoluteURL {
                return [url]
            }
            return []
        case .array(let arr):
            return arr.flatMap { parseImageURLs($0, baseURL: baseURL) }
        case .object(let obj):
            // ImageObject: {"@type":"ImageObject","url":"...","contentUrl":"..."}
            if let s = trimmedString(obj["url"]),
               let url = URL(string: s, relativeTo: baseURL)?.absoluteURL {
                return [url]
            }
            if let s = trimmedString(obj["contentUrl"]),
               let url = URL(string: s, relativeTo: baseURL)?.absoluteURL {
                return [url]
            }
            return []
        default:
            return []
        }
    }

    // MARK: - Duration (ISO 8601)

    private static func parseDuration(_ value: JSONValue?) -> TimeInterval? {
        guard let s = value?.stringValue else { return nil }
        return ISO8601DurationParser.parseSeconds(s)
    }

    // MARK: - Recipe Yield (Text | QuantitativeValue | Number)

    private static func parseRecipeYield(_ value: JSONValue?) -> String? {
        guard let value else { return nil }
        switch value {
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case .number(let n):
            // Some sites provide yield as a plain number
            let intValue = Int(n)
            return Double(intValue) == n ? "\(intValue)" : "\(n)"
        case .object(let obj):
            // QuantitativeValue: {"@type":"QuantitativeValue","value":4,"unitText":"servings"}
            let valueStr: String?
            if let s = trimmedString(obj["value"]) {
                valueStr = s
            } else if case .number(let n)? = obj["value"] {
                let intValue = Int(n)
                valueStr = Double(intValue) == n ? "\(intValue)" : "\(n)"
            } else {
                valueStr = nil
            }
            let unit = trimmedString(obj["unitText"]) ?? trimmedString(obj["unitCode"])
            if let v = valueStr, let u = unit {
                return "\(v) \(u)"
            }
            return valueStr
        case .array(let arr):
            // Take first meaningful value
            for item in arr {
                if let result = parseRecipeYield(item) {
                    return result
                }
            }
            return nil
        default:
            return nil
        }
    }

    // MARK: - String or Array (Text | [Text] | DefinedTerm)

    /// Parses a Schema.org property that can be a single string, array, or DefinedTerm.
    /// Used for `recipeCategory`, `recipeCuisine`.
    private static func parseStringOrArray(_ value: JSONValue?) -> [String] {
        guard let value else { return [] }
        switch value {
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]
        case .array(let arr):
            return arr.compactMap { item -> String? in
                switch item {
                case .string(let s):
                    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                case .object(let obj):
                    return trimmedString(obj["name"])
                default:
                    return nil
                }
            }
        case .object(let obj):
            // DefinedTerm: {"@type":"DefinedTerm","name":"..."}
            if let name = trimmedString(obj["name"]) {
                return [name]
            }
            return []
        default:
            return []
        }
    }

    // MARK: - Suitable for Diet (RestrictedDiet | [RestrictedDiet])

    private static func parseSuitableForDiet(_ value: JSONValue?) -> [String] {
        guard let value else { return [] }
        switch value {
        case .string(let s):
            let cleaned = stripSchemaOrgPrefix(s.trimmingCharacters(in: .whitespacesAndNewlines))
            return cleaned.isEmpty ? [] : [cleaned]
        case .array(let arr):
            return arr.compactMap { item -> String? in
                if let s = item.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    let cleaned = stripSchemaOrgPrefix(s)
                    return cleaned.isEmpty ? nil : cleaned
                }
                return nil
            }
        default:
            return []
        }
    }

    private static func stripSchemaOrgPrefix(_ value: String) -> String {
        // "https://schema.org/GlutenFreeDiet" -> "GlutenFreeDiet"
        if value.lowercased().hasPrefix("http://schema.org/") {
            return String(value.dropFirst("http://schema.org/".count))
        }
        if value.lowercased().hasPrefix("https://schema.org/") {
            return String(value.dropFirst("https://schema.org/".count))
        }
        return value
    }

    // MARK: - Nutrition (NutritionInformation object)

    private static func parseNutrition(_ value: JSONValue?) -> NutritionInfo? {
        guard let obj = value?.objectValue else { return nil }

        let info = NutritionInfo(
            calories: trimmedString(obj["calories"]),
            fatContent: trimmedString(obj["fatContent"]),
            saturatedFatContent: trimmedString(obj["saturatedFatContent"]),
            transFatContent: trimmedString(obj["transFatContent"]),
            unsaturatedFatContent: trimmedString(obj["unsaturatedFatContent"]),
            cholesterolContent: trimmedString(obj["cholesterolContent"]),
            sodiumContent: trimmedString(obj["sodiumContent"]),
            carbohydrateContent: trimmedString(obj["carbohydrateContent"]),
            fiberContent: trimmedString(obj["fiberContent"]),
            sugarContent: trimmedString(obj["sugarContent"]),
            proteinContent: trimmedString(obj["proteinContent"]),
            servingSize: trimmedString(obj["servingSize"])
        )

        // Return nil if all fields are empty
        if info == NutritionInfo() { return nil }
        return info
    }

    // MARK: - Author (Text | Person | Organization | [Person/Organization])

    private static func parseAuthor(_ value: JSONValue?) -> String? {
        guard let value else { return nil }
        switch value {
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case .object(let obj):
            // Person or Organization: {"@type":"Person","name":"John Doe"}
            return trimmedString(obj["name"])
        case .array(let arr):
            // Multiple authors: take names, join with ", "
            let names = arr.compactMap { item -> String? in
                switch item {
                case .string(let s):
                    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                case .object(let obj):
                    return trimmedString(obj["name"])
                default:
                    return nil
                }
            }
            return names.isEmpty ? nil : names.joined(separator: ", ")
        default:
            return nil
        }
    }

    // MARK: - Keywords (Text (comma-separated) | [Text] | DefinedTerm | URL)

    private static func parseKeywords(_ value: JSONValue?) -> [String] {
        guard let value else { return [] }
        switch value {
        case .string(let s):
            // Keywords as comma-separated string: "easy, quick, dinner"
            return s.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        case .array(let arr):
            return arr.compactMap { item -> String? in
                switch item {
                case .string(let s):
                    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                case .object(let obj):
                    // DefinedTerm: {"@type":"DefinedTerm","name":"easy"}
                    return trimmedString(obj["name"])
                default:
                    return nil
                }
            }
        case .object(let obj):
            // Single DefinedTerm
            if let name = trimmedString(obj["name"]) {
                return [name]
            }
            return []
        default:
            return []
        }
    }

    // MARK: - Aggregate Rating (AggregateRating object)

    private static func parseAggregateRating(_ value: JSONValue?) -> RecipeAggregateRating? {
        guard let obj = value?.objectValue else { return nil }

        let ratingValue = parseDouble(obj["ratingValue"])
        let ratingCount = parseInt(obj["ratingCount"])
        let reviewCount = parseInt(obj["reviewCount"])
        let bestRating = parseDouble(obj["bestRating"])
        let worstRating = parseDouble(obj["worstRating"])

        // Return nil if no meaningful data
        if ratingValue == nil, ratingCount == nil, reviewCount == nil {
            return nil
        }

        return RecipeAggregateRating(
            ratingValue: ratingValue,
            ratingCount: ratingCount,
            reviewCount: reviewCount,
            bestRating: bestRating,
            worstRating: worstRating
        )
    }

    /// Parses a number from a JSONValue that may be `.number` or `.string` containing digits.
    private static func parseDouble(_ value: JSONValue?) -> Double? {
        guard let value else { return nil }
        switch value {
        case .number(let n): return n
        case .string(let s): return Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        default: return nil
        }
    }

    private static func parseInt(_ value: JSONValue?) -> Int? {
        guard let d = parseDouble(value) else { return nil }
        return Int(d)
    }

    // MARK: - Dates (Date | DateTime as string)

    private static func parseDate(_ value: JSONValue?) -> Date? {
        guard let s = value?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !s.isEmpty else { return nil }

        // Try ISO 8601 with time first, then date-only
        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: s) {
                return date
            }
        }
        return nil
    }

    private static let dateFormatters: [DateFormatter] = {
        let iso8601Full = DateFormatter()
        iso8601Full.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        iso8601Full.locale = Locale(identifier: "en_US_POSIX")

        let iso8601NoTZ = DateFormatter()
        iso8601NoTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        iso8601NoTZ.locale = Locale(identifier: "en_US_POSIX")
        iso8601NoTZ.timeZone = TimeZone(secondsFromGMT: 0)

        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.timeZone = TimeZone(secondsFromGMT: 0)

        return [iso8601Full, iso8601NoTZ, dateOnly]
    }()

    // MARK: - Video (Clip | VideoObject | URL string)

    private static func parseVideoURL(_ value: JSONValue?, baseURL: URL) -> URL? {
        guard let value else { return nil }
        switch value {
        case .string(let s):
            return URL(string: s.trimmingCharacters(in: .whitespacesAndNewlines), relativeTo: baseURL)?.absoluteURL
        case .object(let obj):
            // VideoObject / Clip: prefer contentUrl, then embedUrl, then url
            if let s = trimmedString(obj["contentUrl"]) {
                return URL(string: s, relativeTo: baseURL)?.absoluteURL
            }
            if let s = trimmedString(obj["embedUrl"]) {
                return URL(string: s, relativeTo: baseURL)?.absoluteURL
            }
            if let s = trimmedString(obj["url"]) {
                return URL(string: s, relativeTo: baseURL)?.absoluteURL
            }
            return nil
        case .array(let arr):
            // Take first valid video URL
            for item in arr {
                if let url = parseVideoURL(item, baseURL: baseURL) {
                    return url
                }
            }
            return nil
        default:
            return nil
        }
    }

    // MARK: - Source URL

    private static func parseSourceURL(_ value: JSONValue?, baseURL: URL) -> URL? {
        guard let s = value?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !s.isEmpty else { return nil }
        return URL(string: s, relativeTo: baseURL)?.absoluteURL
    }

    // MARK: - Tools (HowToTool | Text | [HowToTool | Text])

    private static func parseTools(_ value: JSONValue?) -> [String] {
        guard let value else { return [] }
        switch value {
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]
        case .object(let obj):
            // HowToTool: {"@type":"HowToTool","name":"Mixer"}
            if let name = trimmedString(obj["name"]) {
                return [name]
            }
            return []
        case .array(let arr):
            return arr.compactMap { item -> String? in
                switch item {
                case .string(let s):
                    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                case .object(let obj):
                    return trimmedString(obj["name"])
                default:
                    return nil
                }
            }
        default:
            return []
        }
    }
}
