import SwiftUI

/// One match in the place list: name in bold, region and country below.
struct PlaceRowView: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(place.name)
                .font(.body.weight(.semibold))
            if !place.detail.isEmpty {
                Text(place.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
