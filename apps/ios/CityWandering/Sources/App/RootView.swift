import SwiftUI

struct RootView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var showProfile = false

    var body: some View {
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
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(authStore)
        }
    }
}
