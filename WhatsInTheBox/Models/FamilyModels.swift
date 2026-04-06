import Foundation

struct Family: Identifiable, Codable {
    let id: UUID
    var name: String
    var inviteCode: String?
    var createdBy: UUID
    var createdAt: Date

    init(id: UUID = UUID(), name: String, createdBy: UUID) {
        self.id = id
        self.name = name
        self.inviteCode = nil  // let DB generate it
        self.createdBy = createdBy
        self.createdAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

struct FamilyMember: Identifiable, Codable {
    let id: UUID
    var familyId: UUID
    var userId: UUID
    var role: String
    var joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}
