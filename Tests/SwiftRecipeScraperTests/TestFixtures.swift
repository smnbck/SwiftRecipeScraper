import Foundation

enum TestFixtures {
    static func loadString(named name: String, ext: String = "html") throws -> String {
        let url = Bundle.module.url(forResource: name, withExtension: ext)
        guard let url else {
            throw NSError(domain: "TestFixtures", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing fixture: \(name).\(ext)"])
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}


