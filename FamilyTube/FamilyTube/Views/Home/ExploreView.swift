import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var videoViewModel: VideoViewModel

    var recentVideos: [Video] {
        Array(videoViewModel.videos
            .sorted { $0.uploadDate > $1.uploadDate }
            .prefix(10))
    }

    var mostViewedVideos: [Video] {
        Array(videoViewModel.videos
            .sorted { $0.viewCount > $1.viewCount }
            .prefix(10))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if videoViewModel.videos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "safari")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Nothing to explore yet")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text("Upload some videos to get started!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Recently Added
                            if !recentVideos.isEmpty {
                                SectionHeader(title: "Recently Added", icon: "clock.fill")

                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 12) {
                                        ForEach(recentVideos) { video in
                                            NavigationLink(destination: VideoPlayerView(video: video)) {
                                                ExploreVideoCard(video: video)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // Most Viewed
                            if !mostViewedVideos.isEmpty {
                                SectionHeader(title: "Most Viewed", icon: "eye.fill")

                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 12) {
                                        ForEach(mostViewedVideos) { video in
                                            NavigationLink(destination: VideoPlayerView(video: video)) {
                                                ExploreVideoCard(video: video)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // All Videos
                            SectionHeader(title: "All Videos", icon: "play.rectangle.fill")

                            LazyVStack(spacing: 12) {
                                ForEach(videoViewModel.videos) { video in
                                    NavigationLink(destination: VideoPlayerView(video: video)) {
                                        CompactVideoCardView(video: video)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.red)
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
}

// MARK: - Explore Video Card

struct ExploreVideoCard: View {
    let video: Video

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color(white: 0.15))
                    .frame(width: 200, height: 112)
                    .cornerRadius(10)
                    .overlay(
                        Image(systemName: "video.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )

                Text(video.formattedDuration)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(3)
                    .padding(6)
            }

            Text(video.title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 200, alignment: .leading)

            Text("\(video.uploaderName) · \(video.formattedViewCount)")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 200, alignment: .leading)
        }
    }
}

#Preview {
    ExploreView()
        .environmentObject(VideoViewModel())
        .preferredColorScheme(.dark)
}
