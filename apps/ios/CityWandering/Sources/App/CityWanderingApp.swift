import SwiftUI

@main
struct CityWanderingApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var locationStore = LocationStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authStore)
                .environmentObject(locationStore)
                .task {
                    await authStore.restoreSession()
                    await locationStore.detectFromIP()
                }
        }
    }
}
