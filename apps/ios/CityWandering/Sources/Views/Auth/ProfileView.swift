import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var showAuth = false

    var body: some View {
        NavigationStack {
            List {
                if let user = authStore.user {
                    Section {
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
                AuthView()
                    .environmentObject(authStore)
            }
        }
    }
}
