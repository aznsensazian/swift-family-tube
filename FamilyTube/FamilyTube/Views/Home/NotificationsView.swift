import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var videoViewModel: VideoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    private var recentSharedVideos: [Video] {
        let currentEmail = authViewModel.authService.userEmail ?? ""
        return videoViewModel.videos
            .filter { $0.sharedWith.contains(currentEmail) && $0.uploaderEmail != currentEmail }
            .sorted { $0.uploadDate > $1.uploadDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if recentSharedVideos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Notifications")
                            .font(.title3.bold())
                            .foregroundColor(.white)

                        Text("When family members share\nvideos with you, they'll appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(recentSharedVideos) { video in
                                NavigationLink(destination: VideoPlayerView(video: video)) {
                                    NotificationRow(video: video)
                                }
                                .buttonStyle(.plain)

                                Divider().background(Color.gray.opacity(0.2))
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct NotificationRow: View {
    let video: Video

    var body: some View {
        HStack(spacing: 12) {
            // Uploader avatar
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 48, height: 48)

                Text(String(video.uploaderName.prefix(1)))
                    .font(.title3.bold())
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(video.uploaderName) shared a video with you")
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(video.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text(video.formattedUploadDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Thumbnail
            Rectangle()
                .fill(Color(white: 0.15))
                .frame(width: 80, height: 45)
                .cornerRadius(6)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                )
        }
        .padding()
    }
}

#Preview {
    NotificationsView()
        .environmentObject(VideoViewModel())
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
