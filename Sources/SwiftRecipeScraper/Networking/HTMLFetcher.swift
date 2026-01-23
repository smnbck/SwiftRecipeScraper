import Foundation

public enum HTMLFetcher {
    public static func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "SwiftRecipeScraper/0.1.0 (Swift; +https://github.com/smnbck/swift-recipe-scraper)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ScraperError.httpStatus(code: http.statusCode, url: url)
        }
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ScraperError.invalidResponseBody(url: url)
        }
        return html
    }
}
