import Foundation
import UIKit
import PhotosUI
import SwiftUI

@MainActor
class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var filteredVideos: [Video] = []
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: VideoCategory = .all

    private var driveService: GoogleDriveService?
    private var authService: GoogleAuthService?

    enum VideoCategory: String, CaseIterable {
        case all = "All"
        case myUploads = "My Uploads"
        case sharedWithMe = "Shared"
        case recent = "Recent"
    }

    func configure(authService: GoogleAuthService) {
        self.authService = authService
        self.driveService = GoogleDriveService(authService: authService)
    }

    // MARK: - Fetch Videos

    func fetchVideos() {
        guard let driveService = driveService else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let metadataList = try await driveService.fetchAllVideoMetadata()
                let currentEmail = authService?.userEmail ?? ""

                // Filter videos: only show videos the user uploaded or was shared with
                videos = metadataList
                    .filter { metadata in
                        metadata.uploaderEmail == currentEmail ||
                        metadata.sharedEmails.contains(currentEmail) ||
                        metadata.isPublicToFamily
                    }
                    .map { $0.toVideo() }
                    .sorted { $0.uploadDate > $1.uploadDate }

                applyFilters()
            } catch {
                errorMessage = "Failed to load videos: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    // MARK: - Upload Video

    func uploadVideo(
        fileURL: URL,
        title: String,
        description: String,
        sharedEmails: [String],
        isPublicToFamily: Bool
    ) {
        guard let driveService = driveService,
              let authService = authService else { return }

        isUploading = true
        uploadProgress = 0
        errorMessage = nil

        Task {
            do {
                // Generate thumbnail
                let thumbnail = await ThumbnailGenerator.generateThumbnail(from: fileURL)
                let duration = await ThumbnailGenerator.getVideoDuration(from: fileURL)
                let fileSize = ThumbnailGenerator.getFileSize(from: fileURL)

                // Upload video file
                let driveFileID = try await driveService.uploadVideo(
                    fileURL: fileURL,
                    title: title
                ) { progress in
                    Task { @MainActor in
                        self.uploadProgress = progress * 0.8 // 80% for video upload
                    }
                }

                // Upload thumbnail
                var thumbnailID: String?
                if let thumbnail = thumbnail {
                    thumbnailID = try? await driveService.uploadThumbnail(
                        image: thumbnail,
                        videoTitle: title
                    )
                    uploadProgress = 0.9

                    // Share thumbnail with same users
                    if let thumbID = thumbnailID {
                        for email in sharedEmails {
                            try? await driveService.shareFile(fileID: thumbID, email: email)
                        }
                    }
                }

                // Share the video file on Google Drive with invited emails
                for email in sharedEmails {
                    try? await driveService.shareFile(fileID: driveFileID, email: email)
                }

                // Create and save metadata
                let videoID = UUID().uuidString
                let metadata = VideoMetadata(
                    videoID: videoID,
                    title: title,
                    description: description,
                    driveFileID: driveFileID,
                    thumbnailDriveFileID: thumbnailID,
                    uploaderEmail: authService.userEmail ?? "",
                    uploaderName: authService.userName ?? "Unknown",
                    uploadDate: Date(),
                    duration: duration,
                    viewCount: 0,
                    sharedEmails: sharedEmails,
                    isPublicToFamily: isPublicToFamily,
                    fileSize: fileSize
                )

                _ = try await driveService.saveVideoMetadata(metadata)
                uploadProgress = 1.0

                // Refresh videos list
                fetchVideos()
                successMessage = "Video uploaded successfully!"
            } catch {
                errorMessage = "Upload failed: \(error.localizedDescription)"
            }
            isUploading = false
        }
    }

    // MARK: - Share Video

    func shareVideo(_ video: Video, withEmail email: String) {
        guard let driveService = driveService else { return }

        Task {
            do {
                // Share the actual video file on Google Drive
                try await driveService.shareFile(fileID: video.driveFileID, email: email)

                // Share thumbnail too
                if let thumbID = video.thumbnailDriveFileID {
                    try? await driveService.shareFile(fileID: thumbID, email: email)
                }

                // Update metadata to include the new email
                var updatedVideo = video
                if !updatedVideo.sharedWith.contains(email) {
                    updatedVideo.sharedWith.append(email)
                }

                // Find and update metadata file
                let allMetadata = try await driveService.fetchAllVideoMetadata()
                if let existingIndex = allMetadata.firstIndex(where: { $0.videoID == video.id }) {
                    var updatedMetadata = allMetadata[existingIndex]
                    if !updatedMetadata.sharedEmails.contains(email) {
                        updatedMetadata.sharedEmails.append(email)
                    }
                    // Save updated metadata
                    _ = try await driveService.saveVideoMetadata(updatedMetadata)
                }

                successMessage = "Video shared with \(email)"
                fetchVideos()
            } catch {
                errorMessage = "Failed to share: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Delete Video

    func deleteVideo(_ video: Video) {
        guard let driveService = driveService else { return }

        Task {
            do {
                try await driveService.deleteFile(fileID: video.driveFileID)
                if let thumbID = video.thumbnailDriveFileID {
                    try? await driveService.deleteFile(fileID: thumbID)
                }
                videos.removeAll { $0.id == video.id }
                applyFilters()
                successMessage = "Video deleted"
            } catch {
                errorMessage = "Failed to delete: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Increment View

    func incrementViewCount(for video: Video) {
        guard let driveService = driveService else { return }

        Task {
            do {
                let allMetadata = try await driveService.fetchAllVideoMetadata()
                if let existing = allMetadata.first(where: { $0.videoID == video.id }) {
                    var updated = existing
                    updated.viewCount += 1
                    _ = try await driveService.saveVideoMetadata(updated)

                    if let index = videos.firstIndex(where: { $0.id == video.id }) {
                        videos[index] = updated.toVideo()
                        applyFilters()
                    }
                }
            } catch {
                // Silently fail for view count
            }
        }
    }

    // MARK: - Filtering

    func applyFilters() {
        let currentEmail = authService?.userEmail ?? ""

        var result = videos

        // Apply category filter
        switch selectedCategory {
        case .all:
            break
        case .myUploads:
            result = result.filter { $0.uploaderEmail == currentEmail }
        case .sharedWithMe:
            result = result.filter { $0.uploaderEmail != currentEmail }
        case .recent:
            let oneWeekAgo = Date().addingTimeInterval(-7 * 86400)
            result = result.filter { $0.uploadDate > oneWeekAgo }
        }

        // Apply search
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.uploaderName.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredVideos = result
    }
}
