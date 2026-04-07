import SwiftUI

// MARK: - Theme Colors

extension Theme {
    var cardGradient: LinearGradient {
        switch self {
        case .food:
            return LinearGradient(colors: [Color(hex: "FF6B35"), Color(hex: "FF8C61")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .architecture:
            return LinearGradient(colors: [Color(hex: "2C3E50"), Color(hex: "4A6FA5")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .culture:
            return LinearGradient(colors: [Color(hex: "6C3483"), Color(hex: "9B59B6")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .nature:
            return LinearGradient(colors: [Color(hex: "1A7A4A"), Color(hex: "27AE60")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .colorWalk:
            return LinearGradient(colors: [Color(hex: "E67E22"), Color(hex: "F39C12"), Color(hex: "E74C3C")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .random:
            return LinearGradient(colors: [Color(hex: "2C3E50"), Color(hex: "3D5A80")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Flip View

struct CardFlipView: View {
    let card: Card
    @State private var isFlipped = false

    var body: some View {
        ZStack {
            CardFrontView(card: card)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            CardBackView(card: card)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .onChange(of: card.id) { _, _ in
            withAnimation { isFlipped = false }
        }
    }
}

// MARK: - Front

struct CardFrontView: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: card.theme.symbolName)
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                    Text(card.theme.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                if !card.isUniversal {
                    Label("地区专属", systemImage: "building.2")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            // 任务文字
            Text(card.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)

            Spacer()

            // 底部
            HStack {
                Text(card.difficultyStars)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("轻触查看提示 →")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(card.theme.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
    }
}

// MARK: - Back

struct CardBackView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(card.theme.cardGradient)

            Text(card.hint)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(28)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.08), radius: 24, y: 8)
    }
}

// MARK: - Placeholder

struct CardPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("选好主题，点击下方抽卡")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundStyle(Color.secondary.opacity(0.3))
        )
    }
}
