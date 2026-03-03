import Foundation

/// Metadata stored as a JSON file in Google Drive alongside each video.
/// This allows the app to track sharing permissions, view counts, etc.
struct VideoMetadata: Codable {
    var videoID: String
    var title: String
    var description: String
    var driveFileID: String
    var thumbnailDriveFileID: String?
    var uploaderEmail: String
    var uploaderName: String
    var uploadDate: Date
    var duration: TimeInterval
    var viewCount: Int
    var sharedEmails: [String]
    var isPublicToFamily: Bool
    var fileSize: Int64

    func toVideo() -> Video {
        Video(
            id: videoID,
            title: title,
            description: description,
            driveFileID: driveFileID,
            thumbnailDriveFileID: thumbnailDriveFileID,
            uploaderEmail: uploaderEmail,
            uploaderName: uploaderName,
            uploadDate: uploadDate,
            duration: duration,
            viewCount: viewCount,
            sharedWith: sharedEmails,
            isPublicToFamily: isPublicToFamily,
            fileSize: fileSize
        )
    }

    static func from(video: Video) -> VideoMetadata {
        VideoMetadata(
            videoID: video.id,
            title: video.title,
            description: video.description,
            driveFileID: video.driveFileID,
            thumbnailDriveFileID: video.thumbnailDriveFileID,
            uploaderEmail: video.uploaderEmail,
            uploaderName: video.uploaderName,
            uploadDate: video.uploadDate,
            duration: video.duration,
            viewCount: video.viewCount,
            sharedEmails: video.sharedWith,
            isPublicToFamily: video.isPublicToFamily,
            fileSize: video.fileSize
        )
    }
}
