import Foundation
import UIKit
import AVFoundation

/// Service for interacting with Google Drive API to store and retrieve videos.
@MainActor
class GoogleDriveService: ObservableObject {
    private let baseURL = "https://www.googleapis.com/drive/v3"
    private let uploadURL = "https://www.googleapis.com/upload/drive/v3"
    private let authService: GoogleAuthService

    @Published var uploadProgress: Double = 0

    init(authService: GoogleAuthService) {
        self.authService = authService
    }

    // MARK: - Folder Management

    /// Find or create the FamilyTube folder in Google Drive
    func getOrCreateFolder(name: String) async throws -> String {
        // Search for existing folder
        let query = "name='\(name)' and mimeType='application/vnd.google-apps.folder' and trashed=false"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let searchURL = "\(baseURL)/files?q=\(encodedQuery)&fields=files(id,name)"

        let data = try await authorizedRequest(url: searchURL)
        let result = try JSONDecoder().decode(DriveFileList.self, from: data)

        if let existingFolder = result.files.first {
            return existingFolder.id
        }

        // Create new folder
        let createURL = "\(baseURL)/files"
        let metadata: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]

        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        let responseData = try await authorizedRequest(
            url: createURL,
            method: "POST",
            body: metadataData,
            contentType: "application/json"
        )

