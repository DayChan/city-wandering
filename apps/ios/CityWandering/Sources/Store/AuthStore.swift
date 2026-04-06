import Foundation
import Supabase

@MainActor
class AuthStore: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false

    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            self.user = session.user
        } catch {
            self.user = nil
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let session = try await supabase.auth.signIn(email: email, password: password)
        self.user = session.user
    }

    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let response = try await supabase.auth.signUp(email: email, password: password)
        self.user = response.user
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        self.user = nil
    }
}
