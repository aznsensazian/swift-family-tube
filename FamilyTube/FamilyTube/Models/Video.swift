import Foundation

struct Video: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var driveFileID: String
    var thumbnailDriveFileID: String?
    var uploaderEmail: String
    var uploaderName: String
    var uploadDate: Date
    var duration: TimeInterval
    var viewCount: Int
    var sharedWith: [String] // email addresses
    var isPublicToFamily: Bool // visible to all family members
    var fileSize: Int64

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedUploadDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: uploadDate, relativeTo: Date())
    }

    var formattedViewCount: String {
        if viewCount >= 1_000_000 {
            return String(format: "%.1fM views", Double(viewCount) / 1_000_000)
        } else if viewCount >= 1_000 {
            return String(format: "%.1fK views", Double(viewCount) / 1_000)
        }
        return "\(viewCount) views"
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

extension Video {
    static let preview = Video(
        id: UUID().uuidString,
        title: "Family Beach Day 2025",
        description: "Great day at the beach with the whole family!",
        driveFileID: "sample_drive_id",
        thumbnailDriveFileID: nil,
        uploaderEmail: "parent@family.com",
        uploaderName: "Mom",
        uploadDate: Date().addingTimeInterval(-86400),
        duration: 325,
        viewCount: 12,
        sharedWith: ["dad@family.com", "grandma@family.com"],
        isPublicToFamily: true,
        fileSize: 52_428_800
    )
}
