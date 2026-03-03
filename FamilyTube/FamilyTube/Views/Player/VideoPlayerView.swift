import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let video: Video
    @EnvironmentObject var videoViewModel: VideoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var player: AVPlayer?
    @State private var showShareSheet = false
    @State private var isDescriptionExpanded = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    private var isOwner: Bool {
        video.uploaderEmail == authViewModel.authService.userEmail
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Video Player
                ZStack {
                    if let player = player {
                        VideoPlayer(player: player)
                            .aspectRatio(16/9, contentMode: .fit)
                    } else {
                        Rectangle()
                            .fill(Color.black)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(video.title)
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    // Stats row
                    HStack(spacing: 4) {
                        Text(video.formattedViewCount)
                        Text("·")
                        Text(video.formattedUploadDate)
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)

                    // Action buttons row (YouTube-style)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ActionButton(icon: "hand.thumbsup", label: "Like")
                            ActionButton(icon: "hand.thumbsdown", label: "Dislike")

                            Button(action: { showShareSheet = true }) {
                                ActionButtonContent(icon: "square.and.arrow.up", label: "Share")
                            }

                            ActionButton(icon: "arrow.down.circle", label: "Download")

                            if isOwner {
                                Button(action: { showDeleteConfirmation = true }) {
                                    ActionButtonContent(icon: "trash", label: "Delete")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    Divider().background(Color.gray.opacity(0.3))

                    // Channel info
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.3))
                                .frame(width: 44, height: 44)

                            Text(String(video.uploaderName.prefix(1)))
                                .font(.title3.bold())
                                .foregroundColor(.red)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(video.uploaderName)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)

                            Text(video.uploaderEmail)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    Divider().background(Color.gray.opacity(0.3))

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(video.description.isEmpty ? "No description" : video.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(isDescriptionExpanded ? nil : 3)

                        if !video.description.isEmpty {
                            Button(isDescriptionExpanded ? "Show less" : "Show more") {
                                withAnimation { isDescriptionExpanded.toggle() }
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)

                    Divider().background(Color.gray.opacity(0.3))

                    // Shared with section
                    if isOwner {
                        SharedWithSection(video: video)
                    }

                    // Video details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.headline)
                            .foregroundColor(.white)

                        DetailRow(label: "File size", value: video.formattedFileSize)
                        DetailRow(label: "Duration", value: video.formattedDuration)
                        DetailRow(label: "Uploaded", value: formattedDate(video.uploadDate))
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupPlayer()
            videoViewModel.incrementViewCount(for: video)
        }
        .onDisappear {
            player?.pause()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareVideoView(video: video)
                .environmentObject(videoViewModel)
                .environmentObject(authViewModel)
        }
        .alert("Delete Video", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                videoViewModel.deleteVideo(video)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this video? This cannot be undone.")
        }
    }

    private func setupPlayer() {
        let driveService = GoogleDriveService(authService: authViewModel.authService)
        if let url = driveService.getVideoStreamURL(fileID: video.driveFileID) {
            player = AVPlayer(url: url)
            player?.play()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String

    var body: some View {
        Button(action: {}) {
            ActionButtonContent(icon: icon, label: label)
        }
    }
}

struct ActionButtonContent: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(.white)
        .frame(width: 70, height: 56)
        .background(Color(white: 0.15))
        .cornerRadius(20)
    }
}

// MARK: - Shared With Section

struct SharedWithSection: View {
    let video: Video

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Shared with")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: video.isPublicToFamily ? "globe" : "lock.fill")
                    .foregroundColor(.gray)

                Text(video.isPublicToFamily ? "All Family" : "Invite Only")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if video.sharedWith.isEmpty {
                Text("Not shared with anyone yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(video.sharedWith, id: \.self) { email in
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(.vertical, 8)

        Divider().background(Color.gray.opacity(0.3))
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationStack {
        VideoPlayerView(video: .preview)
            .environmentObject(VideoViewModel())
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
