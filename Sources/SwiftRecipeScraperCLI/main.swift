import Foundation
import SwiftRecipeScraper

@main
struct SwiftRecipeScraperCLI {
    static func main() async {
        do {
            let args = CommandLine.arguments.dropFirst()
            guard let urlString = args.first else {
                fputs("Usage: swift-recipe-scrape <url>\n", stderr)
                exit(2)
            }
            guard let url = URL(string: String(urlString)) else {
                fputs("Invalid URL: \(urlString)\n", stderr)
                exit(2)
            }

            let client = SwiftRecipeScraperClient()
            let recipe = try await client.scrape(url: url)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(recipe)
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
        } catch {
            fputs("Error: \(String(describing: error))\n", stderr)
            exit(1)
        }
    }
}