        let folder = try JSONDecoder().decode(DriveFile.self, from: responseData)
        return folder.id
    }

    // MARK: - Video Upload

    /// Upload a video file to Google Drive with progress tracking
    func uploadVideo(
        fileURL: URL,
        title: String,
        onProgress: @escaping (Double) -> Void
    ) async throws -> String {
        let folderID = try await getOrCreateFolder(name: AppConstants.Google.driveFolderName)

        guard let accessToken = authService.accessToken else {
            throw DriveError.notAuthenticated
        }

        // Initiate resumable upload
        let initiateURL = "\(uploadURL)/files?uploadType=resumable"
        let metadata: [String: Any] = [
            "name": "\(title)_\(UUID().uuidString).mp4",
            "parents": [folderID],
            "mimeType": "video/mp4"
        ]

        let metadataData = try JSONSerialization.data(withJSONObject: metadata)

        var initiateRequest = URLRequest(url: URL(string: initiateURL)!)
        initiateRequest.httpMethod = "POST"
        initiateRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        initiateRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")

        let fileData = try Data(contentsOf: fileURL)
        initiateRequest.setValue("\(fileData.count)", forHTTPHeaderField: "X-Upload-Content-Length")
        initiateRequest.setValue("video/mp4", forHTTPHeaderField: "X-Upload-Content-Type")
        initiateRequest.httpBody = metadataData

        let (_, initiateResponse) = try await URLSession.shared.data(for: initiateRequest)

        guard let httpResponse = initiateResponse as? HTTPURLResponse,
              let uploadSessionURL = httpResponse.value(forHTTPHeaderField: "Location") else {
            throw DriveError.uploadInitFailed
        }

        // Upload file data in chunks
        let chunkSize = 5 * 1024 * 1024 // 5MB chunks
        var offset = 0

        while offset < fileData.count {
            let end = min(offset + chunkSize, fileData.count)
            let chunk = fileData[offset..<end]

            var chunkRequest = URLRequest(url: URL(string: uploadSessionURL)!)
            chunkRequest.httpMethod = "PUT"
            chunkRequest.setValue(
                "bytes \(offset)-\(end - 1)/\(fileData.count)",
                forHTTPHeaderField: "Content-Range"
            )
            chunkRequest.setValue("\(chunk.count)", forHTTPHeaderField: "Content-Length")
            chunkRequest.httpBody = chunk

            let (responseData, chunkResponse) = try await URLSession.shared.data(for: chunkRequest)

            if let httpChunkResponse = chunkResponse as? HTTPURLResponse {
                if httpChunkResponse.statusCode == 200 || httpChunkResponse.statusCode == 201 {
                    // Upload complete
                    let file = try JSONDecoder().decode(DriveFile.self, from: responseData)
                    onProgress(1.0)
                    return file.id
                } else if httpChunkResponse.statusCode == 308 {
                    // Resume incomplete — continue uploading
                    offset = end
                    let progress = Double(offset) / Double(fileData.count)
                    onProgress(progress)
                } else {
                    throw DriveError.uploadFailed
                }
            }
        }

        throw DriveError.uploadFailed
    }

    // MARK: - Thumbnail Upload

    /// Upload a thumbnail image to Google Drive
    func uploadThumbnail(image: UIImage, videoTitle: String) async throws -> String {
        let folderID = try await getOrCreateFolder(name: AppConstants.Google.driveFolderName)

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw DriveError.thumbnailGenerationFailed
        }

        guard let accessToken = authService.accessToken else {
            throw DriveError.notAuthenticated
        }

        // Use multipart upload for smaller files
        let boundary = UUID().uuidString
        let url = "\(uploadURL)/files?uploadType=multipart"

        let metadata: [String: Any] = [
            "name": "\(videoTitle)_thumb_\(UUID().uuidString).jpg",
            "parents": [folderID],
            "mimeType": "image/jpeg"
        ]

        let metadataData = try JSONSerialization.data(withJSONObject: metadata)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataData)
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let file = try JSONDecoder().decode(DriveFile.self, from: data)
        return file.id
    }

    // MARK: - Metadata Storage

    /// Save video metadata as a JSON file in Google Drive
    func saveVideoMetadata(_ metadata: VideoMetadata) async throws -> String {
        let folderID = try await getOrCreateFolder(name: AppConstants.Google.metadataFolderName)

        guard let accessToken = authService.accessToken else {
            throw DriveError.notAuthenticated
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(metadata)

        let boundary = UUID().uuidString
        let url = "\(uploadURL)/files?uploadType=multipart"

        let fileMetadata: [String: Any] = [
            "name": "video_\(metadata.videoID).json",
            "parents": [folderID],
            "mimeType": "application/json"
        ]

        let fileMetadataData = try JSONSerialization.data(withJSONObject: fileMetadata)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(fileMetadataData)
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(jsonData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let file = try JSONDecoder().decode(DriveFile.self, from: data)
        return file.id
    }

    /// Update existing video metadata in Google Drive
    func updateVideoMetadata(_ metadata: VideoMetadata, metadataFileID: String) async throws {
        guard let accessToken = authService.accessToken else {
            throw DriveError.notAuthenticated
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(metadata)

        let url = "\(uploadURL)/files/\(metadataFileID)?uploadType=media"

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DriveError.metadataUpdateFailed
        }
    }

    /// Fetch all video metadata files from the metadata folder
    func fetchAllVideoMetadata() async throws -> [VideoMetadata] {
        let folderID = try await getOrCreateFolder(name: AppConstants.Google.metadataFolderName)

        let query = "'\(folderID)' in parents and mimeType='application/json' and trashed=false"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let searchURL = "\(baseURL)/files?q=\(encodedQuery)&fields=files(id,name)"

        let data = try await authorizedRequest(url: searchURL)
        let result = try JSONDecoder().decode(DriveFileList.self, from: data)

        var metadataList: [VideoMetadata] = []

        for file in result.files {
            if let metadata = try? await fetchFileContent(fileID: file.id) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let videoMetadata = try? decoder.decode(VideoMetadata.self, from: metadata) {
                    metadataList.append(videoMetadata)
                }
            }
        }

        return metadataList
    }

    // MARK: - File Operations

    /// Download file content from Google Drive
    func fetchFileContent(fileID: String) async throws -> Data {
        let url = "\(baseURL)/files/\(fileID)?alt=media"
        return try await authorizedRequest(url: url)
    }

    /// Get an AVURLAsset configured for authenticated video streaming
    func getVideoAsset(fileID: String) -> AVURLAsset? {
        guard let accessToken = authService.accessToken else { return nil }
        let urlString = "\(baseURL)/files/\(fileID)?alt=media"
        guard let url = URL(string: urlString) else { return nil }
        let headers = ["Authorization": "Bearer \(accessToken)"]
        return AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
    }

    /// Share a file with a specific email address (Google Drive sharing)
    func shareFile(fileID: String, email: String, role: String = "reader") async throws {
        guard let accessToken = authService.accessToken else {
            throw DriveError.notAuthenticated
        }

        let url = "\(baseURL)/files/\(fileID)/permissions"
        let permission: [String: Any] = [
            "type": "user",
            "role": role,
            "emailAddress": email
        ]

        let body = try JSONSerialization.data(withJSONObject: permission)

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DriveError.sharingFailed
        }
    }

    /// Delete a file from Google Drive
    func deleteFile(fileID: String) async throws {
        guard let accessToken = authService.accessToken else {
            throw DriveError.notAuthenticated
        }

        let url = "\(baseURL)/files/\(fileID)"

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DriveError.deleteFailed
        }
    }

    // MARK: - Helpers

    private func authorizedRequest(
        url: String,
        method: String = "GET",
        body: Data? = nil,
        contentType: String? = nil
    ) async throws -> Data {
        guard let accessToken = authService.accessToken else {
            throw DriveError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            // Token expired — try refresh
            try await authService.refreshAccessToken()
            return try await authorizedRequest(url: url, method: method, body: body, contentType: contentType)
        }

        return data
    }
}

// MARK: - Drive API Models

struct DriveFile: Codable {
    let id: String
    let name: String?
    let mimeType: String?

    enum CodingKeys: String, CodingKey {
        case id, name, mimeType
    }
}

struct DriveFileList: Codable {
    let files: [DriveFile]
}

// MARK: - Errors

enum DriveError: LocalizedError {
    case notAuthenticated
    case uploadInitFailed
    case uploadFailed
    case thumbnailGenerationFailed
    case metadataUpdateFailed
    case sharingFailed
    case deleteFailed
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated with Google Drive"
        case .uploadInitFailed: return "Failed to initiate upload"
        case .uploadFailed: return "Video upload failed"
        case .thumbnailGenerationFailed: return "Failed to generate thumbnail"
        case .metadataUpdateFailed: return "Failed to update video metadata"
        case .sharingFailed: return "Failed to share video"
        case .deleteFailed: return "Failed to delete file"
        case .fileNotFound: return "File not found"
        }
    }
}
