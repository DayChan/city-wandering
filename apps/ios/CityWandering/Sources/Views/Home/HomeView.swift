import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var card: Card?
    @Published var selectedTheme: Theme = .random
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCitySelector = false
    @Published var showCheckIn = false
    @Published var showShare = false

    // 动画状态
    @Published var cardOffset: CGFloat = 600
    @Published var cardScale: CGFloat = 0.85
    @Published var cardOpacity: Double = 0

    func draw(city: String?) async {
        isLoading = true
        errorMessage = nil
        // 先把旧卡片退出
        if card != nil {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                cardOffset = -600
                cardScale = 0.9
                cardOpacity = 0
            }
            try? await Task.sleep(nanoseconds: 280_000_000)
        }
        defer { isLoading = false }
        do {
            card = try await CardService.shared.getRandom(filters: CardFilters(
                theme: selectedTheme == .random ? nil : selectedTheme,
                city: city
            ))
            // 新卡片从下方飞入
            cardOffset = 600
            cardScale = 0.85
            cardOpacity = 0
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                cardOffset = 0
                cardScale = 1.0
                cardOpacity = 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct HomeView: View {
    @Binding var showProfile: Bool
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var locationStore: LocationStore
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // 主题选择器
                    ThemePickerView(selected: $vm.selectedTheme)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    // 卡片区域 — 充满剩余空间
                    ZStack {
                        if let card = vm.card {
                            CardFlipView(card: card)
                                .padding(.horizontal, 20)
                                .offset(y: vm.cardOffset)
                                .scaleEffect(vm.cardScale)
                                .opacity(vm.cardOpacity)
                        } else {
                            CardPlaceholderView()
                                .padding(.horizontal, 20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geo.size.height - 248)
                    .clipped()

                    Spacer(minLength: 0)

                    // 底部操作区
                    VStack(spacing: 10) {
                        // 打卡 + 分享（仅抽到卡后显示）
                        if vm.card != nil {
                            HStack(spacing: 10) {
                                Button {
                                    if authStore.user != nil { vm.showCheckIn = true }
                                } label: {
                                    Label("打卡", systemImage: "mappin.circle.fill")
                                        .font(.subheadline).fontWeight(.medium)
                                        .frame(maxWidth: .infinity).frame(height: 46)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .foregroundStyle(authStore.user != nil ? .primary : .secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                Button { vm.showShare = true } label: {
                                    Label("分享", systemImage: "square.and.arrow.up")
                                        .font(.subheadline).fontWeight(.medium)
                                        .frame(maxWidth: .infinity).frame(height: 46)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .foregroundStyle(.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // 抽卡按钮
                        Button {
                            Task { await vm.draw(city: locationStore.city?.slug) }
                        } label: {
                            ZStack {
                                if vm.isLoading {
                                    HStack(spacing: 8) {
                                        ProgressView().tint(.white).scaleEffect(0.85)
                                        Text("抽取中…").fontWeight(.semibold)
                                    }
                                } else {
                                    Label(vm.card == nil ? "抽一张" : "再抽一张",
                                          systemImage: "rectangle.on.rectangle.angled")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.primary)
                            .foregroundStyle(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 17))
                        }
                        .disabled(vm.isLoading)
                        .padding(.horizontal, 20)
                        .scaleEffect(vm.isLoading ? 0.97 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: vm.isLoading)

                        if let error = vm.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? 8 : 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.card != nil)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CityPillButton(store: locationStore) {
                        vm.showCitySelector = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: authStore.user != nil
                              ? "person.crop.circle.fill"
                              : "person.crop.circle")
                            .foregroundStyle(authStore.user != nil ? .primary : .secondary)
                    }
                }
            }
            .sheet(isPresented: $vm.showCitySelector) {
                CitySelectorView(store: locationStore)
            }
            .sheet(isPresented: $vm.showCheckIn) {
                if let card = vm.card, let userId = authStore.user?.id.uuidString {
                    CheckInSheet(card: card, userId: userId)
                }
            }
            .sheet(isPresented: $vm.showShare) {
                if let card = vm.card {
                    CardShareSheet(card: card)
                }
            }
        }
    }
}
