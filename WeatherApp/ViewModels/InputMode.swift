import Foundation

/// How the user tells the app where they want the forecast for.
enum InputMode: Hashable, CaseIterable {
    case place
    case coordinates

    var title: String {
        switch self {
        case .place: "Place"
        case .coordinates: "Coordinates"
        }
    }
}
