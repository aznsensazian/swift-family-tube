import Foundation

struct ShareInvite: Identifiable, Codable {
    let id: String
    var videoID: String
    var videoTitle: String
    var senderEmail: String
    var senderName: String
    var recipientEmail: String
    var sentDate: Date
    var status: InviteStatus

    enum InviteStatus: String, Codable {
        case pending
        case accepted
        case declined
    }
}

extension ShareInvite {
    static let preview = ShareInvite(
        id: UUID().uuidString,
        videoID: "video_123",
        videoTitle: "Birthday Party",
        senderEmail: "parent@family.com",
        senderName: "Mom",
        recipientEmail: "grandma@family.com",
        sentDate: Date(),
        status: .pending
    )
}
