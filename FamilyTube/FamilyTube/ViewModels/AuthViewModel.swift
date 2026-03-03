import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    let authService = GoogleAuthService()

    init() {
        if authService.isAuthenticated {
            isSignedIn = true
            loadCurrentUser()
        }
    }

    func signIn() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signIn()
                loadCurrentUser()
                isSignedIn = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signOut() {
        authService.signOut()
        currentUser = nil
        isSignedIn = false
    }

    private func loadCurrentUser() {
        guard let email = authService.userEmail,
              let name = authService.userName else { return }

        currentUser = User(
            id: email,
            email: email,
            displayName: name,
            profileImageURL: authService.userProfileImageURL,
            familyMembers: loadFamilyMembers(),
            joinDate: Date()
        )
    }

    func addFamilyMember(email: String) {
        guard var user = currentUser else { return }
        if !user.familyMembers.contains(email) {
            user.familyMembers.append(email)
            currentUser = user
            saveFamilyMembers(user.familyMembers)
        }
    }

    func removeFamilyMember(email: String) {
        guard var user = currentUser else { return }
        user.familyMembers.removeAll { $0 == email }
        currentUser = user
        saveFamilyMembers(user.familyMembers)
    }

    private func saveFamilyMembers(_ members: [String]) {
        UserDefaults.standard.set(members, forKey: "ft_family_members")
    }

    private func loadFamilyMembers() -> [String] {
        UserDefaults.standard.stringArray(forKey: "ft_family_members") ?? []
    }
}
