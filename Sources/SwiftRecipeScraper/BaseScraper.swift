import Foundation
import SwiftSoup

class BaseScraper: RecipeScraper {
    let host: String

    init(host: String) {
        self.host = host
    }

    func scrape(from url: URL) async throws -> Recipe {
        let html = try await HTMLFetcher.fetchHTML(from: url)
        let document = try makeDocument(fromHTML: html)
        return try scrape(document: document, url: url)
    }

    func scrape(document: Document, url: URL) throws -> Recipe {
        throw ScraperError.missingRequiredField("Override scrape(document:url:) in a subclass.")
    }

    // MARK: - Document

    func makeDocument(fromHTML html: String) throws -> Document {
        do {
            return try SwiftSoup.parse(html)
        } catch {
            throw ScraperError.invalidHTML(String(describing: error))
        }
    }

    // MARK: - Utilities

    func firstText(_ css: String, in document: Document) throws -> String? {
        let el = try document.select(css).first()
        let text = try el?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        return text?.isEmpty == true ? nil : text
    }

    func firstAttr(_ css: String, attr: String, in document: Document) throws -> String? {
        let el = try document.select(css).first()
        let value = try el?.attr(attr).trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == true ? nil : value
    }

    func texts(_ css: String, in document: Document) throws -> [String] {
        try document
            .select(css)
            .array()
            .map { try $0.text().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
