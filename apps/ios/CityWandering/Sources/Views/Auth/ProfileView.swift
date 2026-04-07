import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var showAuth = false
    @AppStorage("colorScheme") private var colorSchemeRaw: String = "system"

    var body: some View {
        NavigationStack {
            List {
                // 外观设置
                Section("外观") {
                    Picker(selection: $colorSchemeRaw) {
                        Label("跟随系统", systemImage: "circle.lefthalf.filled").tag("system")
                        Label("浅色模式", systemImage: "sun.max").tag("light")
                        Label("深色模式", systemImage: "moon").tag("dark")
                    } label: {
                        Label("主题", systemImage: "paintbrush")
                    }
                    .pickerStyle(.navigationLink)
                }

                if let user = authStore.user {
                    Section("账号") {
                        LabeledContent("邮箱", value: user.email ?? "—")
                    }
                    Section {
                        Button(role: .destructive) {
                            Task { try? await authStore.signOut() }
                        } label: {
                            Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } else {
                    Section {
                        Button {
                            showAuth = true
                        } label: {
                            Label("登录 / 注册", systemImage: "person.badge.plus")
                        }
                    }
                }
            }
            .navigationTitle("我的")
            .sheet(isPresented: $showAuth) {
                AuthView().environmentObject(authStore)
            }
        }
        .preferredColorScheme(preferredScheme)
    }

    private var preferredScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
