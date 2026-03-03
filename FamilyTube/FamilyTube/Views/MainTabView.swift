import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var videoViewModel: VideoViewModel
    @State private var selectedTab = 0
    @State private var showUploadSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                ExploreView()
                    .tag(1)

                // Placeholder for upload button
                Color.clear
                    .tag(2)

                NotificationsView()
                    .tag(3)

                ProfileView()
                    .tag(4)
            }
            .onAppear {
                configureViewModel()
            }

            // Custom tab bar
            CustomTabBar(
                selectedTab: $selectedTab,
                showUploadSheet: $showUploadSheet
            )
        }
        .sheet(isPresented: $showUploadSheet) {
            UploadView()
                .environmentObject(videoViewModel)
                .environmentObject(authViewModel)
        }
        .preferredColorScheme(.dark)
    }

    private func configureViewModel() {
        videoViewModel.configure(authService: authViewModel.authService)
        videoViewModel.fetchVideos()
    }
}

// MARK: - Custom Tab Bar (YouTube-style)

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showUploadSheet: Bool

    var body: some View {
        HStack {
            TabBarButton(icon: "house.fill", label: "Home", isSelected: selectedTab == 0) {
                selectedTab = 0
            }

            TabBarButton(icon: "safari.fill", label: "Explore", isSelected: selectedTab == 1) {
                selectedTab = 1
            }

            // Upload button (center, prominent)
            Button(action: { showUploadSheet = true }) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 48, height: 48)

                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
            }
            .offset(y: -8)

            TabBarButton(icon: "bell.fill", label: "Inbox", isSelected: selectedTab == 3) {
                selectedTab = 3
            }

            TabBarButton(icon: "person.fill", label: "You", isSelected: selectedTab == 4) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.3), radius: 8, y: -4)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(VideoViewModel())
}
