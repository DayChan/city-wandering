import SwiftUI

struct RootView: View {
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("漫步", systemImage: "map")
                }

            LogView()
                .tabItem {
                    Label("日志", systemImage: "list.bullet.clipboard")
                }

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.circle")
                }
        }
        .tint(.primary)
    }
}
