import SwiftUI

struct CardShareSheet: View {
    let card: Card
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?
    @State private var showActivity = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 预览
                CardSharePreview(card: card)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)

                Spacer()

                // 分享按钮
                Button {
                    renderAndShare()
                } label: {
                    Label("分享图片", systemImage: "square.and.arrow.up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .navigationTitle("分享卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showActivity) {
                if let img = renderedImage {
                    ActivityView(items: [img])
                }
            }
        }
    }

    private func renderAndShare() {
        let renderer = ImageRenderer(content:
            CardSharePreview(card: card)
                .frame(width: 320)
                .environment(\.colorScheme, .light)
        )
        renderer.scale = 3
        renderedImage = renderer.uiImage
        showActivity = true
    }
}

struct CardSharePreview: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(card.theme.emoji).font(.title2)
                Text(card.theme.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text(card.difficultyStars)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer().frame(height: 24)

            Text(card.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)

            Spacer().frame(height: 24)

            HStack {
                Spacer()
                Text("陌生城市漫步卡")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 320, height: 220)
        .background(card.theme.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
