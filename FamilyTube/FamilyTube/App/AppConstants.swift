import Foundation

enum AppConstants {
    static let appName = "Family Tube"

    // MARK: - Google API Configuration
    // Replace these with your actual Google Cloud Console credentials
    enum Google {
        static let clientID = "933979668006-imna0foiqmp6om4bgoqcj57bt3goaf2b.apps.googleusercontent.com"
        static let apiKey = "AIzaSyAlKMm6ZaFEBPRnvB1Ysm_F0_9-jmUy2ig"
        static let driveScope = "https://www.googleapis.com/auth/drive.file"
        static let driveReadScope = "https://www.googleapis.com/auth/drive.readonly"
        static let emailScope = "https://www.googleapis.com/auth/userinfo.email"
        static let profileScope = "https://www.googleapis.com/auth/userinfo.profile"

        // Folder name in Google Drive where videos are stored
        static let driveFolderName = "FamilyTube Videos"
        static let metadataFolderName = "FamilyTube Metadata"
    }

    // MARK: - Video Settings
    enum Video {
        static let maxUploadSizeMB: Int = 500
        static let thumbnailSize: CGSize = CGSize(width: 320, height: 180)
        static let supportedFormats = ["mp4", "mov", "m4v"]
    }

    // MARK: - UI
    enum UI {
        static let primaryRed = "YouTubeRed"
        static let cornerRadius: CGFloat = 12
        static let thumbnailAspectRatio: CGFloat = 16 / 9
        static let gridSpacing: CGFloat = 12
    }
}
