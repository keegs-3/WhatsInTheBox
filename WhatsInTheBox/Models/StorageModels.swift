import Foundation
import SceneKit

// MARK: - Enums

enum ItemCategory: String, Codable, CaseIterable {
    case box, furniture, appliance, misc
}

enum LocationType: String, Codable, CaseIterable {
    case house
    case storageFacility = "storage_facility"
    case apartment
    case garage
    case warehouse
    case other

    var displayName: String {
        switch self {
        case .house: return "House"
        case .storageFacility: return "Storage Facility"
        case .apartment: return "Apartment"
        case .garage: return "Garage"
        case .warehouse: return "Warehouse"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .house: return "house.fill"
        case .storageFacility: return "building.2.fill"
        case .apartment: return "building.fill"
        case .garage: return "car.garage.fill"
        case .warehouse: return "shippingbox.fill"
        case .other: return "mappin.circle.fill"
        }
    }
}

// MARK: - Location (HomeKit "Home" equivalent)

struct Location: Identifiable, Codable {
    let id: UUID
    var familyId: UUID?
    var name: String
    var locationType: LocationType
    var address: String?
    var unitNumber: String?
    var iconName: String?
    var sortOrder: Int
    var phone: String?
    var websiteUrl: String?
    var accessHours: String?
    var officeHours: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        familyId: UUID? = nil,
        name: String,
        locationType: LocationType = .storageFacility,
        address: String? = nil,
        unitNumber: String? = nil,
        iconName: String? = nil,
        sortOrder: Int = 0,
        phone: String? = nil,
        websiteUrl: String? = nil,
        accessHours: String? = nil,
        officeHours: String? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.name = name
        self.locationType = locationType
        self.address = address
        self.unitNumber = unitNumber
        self.iconName = iconName ?? locationType.iconName
        self.sortOrder = sortOrder
        self.phone = phone
        self.websiteUrl = websiteUrl
        self.accessHours = accessHours
        self.officeHours = officeHours
        self.createdAt = Date()
    }

    var displayIcon: String {
        iconName ?? locationType.iconName
    }

    enum CodingKeys: String, CodingKey {
        case id, name, address, phone
        case familyId = "family_id"
        case locationType = "location_type"
        case unitNumber = "unit_number"
        case iconName = "icon_name"
        case sortOrder = "sort_order"
        case websiteUrl = "website_url"
        case accessHours = "access_hours"
        case officeHours = "office_hours"
        case createdAt = "created_at"
    }
}

// MARK: - Storage Space

struct StorageSpace: Identifiable, Codable {
    let id: UUID
    var familyId: UUID?
    var locationId: UUID?
    var name: String
    var width: Float   // feet
    var height: Float  // feet
    var depth: Float   // feet
    var unitNumber: String?
    var floor: Int?
    var monthlyRate: Float?
    var isClimateControlled: Bool
    var moveInDate: Date?
    var contractEndDate: Date?
    var discountMonths: Int?
    var discountRate: Float?
    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        familyId: UUID? = nil,
        locationId: UUID? = nil,
        name: String,
        width: Float,
        height: Float,
        depth: Float,
        unitNumber: String? = nil,
        floor: Int? = nil,
        monthlyRate: Float? = nil,
        isClimateControlled: Bool = false,
        moveInDate: Date? = nil,
        contractEndDate: Date? = nil,
        discountMonths: Int? = nil,
        discountRate: Float? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.locationId = locationId
        self.name = name
        self.width = width
        self.height = height
        self.depth = depth
        self.unitNumber = unitNumber
        self.floor = floor
        self.monthlyRate = monthlyRate
        self.isClimateControlled = isClimateControlled
        self.moveInDate = moveInDate
        self.contractEndDate = contractEndDate
        self.discountMonths = discountMonths
        self.discountRate = discountRate
        self.notes = notes
        self.createdAt = Date()
    }

    var displayName: String {
        if let num = unitNumber, !num.isEmpty {
            return "Unit \(num)"
        }
        return name
    }

    var sizeLabel: String {
        "\(String(format: "%.0f", width))×\(String(format: "%.0f", depth))"
    }

    enum CodingKeys: String, CodingKey {
        case id, name, width, height, depth, floor, notes
        case familyId = "family_id"
        case locationId = "location_id"
        case unitNumber = "unit_number"
        case monthlyRate = "monthly_rate"
        case isClimateControlled = "is_climate_controlled"
        case moveInDate = "move_in_date"
        case contractEndDate = "contract_end_date"
        case discountMonths = "discount_months"
        case discountRate = "discount_rate"
        case createdAt = "created_at"
    }
}

// MARK: - Item Type (templates: Husky 27gal, IKEA shelf, etc.)

