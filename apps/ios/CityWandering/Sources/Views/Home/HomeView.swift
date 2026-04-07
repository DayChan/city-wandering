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

    func draw(city: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        print("[Draw] 开始抽卡 theme=\(selectedTheme.rawValue) city=\(city ?? "nil")")
        do {
            card = try await CardService.shared.getRandom(filters: CardFilters(
                theme: selectedTheme == .random ? nil : selectedTheme,
                city: city
            ))
            print("[Draw] 成功: \(card?.title ?? "nil")")
        } catch {
            print("[Draw] 失败: \(error)")
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
            ScrollView {
                VStack(spacing: 20) {
                    ThemePickerView(selected: $vm.selectedTheme)

                    if let card = vm.card {
                        CardFlipView(card: card)
                            .padding(.horizontal)

                        // 操作按钮行
                        HStack(spacing: 12) {
                            // 打卡
                            Button {
                                if authStore.user != nil {
                                    vm.showCheckIn = true
                                }
                            } label: {
                                Label("打卡", systemImage: "mappin.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(authStore.user != nil
                                        ? Color(uiColor: .secondarySystemBackground)
                                        : Color(uiColor: .tertiarySystemBackground))
                                    .foregroundStyle(authStore.user != nil ? .primary : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            // 分享
                            Button {
                                vm.showShare = true
                            } label: {
                                Label("分享", systemImage: "square.and.arrow.up")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .foregroundStyle(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        CardPlaceholderView()
                            .padding(.horizontal)
                    }

                    // 抽卡按钮
                    Button {
                        Task { await vm.draw(city: locationStore.city?.slug) }
                    } label: {
                        HStack(spacing: 8) {
                            if vm.isLoading {
                                ProgressView().tint(.white).scaleEffect(0.8)
                            } else {
                                Label(vm.card == nil ? "抽一张" : "再抽一张",
                                      systemImage: "rectangle.on.rectangle.angled")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    .disabled(vm.isLoading)

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    if authStore.user == nil, vm.card != nil {
                        Text("登录后可以打卡记录漫步")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle("漫步卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CityPillButton(store: locationStore) {
                        vm.showCitySelector = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: authStore.user != nil ? "person.crop.circle.fill" : "person.crop.circle")
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
