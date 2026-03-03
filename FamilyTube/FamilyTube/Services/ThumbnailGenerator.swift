import AVFoundation
import UIKit

/// Generates thumbnail images from video files.
enum ThumbnailGenerator {

    /// Generate a thumbnail from a video URL at a specific time
    static func generateThumbnail(from videoURL: URL, at time: CMTime = CMTime(seconds: 1, preferredTimescale: 600)) async -> UIImage? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = AppConstants.Video.thumbnailSize

        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Thumbnail generation failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Get video duration from a URL
    static func getVideoDuration(from url: URL) async -> TimeInterval {
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            return 0
        }
    }

    /// Get video file size
    static func getFileSize(from url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}
