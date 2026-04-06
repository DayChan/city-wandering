import SwiftUI

struct CityPillButton: View {
    @ObservedObject var store: LocationStore
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if store.isDetecting {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.secondary)
                } else {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(store.city != nil ? .primary : .secondary)
                }
                Text(store.city?.label ?? "选择城市")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(store.city != nil ? .primary : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
