import SwiftUI
import Supabase

struct CheckIn: Identifiable, Decodable {
    let id: String
    let note: String?
    let photoUrl: String?
    let createdAt: String
    let cards: CardRef?

    struct CardRef: Decodable {
        let title: String
        let theme: Theme
    }

    enum CodingKeys: String, CodingKey {
        case id, note
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case cards
    }
}

struct CommunityCheckIn: Identifiable, Decodable {
    let id: String
    let note: String?
    let photoUrl: String?
    let createdAt: String
    let cards: CheckIn.CardRef?
    let profiles: Profile?

    struct Profile: Decodable {
        let email: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, note, profiles
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case cards
    }
}

// MARK: - My Log

@MainActor
class LogViewModel: ObservableObject {
    @Published var checkIns: [CheckIn] = []
    @Published var isLoading = false
    @Published var selectedTheme: Theme? = nil

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            var filterBuilder = supabase
                .from("check_ins")
                .select("id, note, photo_url, created_at, cards(title, theme)")
                .eq("user_id", value: userId)

            if let theme = selectedTheme {
                filterBuilder = filterBuilder.eq("cards.theme", value: theme.rawValue)
            }

            checkIns = try await filterBuilder
                .order("created_at", ascending: false)
                .execute().value
        } catch {
            print("[LogView] load error:", error)
        }
    }
}

// MARK: - Community

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var checkIns: [CommunityCheckIn] = []
    @Published var isLoading = false
    @Published var selectedTheme: Theme? = nil

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var filterBuilder = supabase
                .from("check_ins")
                .select("id, note, photo_url, created_at, cards(title, theme), profiles(email)")

            if let theme = selectedTheme {
                filterBuilder = filterBuilder.eq("cards.theme", value: theme.rawValue)
            }

            checkIns = try await filterBuilder
                .order("created_at", ascending: false)
                .limit(50)
                .execute().value
        } catch {
            print("[CommunityView] load error:", error)
        }
    }
}

// MARK: - LogView

struct LogView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var tab = 0
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab 切换
                Picker("", selection: $tab) {
                    Text("我的日志").tag(0)
                    Text("社区广场").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if tab == 0 {
                    MyLogView()
                        .environmentObject(authStore)
                } else {
                    CommunityView()
                }
            }
            .navigationTitle("漫志")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: authStore.user != nil ? "person.crop.circle.fill" : "person.crop.circle")
                            .foregroundStyle(authStore.user != nil ? .primary : .secondary)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView().environmentObject(authStore)
            }
        }
    }
}

// MARK: - My Log Tab

struct MyLogView: View {
    @StateObject private var vm = LogViewModel()
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                themeMenu
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

    var themeMenu: some View {
        Menu {
            Button("全部") { vm.selectedTheme = nil }
            ForEach(Theme.allCases.filter { $0 != .random }, id: \.self) { theme in
                Button { vm.selectedTheme = theme } label: {
                Label(theme.label, systemImage: theme.symbolName)
            }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

// MARK: - Community Tab

struct CommunityView: View {
    @StateObject private var vm = CommunityViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
            } else if vm.checkIns.isEmpty {
                ContentUnavailableView(
                    "暂无社区内容",
                    systemImage: "person.2",
                    description: Text("完成漫步后打卡，你的记录将出现在这里")
                )
            } else {
                List(vm.checkIns) { item in
                    CommunityRow(checkIn: item)
                }
                .listStyle(.plain)
            }
        }
        .task { await vm.load() }
        .onChange(of: vm.selectedTheme) { _, _ in
            Task { await vm.load() }
        }
    }
}

// MARK: - Rows

struct CheckInRow: View {
    let checkIn: CheckIn

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let card = checkIn.cards {
                HStack(spacing: 6) {
                    Image(systemName: card.theme.symbolName)
                    Text(card.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
            }
            if let photoUrl = checkIn.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        EmptyView()
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .secondarySystemBackground))
                            .frame(height: 160)
                            .overlay(ProgressView())
                    }
                }
            }
            if let note = checkIn.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Text(String(checkIn.createdAt.prefix(10)))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct CommunityRow: View {
    let checkIn: CommunityCheckIn

    var displayName: String {
        if let email = checkIn.profiles?.email {
            return String(email.split(separator: "@").first ?? "漫游者")
        }
        return "漫游者"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.secondary)
                Text(displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(checkIn.createdAt.prefix(10)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if let card = checkIn.cards {
                HStack(spacing: 6) {
                    Image(systemName: card.theme.symbolName)
                    Text(card.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
            }
            if let photoUrl = checkIn.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        EmptyView()
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .secondarySystemBackground))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    }
                }
            }
            if let note = checkIn.note, !note.isEmpty {
                Text(note)
                    .font(.body)
                    .lineLimit(4)
            }
        }
        .padding(.vertical, 6)
    }
}
