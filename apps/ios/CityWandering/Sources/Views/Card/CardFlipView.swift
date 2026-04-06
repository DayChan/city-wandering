import SwiftUI

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
            isFlipped = false
        }
    }
}

struct CardFrontView: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部装饰区
            HStack {
                Text(card.theme.emoji)
                    .font(.title2)
                Spacer()
                if !card.isUniversal {
                    Label("地区专属", systemImage: "building.2")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            // 任务文字
            Text(card.title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)

            Spacer()

            // 底部信息
            HStack {
                Text(card.theme.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(card.difficultyStars)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // 点击提示
            Text("轻触查看提示")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 4)
    }
}

struct CardBackView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 16) {
            Text("💡 任务提示")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(card.hint)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(20)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 4)
    }
}

struct CardPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🎴")
                .font(.system(size: 48))
            Text("选好主题，点击下方抽卡")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundStyle(Color.secondary.opacity(0.3))
        )
    }
}
