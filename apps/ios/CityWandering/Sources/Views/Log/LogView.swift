import SwiftUI
import Supabase

struct CheckIn: Identifiable, Decodable {
    let id: String
    let note: String?
    let createdAt: String
    let cards: CardRef?

    struct CardRef: Decodable {
        let title: String
        let theme: Theme
    }

    enum CodingKeys: String, CodingKey {
        case id, note
        case createdAt = "created_at"
        case cards
    }
}

@MainActor
class LogViewModel: ObservableObject {
    @Published var checkIns: [CheckIn] = []
    @Published var isLoading = false
    @Published var selectedTheme: Theme? = nil

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            var query = supabase
                .from("check_ins")
                .select("id, note, created_at, cards(title, theme)")
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)

            if let theme = selectedTheme {
                query = query.eq("cards.theme", value: theme.rawValue)
            }

            checkIns = try await query.execute().value
        } catch {
            print("[LogView] load error:", error)
        }
    }
}

struct LogView: View {
    @StateObject private var vm = LogViewModel()
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        NavigationStack {
            Group {
                if authStore.user == nil {
                    ContentUnavailableView(
                        "登录后查看漫步日志",
                        systemImage: "list.bullet.clipboard",
                        description: Text("记录每一次城市漫步")
                    )
                } else if vm.isLoading {
                    ProgressView()
                } else if vm.checkIns.isEmpty {
                    ContentUnavailableView(
                        "还没有打卡记录",
                        systemImage: "mappin.slash",
                        description: Text("完成一张漫步卡后打卡签到")
                    )
                } else {
                    List(vm.checkIns) { item in
                        CheckInRow(checkIn: item)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("漫步日志")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("全部") { vm.selectedTheme = nil }
                        ForEach(Theme.allCases.filter { $0 != .random }, id: \.self) { theme in
                            Button("\(theme.emoji) \(theme.label)") { vm.selectedTheme = theme }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .task(id: authStore.user?.id) {
                guard let uid = authStore.user?.id.uuidString else { return }
                await vm.load(userId: uid)
            }
            .onChange(of: vm.selectedTheme) { _, _ in
                guard let uid = authStore.user?.id.uuidString else { return }
                Task { await vm.load(userId: uid) }
            }
        }
    }
}

struct CheckInRow: View {
    let checkIn: CheckIn

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let card = checkIn.cards {
                HStack(spacing: 6) {
                    Text(card.theme.emoji)
                    Text(card.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
            }
            if let note = checkIn.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Text(checkIn.createdAt.prefix(10))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
