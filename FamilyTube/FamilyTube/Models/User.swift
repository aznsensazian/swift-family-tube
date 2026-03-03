import Foundation

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var displayName: String
    var profileImageURL: String?
    var familyMembers: [String] // email addresses of family members
    var joinDate: Date

    var initials: String {
        let parts = displayName.split(separator: " ")
        let firstInitial = parts.first?.prefix(1) ?? ""
        let lastInitial = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
}

extension User {
    static let preview = User(
        id: UUID().uuidString,
        email: "parent@family.com",
        displayName: "John Smith",
        profileImageURL: nil,
        familyMembers: ["spouse@family.com", "grandma@family.com"],
        joinDate: Date().addingTimeInterval(-86400 * 30)
    )
}
