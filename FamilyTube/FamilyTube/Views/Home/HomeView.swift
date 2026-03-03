import SwiftUI

struct HomeView: View {
    @EnvironmentObject var videoViewModel: VideoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category chips
                    CategoryChipsView(selectedCategory: $videoViewModel.selectedCategory)
                        .onChange(of: videoViewModel.selectedCategory) { _, _ in
                            videoViewModel.applyFilters()
                        }

                    if videoViewModel.isLoading {
                        Spacer()
                        ProgressView("Loading videos...")
                            .tint(.white)
                            .foregroundColor(.gray)
                        Spacer()
                    } else if videoViewModel.filteredVideos.isEmpty {
                        EmptyStateView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(videoViewModel.filteredVideos) { video in
                                    NavigationLink(destination: VideoPlayerView(video: video)) {
                                        VideoCardView(video: video)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 100) // Space for tab bar
                        }
                        .refreshable {
                            videoViewModel.fetchVideos()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 28, height: 20)

                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }

                        Text("Family Tube")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showSearch.toggle() }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
                    .environmentObject(videoViewModel)
            }
        }
    }
}

// MARK: - Category Chips

struct CategoryChipsView: View {
    @Binding var selectedCategory: VideoViewModel.VideoCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VideoViewModel.VideoCategory.allCases, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        Text(category.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category
                                    ? Color.white
                                    : Color(white: 0.2)
                            )
                            .foregroundColor(
                                selectedCategory == category
                                    ? .black
                                    : .white
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.black)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        Spacer()
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Videos Yet")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("Tap the + button to upload\nyour first family video!")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        Spacer()
    }
}

#Preview {
    HomeView()
        .environmentObject(VideoViewModel())
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
