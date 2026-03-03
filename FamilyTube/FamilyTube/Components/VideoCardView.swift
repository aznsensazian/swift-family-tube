import SwiftUI

/// YouTube-style video card for the home feed
struct VideoCardView: View {
    let video: Video
    @State private var thumbnailImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                if let thumbnail = thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color(white: 0.15))
                        .aspectRatio(16/9, contentMode: .fill)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: "video.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }

                // Duration badge
                Text(video.formattedDuration)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(8)
            }

            // Video info row
            HStack(alignment: .top, spacing: 12) {
                // Channel avatar
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 40, height: 40)

                    Text(String(video.uploaderName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
                        Text(video.uploaderName)
                        Text("·")
                        Text(video.formattedViewCount)
                        Text("·")
                        Text(video.formattedUploadDate)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }

                Spacer()

                // More options
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(90))
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Compact Video Card (for search results, related videos)

struct CompactVideoCardView: View {
    let video: Video

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color(white: 0.15))
                    .frame(width: 160, height: 90)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "video.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    )

                Text(video.formattedDuration)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(3)
                    .padding(4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(video.uploaderName)
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 4) {
                    Text(video.formattedViewCount)
                    Text("·")
                    Text(video.formattedUploadDate)
                }
                .font(.caption)
                .foregroundColor(.gray)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    VStack {
        VideoCardView(video: .preview)
        CompactVideoCardView(video: .preview)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
