import Foundation
import SwiftUI

@MainActor
class StorageManager: ObservableObject {
    @Published var locations: [Location] = []
    @Published var selectedLocation: Location?
    @Published var spaces: [StorageSpace] = []
    @Published var selectedSpace: StorageSpace?
    @Published var items: [Item] = []          // top-level items in selected space
    @Published var selectedItem: Item?
    @Published var children: [Item] = []       // children of selected item
    @Published var inventoryItems: [Item] = [] // unassigned items
    @Published var itemTypes: [ItemType] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var allBoxes: [Item] = []

    var familyId: UUID?

    private let service = SupabaseService.shared

    // MARK: - Locations

    func loadLocations() async {
        isLoading = true
        do {
            locations = try await service.fetchLocations()
            if selectedLocation == nil, let first = locations.first {
                selectedLocation = first
                await loadSpaces(for: first)
            }
        } catch {
            errorMessage = "Failed to load locations: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func addLocation(
        name: String, type: LocationType, address: String?, unitNumber: String?,
        phone: String? = nil, websiteUrl: String? = nil,
        accessHours: String? = nil, officeHours: String? = nil
    ) async {
        let location = Location(familyId: familyId, name: name, locationType: type,
                                address: address, unitNumber: unitNumber, phone: phone,
                                websiteUrl: websiteUrl, accessHours: accessHours, officeHours: officeHours)
        do {
            let created = try await service.createLocation(location)
            locations.append(created)
            if selectedLocation == nil { selectedLocation = created }
        } catch {
            errorMessage = "Failed to create location: \(error.localizedDescription)"
        }
    }

    func deleteLocation(_ location: Location) async {
        do {
            try await service.deleteLocation(location.id)
            locations.removeAll { $0.id == location.id }
            if selectedLocation?.id == location.id {
                selectedLocation = locations.first
                if let loc = selectedLocation { await loadSpaces(for: loc) } else { spaces = [] }
            }
        } catch {
            errorMessage = "Failed to delete location: \(error.localizedDescription)"
        }
    }

    func selectLocation(_ location: Location) async {
        selectedLocation = location
        await loadSpaces(for: location)
    }

    // MARK: - Spaces

    func loadSpaces(for location: Location) async {
        do { spaces = try await service.fetchSpaces(for: location.id) }
        catch { errorMessage = "Failed to load spaces: \(error.localizedDescription)" }
    }

    func addSpace(
        name: String, width: Float, height: Float, depth: Float,
        unitNumber: String? = nil, floor: Int? = nil, monthlyRate: Float? = nil,
        isClimateControlled: Bool = false, moveInDate: Date? = nil,
        contractEndDate: Date? = nil, discountMonths: Int? = nil,
        discountRate: Float? = nil, notes: String? = nil,
        locationOverride: Location? = nil
    ) async {
        guard let location = locationOverride ?? selectedLocation else { return }
        let space = StorageSpace(familyId: familyId, locationId: location.id, name: name,
                                 width: width, height: height, depth: depth,
                                 unitNumber: unitNumber, floor: floor, monthlyRate: monthlyRate,
                                 isClimateControlled: isClimateControlled, moveInDate: moveInDate,
                                 contractEndDate: contractEndDate, discountMonths: discountMonths,
                                 discountRate: discountRate, notes: notes)
        do {
            let created = try await service.createSpace(space)
            spaces.append(created)
        } catch {
            errorMessage = "Failed to create space: \(error.localizedDescription)"
        }
    }

    func deleteSpace(_ space: StorageSpace) async {
        do {
            try await service.deleteSpace(space.id)
            spaces.removeAll { $0.id == space.id }
        } catch {
            errorMessage = "Failed to delete space: \(error.localizedDescription)"
        }
    }

    // MARK: - Item Types

    func loadItemTypes() async {
        do { itemTypes = try await service.fetchItemTypes() }
        catch { errorMessage = "Failed to load item types: \(error.localizedDescription)" }
    }

    // MARK: - Items (space-level, top-level containers)

    func loadItems(for space: StorageSpace) async {
        selectedSpace = space
        isLoading = true
        do { items = try await service.fetchSpaceItems(for: space.id) }
        catch { errorMessage = "Failed to load items: \(error.localizedDescription)" }
        isLoading = false
    }

    /// Auto-calculate next position so boxes don't overlap
    func nextPosition(in space: StorageSpace) -> (Float, Float, Float) {
        var curX: Float = 0.2
        var curZ: Float = 0.2
        var rowMaxDepth: Float = 0

        for item in items {
            let endX = (item.posX ?? 0) + item.widthFeet
            let itemDepth = item.depthFeet
            if endX > curX { curX = endX + 0.2 }
            if itemDepth > rowMaxDepth { rowMaxDepth = itemDepth }
        }

        // If we'd go past the space width, start a new row
        if curX > space.width - 1 {
            curX = 0.2
            curZ += rowMaxDepth + 0.2
        }

        return (curX, 0, curZ)
    }

    func addContainerToSpace(
        name: String, category: ItemCategory, itemType: ItemType?,
        weight: Float?, width: Float, height: Float, depth: Float,
        stackable: Bool, colorHex: String, bodyColorHex: String? = nil,
        notes: String?, productUrl: String?, fullnessPct: Int = 0
    ) async {
        guard let space = selectedSpace else { return }
        let nextNum = (items.compactMap(\.boxNumber).max() ?? 0) + 1
        let pos = nextPosition(in: space)

        let item = Item(
            familyId: familyId, spaceId: space.id,
            name: name, category: category, itemTypeId: itemType?.id,
            width: width, height: height, depth: depth, weight: weight,
            isContainer: true, colorHex: colorHex, bodyColorHex: bodyColorHex,
            fullnessPct: fullnessPct,
            boxNumber: nextNum, stackable: stackable,
            posX: pos.0, posY: pos.1, posZ: pos.2,
            shapeHint: itemType?.shapeHint ?? "box",
            productUrl: productUrl, notes: notes
        )
        do {
            let created = try await service.createItem(item)
            items.append(created)
        } catch {
            errorMessage = "Failed to create item: \(error.localizedDescription)"
        }
    }

    func updateItem(_ item: Item) async {
        do {
            let updated = try await service.updateItem(item)
            if let idx = items.firstIndex(where: { $0.id == item.id }) { items[idx] = updated }
            if let idx = children.firstIndex(where: { $0.id == item.id }) { children[idx] = updated }
        } catch {
            errorMessage = "Failed to update item: \(error.localizedDescription)"
        }
    }

    func deleteItem(_ item: Item) async {
        do {
            try await service.deleteItem(item.id)
            items.removeAll { $0.id == item.id }
            children.removeAll { $0.id == item.id }
            inventoryItems.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    // MARK: - Children (contents of a container)

    func loadChildren(for item: Item) async {
        selectedItem = item
        do { children = try await service.fetchChildren(of: item.id) }
        catch { errorMessage = "Failed to load contents: \(error.localizedDescription)" }
    }

    func addChild(
        name: String, parentId: UUID, category: ItemCategory = .item,
        quantity: Int = 1, width: Float? = nil, height: Float? = nil, depth: Float? = nil,
        weight: Float? = nil, icon: String? = nil,
        isBreakable: Bool = false, isWrapped: Bool = false,
        wrappingMaterial: String? = nil, notes: String? = nil,
        isContainer: Bool = false, colorHex: String? = nil, boxNumber: Int? = nil
    ) async {
        let item = Item(
            familyId: familyId, parentId: parentId,
            name: name, icon: icon, category: category,
            width: width, height: height, depth: depth, weight: weight,
            quantity: quantity, isContainer: isContainer, colorHex: colorHex,
            boxNumber: boxNumber,
            isBreakable: isBreakable, isWrapped: isWrapped,
            wrappingMaterial: wrappingMaterial, notes: notes
        )
        do {
            let created = try await service.createItem(item)
            children.append(created)
        } catch {
            errorMessage = "Failed to add item: \(error.localizedDescription)"
        }
    }

    func deleteChild(_ item: Item) async {
        do {
            try await service.deleteItem(item.id)
            children.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    // MARK: - Inventory (unassigned items)

    func loadInventory() async {
        guard let fid = familyId else { return }
        do { inventoryItems = try await service.fetchInventory(familyId: fid) }
        catch { errorMessage = "Failed to load inventory: \(error.localizedDescription)" }
    }

    func addToInventory(
        name: String, category: ItemCategory = .item,
        width: Float? = nil, height: Float? = nil, depth: Float? = nil,
        weight: Float? = nil, icon: String? = nil, quantity: Int = 1,
        isBreakable: Bool = false, isWrapped: Bool = false,
        wrappingMaterial: String? = nil, notes: String? = nil
    ) async {
        let item = Item(
            familyId: familyId, name: name, icon: icon, category: category,
            width: width, height: height, depth: depth, weight: weight,
            quantity: quantity, isBreakable: isBreakable, isWrapped: isWrapped,
            wrappingMaterial: wrappingMaterial, notes: notes
        )
        do {
            let created = try await service.createItem(item)
            inventoryItems.append(created)
        } catch {
            errorMessage = "Failed to add to inventory: \(error.localizedDescription)"
        }
    }

    func assignToContainer(_ item: Item, containerId: UUID) async {
        var updated = item
        updated.parentId = containerId
        updated.spaceId = nil
        await updateItem(updated)
        inventoryItems.removeAll { $0.id == item.id }
    }

    // MARK: - Standalone Box Creation

    func addBox(
        name: String, category: ItemCategory = .box,
        width: Float, height: Float, depth: Float,
        weight: Float? = nil, stackable: Bool = false,
        colorHex: String = "#FF6600", bodyColorHex: String? = nil,
        notes: String? = nil, itemTypeId: UUID? = nil
    ) async {
        let nextNum = (allBoxes.compactMap(\.boxNumber).max() ?? 0) + 1
        let item = Item(
            familyId: familyId,
            name: name, category: category, itemTypeId: itemTypeId,
            width: width, height: height, depth: depth, weight: weight,
            isContainer: true, colorHex: colorHex, bodyColorHex: bodyColorHex,
            fullnessPct: 0, boxNumber: nextNum, stackable: stackable,
            notes: notes
        )
        do {
            let created = try await service.createItem(item)
            allBoxes.append(created)
        } catch {
            errorMessage = "Failed to create box: \(error.localizedDescription)"
        }
    }

    // MARK: - All Boxes (cross-space view)

    func loadAllBoxes() async {
        guard let fid = familyId else { return }
        do {
            let all: [Item] = try await service.client
                .from("items")
                .select()
                .eq("family_id", value: fid.uuidString)
                .eq("is_container", value: true)
                .order("box_number")
                .execute()
                .value
            allBoxes = all
        } catch {
            errorMessage = "Failed to load boxes: \(error.localizedDescription)"
        }
    }

    // MARK: - AI Shape Generation

    func generateShape(from url: String) async -> ShapeData? {
        do { return try await service.generateShapeFromURL(url) }
        catch {
            errorMessage = "Failed to generate shape: \(error.localizedDescription)"
            return nil
        }
    }
}
