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

    enum CodingKeys: String, CodingKey {
        case id, note
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
                .select("id, note, photo_url, created_at, cards(title, theme)")

            if let theme = selectedTheme {
                filterBuilder = filterBuilder.eq("cards.theme", value: theme.rawValue)
            }

            checkIns = try await filterBuilder
                .order("created_at", ascending: false)
                .limit(50)
                .execute().value
            print("[Community] loaded \(checkIns.count) items")
        } catch {
            print("[Community] load error:", error)
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
            ToolbarItem(placement: .topBarLeading) {
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
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            HStack(spacing: 12) {
                // 缩略图或主题图标
                if let photoUrl = checkIn.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            Color(uiColor: .secondarySystemBackground)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let card = checkIn.cards {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: 60, height: 60)
                        .overlay(Image(systemName: card.theme.symbolName).foregroundStyle(.secondary))
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let card = checkIn.cards {
                        Text(card.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    if let note = checkIn.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(String(checkIn.createdAt.prefix(10)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CheckInDetailSheet(
                cardTitle: checkIn.cards?.title,
                cardSymbol: checkIn.cards?.theme.symbolName,
                note: checkIn.note,
                photoUrl: checkIn.photoUrl.flatMap(URL.init),
                date: String(checkIn.createdAt.prefix(10))
            )
        }
    }
}

struct CommunityRow: View {
    let checkIn: CommunityCheckIn
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            HStack(spacing: 12) {
                if let photoUrl = checkIn.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            Color(uiColor: .secondarySystemBackground)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let card = checkIn.cards {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: 60, height: 60)
                        .overlay(Image(systemName: card.theme.symbolName).foregroundStyle(.secondary))
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let card = checkIn.cards {
                        Text(card.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    if let note = checkIn.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(String(checkIn.createdAt.prefix(10)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CheckInDetailSheet(
                cardTitle: checkIn.cards?.title,
                cardSymbol: checkIn.cards?.theme.symbolName,
                note: checkIn.note,
                photoUrl: checkIn.photoUrl.flatMap(URL.init),
                date: String(checkIn.createdAt.prefix(10)),
                author: "漫游者"
            )
        }
    }
}

// MARK: - Detail Sheet

struct CheckInDetailSheet: View {
    var cardTitle: String?
    var cardSymbol: String?
    var note: String?
    var photoUrl: URL?
    var date: String
    var author: String? = nil
    @State private var fullscreenURL: URL? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 作者行（社区）
                    if let author {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.secondary)
                            Text(author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(date)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // 卡片标题
                    if let title = cardTitle {
                        HStack(spacing: 8) {
                            if let sym = cardSymbol {
                                Image(systemName: sym)
                                    .foregroundStyle(.secondary)
                            }
                            Text(title)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }

                    // 图片（可点击全屏）
                    if let url = photoUrl {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 260)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .onTapGesture { fullscreenURL = url }
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .font(.caption)
                                            .padding(6)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .padding(10)
                                    }
                            case .failure:
                                EmptyView()
                            default:
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                                    .frame(height: 260)
                                    .overlay(ProgressView())
                            }
                        }
                    }

                    // 备注
                    if let note, !note.isEmpty {
                        Text(note)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    if author == nil {
                        Text(date)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .fullScreenCover(item: $fullscreenURL) { url in
                PhotoFullscreenView(url: url)
            }
        }
    }
}

// MARK: - Fullscreen Photo

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct PhotoFullscreenView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                default:
                    ProgressView().tint(.white)
                }
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
            }
        }
        .onTapGesture { dismiss() }
    }
}
