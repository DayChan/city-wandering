import SwiftUI

struct RootView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var showProfile = false
    @AppStorage("colorScheme") private var colorSchemeRaw: String = "system"

    var body: some View {
        ZStack {
            // 流动彩色背景（最底层）
            FlowingBackground()

            TabView {
                HomeView(showProfile: $showProfile)
                    .tabItem {
                        Label("漫步", systemImage: "map")
                    }

                LogView()
                    .tabItem {
                        Label("漫志", systemImage: "figure.walk.motion")
                    }
            }
            .tint(.primary)
            .scrollContentBackground(.hidden)
        }
        .preferredColorScheme(colorSchemeRaw == "light" ? .light : colorSchemeRaw == "dark" ? .dark : nil)
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(authStore)
        }
    }
}
