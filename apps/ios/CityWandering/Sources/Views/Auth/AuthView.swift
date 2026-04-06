import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var isSignIn = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var signUpSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Tab 切换
                Picker("", selection: $isSignIn) {
                    Text("登录").tag(true)
                    Text("注册").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                VStack(spacing: 14) {
                    TextField("邮箱", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)

                    SecureField("密码（至少 8 位）", text: $password)
                        .textFieldStyle(.roundedBorder)

                    if !isSignIn {
                        SecureField("确认密码", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                if signUpSuccess {
                    Text("注册成功！请检查邮箱并点击确认链接")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if authStore.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSignIn ? "登录" : "注册")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.primary)
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                }
                .disabled(authStore.isLoading)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle(isSignIn ? "登录" : "注册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func submit() async {
        errorMessage = nil
        guard password.count >= 8 else {
            errorMessage = "密码至少 8 位"
            return
        }
        if !isSignIn && password != confirmPassword {
            errorMessage = "两次密码不一致"
            return
        }
        do {
            if isSignIn {
                try await authStore.signIn(email: email, password: password)
                dismiss()
            } else {
                try await authStore.signUp(email: email, password: password)
                signUpSuccess = true
            }
        } catch {
            errorMessage = localizedAuthError(error.localizedDescription)
        }
    }

    private func localizedAuthError(_ message: String) -> String {
        if message.contains("Invalid login credentials") { return "邮箱或密码错误" }
        if message.contains("Email not confirmed") { return "请先验证邮箱" }
        if message.contains("User already registered") { return "该邮箱已注册，请直接登录" }
        if message.contains("Password should be") { return "密码太简单，请使用更复杂的密码" }
        return message
    }
}
