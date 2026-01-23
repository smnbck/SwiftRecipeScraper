import Foundation
import SwiftRecipeScraper

@main
enum SwiftRecipeScraperCLI {
    static func main() async {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            if args.isEmpty || args.contains("--help") || args.contains("-h") {
                printHelp()
                return
            }

            guard let url = URL(string: args[0]), url.scheme != nil else {
                throw CLIError.invalidURL(args[0])
            }

            let client = SwiftRecipeScraperClient()
            let recipe = try await client.scrape(url: url)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(recipe)
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
        } catch {
            FileHandle.standardError.write(Data("Error: \(error)\n".utf8))
            exit(1)
        }
    }

    private static func printHelp() {
        print(
            """
            swift-recipe-scrape

            Usage:
              swift run swift-recipe-scrape <url>

            Output:
              Prints a JSON representation of the scraped recipe to stdout.
            """
        )
    }
}

enum CLIError: Error, CustomStringConvertible {
    case invalidURL(String)

    var description: String {
        switch self {
        case .invalidURL(let s):
            return "Invalid URL: \(s)"
        }
    }
}


