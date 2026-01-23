import Foundation

enum FixtureLoader {
    static func loadString(_ name: String, fileExtension: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: fileExtension) else {
            throw FixtureError.missingFixture("\(name).\(fileExtension)")
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}

enum FixtureError: Error, CustomStringConvertible {
    case missingFixture(String)

    var description: String {
        switch self {
        case .missingFixture(let s):
            return "Missing test fixture: \(s)"
        }
    }
}


