import SwiftUI

struct ThemePickerView: View {
    @Binding var selected: Theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Theme.allCases, id: \.self) { theme in
                    Button {
                        selected = theme
                    } label: {
                        HStack(spacing: 4) {
                            Text(theme.emoji)
                                .font(.caption)
                            Text(theme.label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selected == theme ? Color.primary : Color(uiColor: .secondarySystemBackground))
                        .foregroundStyle(selected == theme ? Color(uiColor: .systemBackground) : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: selected)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
