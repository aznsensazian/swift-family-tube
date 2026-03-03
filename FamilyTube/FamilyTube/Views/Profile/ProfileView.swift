import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var videoViewModel: VideoViewModel
    @State private var showFamilyManager = false
    @State private var showSignOutConfirmation = false

    private var myVideos: [Video] {
        let currentEmail = authViewModel.authService.userEmail ?? ""
        return videoViewModel.videos.filter { $0.uploaderEmail == currentEmail }
    }

    private var totalViews: Int {
        myVideos.reduce(0) { $0 + $1.viewCount }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)

                                Text(authViewModel.currentUser?.initials ?? "?")
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                            }

                            Text(authViewModel.currentUser?.displayName ?? "User")
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)

                        // Stats
                        HStack(spacing: 40) {
                            StatView(value: "\(myVideos.count)", label: "Videos")
                            StatView(value: "\(totalViews)", label: "Views")
                            StatView(
                                value: "\(authViewModel.currentUser?.familyMembers.count ?? 0)",
                                label: "Family"
                            )
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Menu items
                        VStack(spacing: 2) {
                            ProfileMenuItem(
                                icon: "person.3.fill",
                                title: "Manage Family Members",
                                subtitle: "\(authViewModel.currentUser?.familyMembers.count ?? 0) members"
                            ) {
                                showFamilyManager = true
                            }

                            ProfileMenuItem(
                                icon: "video.fill",
                                title: "My Videos",
                                subtitle: "\(myVideos.count) videos uploaded"
                            ) {
                                // Navigate to my videos
                                videoViewModel.selectedCategory = .myUploads
                                videoViewModel.applyFilters()
                            }

                            ProfileMenuItem(
                                icon: "square.and.arrow.down",
                                title: "Shared with Me",
                                subtitle: "Videos from family"
                            ) {
                                videoViewModel.selectedCategory = .sharedWithMe
                                videoViewModel.applyFilters()
                            }

                            ProfileMenuItem(
                                icon: "icloud.fill",
                                title: "Storage",
                                subtitle: "Videos stored on Google Drive"
                            ) {}

                            ProfileMenuItem(
                                icon: "gearshape.fill",
                                title: "Settings",
                                subtitle: "App preferences"
                            ) {}
                        }
                        .padding(.horizontal)

                        // Sign out
                        Button(action: { showSignOutConfirmation = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)

                        // App version
                        Text("Family Tube v1.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFamilyManager) {
                FamilyManagerView()
                    .environmentObject(authViewModel)
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Stat View

struct StatView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Profile Menu Item

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.red)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(white: 0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(VideoViewModel())
        .preferredColorScheme(.dark)
}
