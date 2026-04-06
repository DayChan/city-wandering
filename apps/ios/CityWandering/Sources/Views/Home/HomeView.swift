import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var card: Card?
    @Published var selectedTheme: Theme = .random
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCitySelector = false

    func draw(city: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            card = try await CardService.shared.getRandom(filters: CardFilters(
                theme: selectedTheme == .random ? nil : selectedTheme,
                city: city
            ))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var locationStore: LocationStore
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 主题选择
                    ThemePickerView(selected: $vm.selectedTheme)

                    // 卡片区域
                    if let card = vm.card {
                        CardFlipView(card: card)
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
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Text(vm.card == nil ? "🎴 抽一张" : "再抽一张")
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
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .navigationTitle("陌生城市漫步卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CityPillButton(store: locationStore) {
                        vm.showCitySelector = true
                    }
                }
            }
            .sheet(isPresented: $vm.showCitySelector) {
                CitySelectorView(store: locationStore)
            }
        }
    }
}