struct ItemType: Identifiable, Codable, Hashable {
    static func == (lhs: ItemType, rhs: ItemType) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    var name: String
    var brand: String?
    var category: ItemCategory
    var width: Float      // inches
    var height: Float     // inches
    var depth: Float      // inches
    var weightEmpty: Float?
    var stackable: Bool
    var maxStack: Int?
    var colorHex: String?
    var productUrl: String?
    var shapeHint: String?    // box, cylinder, l_shape, irregular, custom
    var shapeData: ShapeData?
    var imageUrl: String?
    var isPreset: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        category: ItemCategory = .box,
        width: Float,
        height: Float,
        depth: Float,
        weightEmpty: Float? = nil,
        stackable: Bool = false,
        maxStack: Int? = 1,
        colorHex: String? = "#8B6914",
        productUrl: String? = nil,
        shapeHint: String? = "box",
        shapeData: ShapeData? = nil,
        isPreset: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.width = width
        self.height = height
        self.depth = depth
        self.weightEmpty = weightEmpty
        self.stackable = stackable
        self.maxStack = maxStack
        self.colorHex = colorHex
        self.productUrl = productUrl
        self.shapeHint = shapeHint
        self.shapeData = shapeData
        self.isPreset = isPreset
        self.createdAt = Date()
    }

    /// Dimensions converted to feet for 3D rendering
    var widthFeet: Float { width / 12.0 }
    var heightFeet: Float { height / 12.0 }
    var depthFeet: Float { depth / 12.0 }

    var displayName: String {
        if let brand = brand {
            return "\(brand) \(name)"
        }
        return name
    }

    enum CodingKeys: String, CodingKey {
        case id, name, brand, category, width, height, depth
        case weightEmpty = "weight_empty"
        case stackable
        case maxStack = "max_stack"
        case colorHex = "color_hex"
        case productUrl = "product_url"
        case shapeHint = "shape_hint"
        case shapeData = "shape_data"
        case imageUrl = "image_url"
        case isPreset = "is_preset"
        case createdAt = "created_at"
    }
}

// MARK: - Shape Data (AI-generated or manual 3D shape info)

struct ShapeData: Codable {
    var segments: [ShapeSegment]?   // for composite shapes (L-shaped desk, etc.)
    var profile: String?            // SVG-like path for extrusion
    var notes: String?              // AI description of the shape

    struct ShapeSegment: Codable {
        var width: Float   // inches
        var height: Float
        var depth: Float
        var offsetX: Float
        var offsetY: Float
        var offsetZ: Float
        var type: String   // "box", "cylinder", "sphere"
    }
}

// MARK: - Storage Item (placed in a space — was "StorageBox")

struct StorageItem: Identifiable, Codable {
    let id: UUID
    var spaceId: UUID
    var itemTypeId: UUID?
    var boxNumber: Int
    var label: String
    var category: ItemCategory
    var weight: Float?       // lbs (total with contents)
    var width: Float         // inches (override or from type)
    var height: Float        // inches
    var depth: Float         // inches
    var posX: Float          // position in space (feet)
    var posY: Float
    var posZ: Float
    var rotationY: Float     // rotation around Y axis (radians)
    var colorHex: String
    var stackable: Bool
    var stackedOn: UUID?     // id of item this is stacked on
    var notes: String?
    var productUrl: String?
    var shapeHint: String?
    var shapeData: ShapeData?
    var fullnessPercent: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        spaceId: UUID,
        itemTypeId: UUID? = nil,
        boxNumber: Int,
        label: String,
        category: ItemCategory = .box,
        weight: Float? = nil,
        width: Float = 18,
        height: Float = 18,
        depth: Float = 16,
        posX: Float = 0,
        posY: Float = 0,
        posZ: Float = 0,
        rotationY: Float = 0,
        colorHex: String = "#8B6914",
        stackable: Bool = false,
        stackedOn: UUID? = nil,
        notes: String? = nil,
        productUrl: String? = nil,
        shapeHint: String? = "box",
        shapeData: ShapeData? = nil,
        fullnessPercent: Int = 0
    ) {
        self.id = id
        self.spaceId = spaceId
        self.itemTypeId = itemTypeId
        self.boxNumber = boxNumber
        self.label = label
        self.category = category
        self.weight = weight
        self.width = width
        self.height = height
        self.depth = depth
        self.posX = posX
        self.posY = posY
        self.posZ = posZ
        self.rotationY = rotationY
        self.colorHex = colorHex
        self.stackable = stackable
        self.stackedOn = stackedOn
        self.notes = notes
        self.productUrl = productUrl
        self.shapeHint = shapeHint
        self.shapeData = shapeData
        self.fullnessPercent = fullnessPercent
        self.createdAt = Date()
    }

    /// Dimensions in feet for 3D rendering
    var widthFeet: Float { width / 12.0 }
    var heightFeet: Float { height / 12.0 }
    var depthFeet: Float { depth / 12.0 }

    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case itemTypeId = "item_type_id"
        case boxNumber = "box_number"
        case label, category, weight, width, height, depth
        case posX = "pos_x"
        case posY = "pos_y"
        case posZ = "pos_z"
        case rotationY = "rotation_y"
        case colorHex = "color_hex"
        case stackable
        case stackedOn = "stacked_on"
        case notes
        case productUrl = "product_url"
        case shapeHint = "shape_hint"
        case shapeData = "shape_data"
        case fullnessPercent = "fullness_percent"
        case createdAt = "created_at"
    }
}

// MARK: - Box Item (contents of a box/container)

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
