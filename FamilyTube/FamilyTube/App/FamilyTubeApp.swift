import SwiftUI

@main
struct FamilyTubeApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var videoViewModel = VideoViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isSignedIn {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(videoViewModel)
            } else {
                SignInView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
