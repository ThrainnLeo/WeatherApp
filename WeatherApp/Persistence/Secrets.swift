import Foundation

/// Reads API keys from `Secrets.plist`, which is gitignored and copied into the app by the
/// synced folder. Hugo creates his own copy from `Secrets.example.plist` at the repo root.
nonisolated enum Secrets {
    static let placeholder = "PASTE_YOUR_GEOCODE_MAPS_CO_KEY_HERE"

    private struct File: Decodable {
        let geocodeMapsAPIKey: String

        enum CodingKeys: String, CodingKey {
            case geocodeMapsAPIKey = "GeocodeMapsAPIKey"
        }
    }

    /// `nil` if the file is missing, unreadable, empty or still has the placeholder.
    /// The app then shows "place search isn't set up" instead of sending a request that will fail.
    static func geocodeMapsAPIKey(in bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let file = try? PropertyListDecoder().decode(File.self, from: data)
        else {
            return nil
        }
        let key = file.geocodeMapsAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty || key == placeholder ? nil : key
    }
}
