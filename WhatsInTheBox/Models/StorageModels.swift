import Foundation
import SceneKit

// MARK: - Storage Space

struct StorageSpace: Identifiable, Codable {
    let id: UUID
    var name: String
    var width: Float   // feet
    var height: Float  // feet
    var depth: Float   // feet
    var createdAt: Date

    init(id: UUID = UUID(), name: String, width: Float, height: Float, depth: Float) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.depth = depth
        self.createdAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, name, width, height, depth
        case createdAt = "created_at"
    }
}

// MARK: - Storage Box

struct StorageBox: Identifiable, Codable {
    let id: UUID
    var spaceId: UUID
    var boxNumber: Int
    var label: String
    var weight: Float?  // lbs
    var width: Float    // feet
    var height: Float   // feet
    var depth: Float    // feet
    var posX: Float     // position in space
    var posY: Float
    var posZ: Float
    var colorHex: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        spaceId: UUID,
        boxNumber: Int,
        label: String,
        weight: Float? = nil,
        width: Float = 1.5,
        height: Float = 1.5,
        depth: Float = 1.5,
        posX: Float = 0,
        posY: Float = 0,
        posZ: Float = 0,
        colorHex: String = "#8B6914"
    ) {
        self.id = id
        self.spaceId = spaceId
        self.boxNumber = boxNumber
        self.label = label
        self.weight = weight
        self.width = width
        self.height = height
        self.depth = depth
        self.posX = posX
        self.posY = posY
        self.posZ = posZ
        self.colorHex = colorHex
        self.createdAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case boxNumber = "box_number"
        case label, weight, width, height, depth
        case posX = "pos_x"
        case posY = "pos_y"
        case posZ = "pos_z"
        case colorHex = "color_hex"
        case createdAt = "created_at"
    }
}

// MARK: - Box Item (contents of a box)

struct BoxItem: Identifiable, Codable {
    let id: UUID
    var boxId: UUID
    var name: String
    var quantity: Int
    var notes: String?
    var createdAt: Date

    init(id: UUID = UUID(), boxId: UUID, name: String, quantity: Int = 1, notes: String? = nil) {
        self.id = id
        self.boxId = boxId
        self.name = name
        self.quantity = quantity
        self.notes = notes
        self.createdAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case boxId = "box_id"
        case name, quantity, notes
        case createdAt = "created_at"
    }
}
