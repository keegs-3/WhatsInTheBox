import Foundation
import SceneKit

// MARK: - Enums

enum ItemCategory: String, Codable, CaseIterable {
    case box, tote, furniture, appliance, item, misc

    var displayName: String {
        switch self {
        case .box: return "Box"
        case .tote: return "Tote"
        case .furniture: return "Furniture"
        case .appliance: return "Appliance"
        case .item: return "Item"
        case .misc: return "Misc"
        }
    }

    var iconName: String {
        switch self {
        case .box: return "shippingbox"
        case .tote: return "archivebox"
        case .furniture: return "cabinet"
        case .appliance: return "washer"
        case .item: return "cube.box"
        case .misc: return "ellipsis.circle"
        }
    }

    var isContainer: Bool {
        switch self {
        case .box, .tote: return true
        default: return false
        }
    }
}

enum WrappingMaterial: String, Codable, CaseIterable {
    case bubbleWrap = "bubble_wrap"
    case foamSheet = "foam_sheet"
    case packingPaper = "packing_paper"
    case newspaper
    case clothTowel = "cloth_towel"
    case none

    var displayName: String {
        switch self {
        case .bubbleWrap: return "Bubble Wrap"
        case .foamSheet: return "Foam Sheet"
        case .packingPaper: return "Packing Paper"
        case .newspaper: return "Newspaper"
        case .clothTowel: return "Cloth/Towel"
        case .none: return "None"
        }
    }
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

// MARK: - Item (unified — containers, contents, inventory)

struct Item: Identifiable, Codable {
    let id: UUID
    var familyId: UUID?

    // Hierarchy
    var spaceId: UUID?       // set for top-level items placed in a 3D space
    var parentId: UUID?      // set when nested inside another item

    // Identity
    var name: String
    var description: String?
    var icon: String?        // SF Symbol name
    var category: ItemCategory
    var itemTypeId: UUID?

    // Physical (all optional for simple items)
    var width: Float?        // inches
    var height: Float?       // inches
    var depth: Float?        // inches
    var weight: Float?       // lbs (own weight, not including contents)
    var quantity: Int

    // Container fields
    var isContainer: Bool
    var colorHex: String?
    var fullnessPct: Int?
    var boxNumber: Int?
    var stackable: Bool?
    var stackedOn: UUID?

    // 3D placement (only when spaceId is set)
    var posX: Float?
    var posY: Float?
    var posZ: Float?
    var rotationY: Float?

    // Shape
    var shapeHint: String?
    var shapeData: ShapeData?
    var productUrl: String?

    // Item properties
    var isBreakable: Bool?
    var isWrapped: Bool?
    var wrappingMaterial: String?

    var notes: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        familyId: UUID? = nil,
        spaceId: UUID? = nil,
        parentId: UUID? = nil,
        name: String,
        description: String? = nil,
        icon: String? = nil,
        category: ItemCategory = .item,
        itemTypeId: UUID? = nil,
        width: Float? = nil,
        height: Float? = nil,
        depth: Float? = nil,
        weight: Float? = nil,
        quantity: Int = 1,
        isContainer: Bool = false,
        colorHex: String? = "#8B6914",
        fullnessPct: Int? = 0,
        boxNumber: Int? = nil,
        stackable: Bool? = false,
        stackedOn: UUID? = nil,
        posX: Float? = nil,
        posY: Float? = nil,
        posZ: Float? = nil,
        rotationY: Float? = nil,
        shapeHint: String? = "box",
        shapeData: ShapeData? = nil,
        productUrl: String? = nil,
        isBreakable: Bool? = false,
        isWrapped: Bool? = false,
        wrappingMaterial: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.spaceId = spaceId
        self.parentId = parentId
        self.name = name
        self.description = description
        self.icon = icon
        self.category = category
        self.itemTypeId = itemTypeId
        self.width = width
        self.height = height
        self.depth = depth
        self.weight = weight
        self.quantity = quantity
        self.isContainer = isContainer
        self.colorHex = colorHex
        self.fullnessPct = fullnessPct
        self.boxNumber = boxNumber
        self.stackable = stackable
        self.stackedOn = stackedOn
        self.posX = posX
        self.posY = posY
        self.posZ = posZ
        self.rotationY = rotationY
        self.shapeHint = shapeHint
        self.shapeData = shapeData
        self.productUrl = productUrl
        self.isBreakable = isBreakable
        self.isWrapped = isWrapped
        self.wrappingMaterial = wrappingMaterial
        self.notes = notes
        self.createdAt = Date()
    }

    // MARK: - Computed

    var widthFeet: Float { (width ?? 18) / 12.0 }
    var heightFeet: Float { (height ?? 18) / 12.0 }
    var depthFeet: Float { (depth ?? 16) / 12.0 }

    var isPlaced: Bool { spaceId != nil }
    var isNested: Bool { parentId != nil }
    var isUnassigned: Bool { spaceId == nil && parentId == nil }

    var volumeCubicInches: Float? {
        guard let w = width, let h = height, let d = depth else { return nil }
        return w * h * d
    }

    var displayName: String {
        if let num = boxNumber, (category == .box || category == .tote) {
            return name.isEmpty ? "#\(num)" : name
        }
        return name
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, category, width, height, depth, weight, quantity, notes
        case familyId = "family_id"
        case spaceId = "space_id"
        case parentId = "parent_id"
        case itemTypeId = "item_type_id"
        case isContainer = "is_container"
        case colorHex = "color_hex"
        case fullnessPct = "fullness_pct"
        case boxNumber = "box_number"
        case stackable
        case stackedOn = "stacked_on"
        case posX = "pos_x"
        case posY = "pos_y"
        case posZ = "pos_z"
        case rotationY = "rotation_y"
        case shapeHint = "shape_hint"
        case shapeData = "shape_data"
        case productUrl = "product_url"
        case isBreakable = "is_breakable"
        case isWrapped = "is_wrapped"
        case wrappingMaterial = "wrapping_material"
        case createdAt = "created_at"
    }
}
