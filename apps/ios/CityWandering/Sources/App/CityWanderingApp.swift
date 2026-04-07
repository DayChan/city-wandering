import SwiftUI

@main
struct CityWanderingApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var locationStore = LocationStore()

    var body: some Scene {
        WindowGroup {
            let _ = ImageCache.shared  // 启动时初始化 URLCache
            RootView()
                .environmentObject(authStore)
                .environmentObject(locationStore)
                .task {
                    await authStore.restoreSession()
                    // 模拟器无真实 IP，跳过静默检测；真机会正常走 IP 推断
                    #if !targetEnvironment(simulator)
                    await locationStore.detectFromIP()
                    #endif
                }
        }
    }
}
