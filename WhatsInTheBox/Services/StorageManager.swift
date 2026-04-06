import Foundation
import SwiftUI

@MainActor
class StorageManager: ObservableObject {
    @Published var locations: [Location] = []
    @Published var selectedLocation: Location?
    @Published var spaces: [StorageSpace] = []
    @Published var selectedSpace: StorageSpace?
    @Published var items: [StorageItem] = []
    @Published var selectedItem: StorageItem?
    @Published var contents: [BoxItem] = []
    @Published var itemTypes: [ItemType] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

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

    func addLocation(name: String, type: LocationType, address: String?, unitNumber: String?) async {
        let location = Location(
            familyId: familyId,
            name: name,
            locationType: type,
            address: address,
            unitNumber: unitNumber
        )
        do {
            let created = try await service.createLocation(location)
            locations.append(created)
            if selectedLocation == nil {
                selectedLocation = created
            }
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
                if let loc = selectedLocation {
                    await loadSpaces(for: loc)
                } else {
                    spaces = []
                }
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
        do {
            spaces = try await service.fetchSpaces(for: location.id)
        } catch {
            errorMessage = "Failed to load spaces: \(error.localizedDescription)"
        }
    }

    func addSpace(name: String, width: Float, height: Float, depth: Float) async {
        guard let location = selectedLocation else { return }
        let space = StorageSpace(
            familyId: familyId,
            locationId: location.id,
            name: name,
            width: width,
            height: height,
            depth: depth
        )
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
            if selectedSpace?.id == space.id {
                selectedSpace = nil
            }
        } catch {
            errorMessage = "Failed to delete space: \(error.localizedDescription)"
        }
    }

    // MARK: - Item Types

    func loadItemTypes() async {
        do {
            itemTypes = try await service.fetchItemTypes()
        } catch {
            errorMessage = "Failed to load item types: \(error.localizedDescription)"
        }
    }

    // MARK: - Storage Items

    func loadItems(for space: StorageSpace) async {
        selectedSpace = space
        isLoading = true
        do {
            items = try await service.fetchItems(for: space.id)
        } catch {
            errorMessage = "Failed to load items: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func addItem(
        label: String,
        category: ItemCategory,
        itemType: ItemType?,
        weight: Float?,
        width: Float,
        height: Float,
        depth: Float,
        stackable: Bool,
        colorHex: String,
        notes: String?,
        productUrl: String?,
        fullnessPercent: Int = 0
    ) async {
        guard let space = selectedSpace else { return }
        let nextNumber = (items.map(\.boxNumber).max() ?? 0) + 1
        let item = StorageItem(
            spaceId: space.id,
            itemTypeId: itemType?.id,
            boxNumber: nextNumber,
            label: label,
            category: category,
            weight: weight,
            width: width,
            height: height,
            depth: depth,
            colorHex: colorHex,
            stackable: stackable,
            notes: notes,
            productUrl: productUrl,
            shapeHint: itemType?.shapeHint ?? "box",
            fullnessPercent: fullnessPercent
        )
        do {
            let created = try await service.createItem(item)
            items.append(created)
        } catch {
            errorMessage = "Failed to create item: \(error.localizedDescription)"
        }
    }

    func updateItem(_ item: StorageItem) async {
        do {
            let updated = try await service.updateItem(item)
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
            }
        } catch {
            errorMessage = "Failed to update item: \(error.localizedDescription)"
        }
    }

    func deleteItem(_ item: StorageItem) async {
        do {
            try await service.deleteItem(item.id)
            items.removeAll { $0.id == item.id }
            if selectedItem?.id == item.id {
                selectedItem = nil
            }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    // MARK: - Box Contents

    func loadContents(for item: StorageItem) async {
        selectedItem = item
        do {
            contents = try await service.fetchContents(for: item.id)
        } catch {
            errorMessage = "Failed to load contents: \(error.localizedDescription)"
        }
    }

    func addContent(name: String, quantity: Int, notes: String?) async {
        guard let item = selectedItem else { return }
        let content = BoxItem(boxId: item.id, name: name, quantity: quantity, notes: notes)
        do {
            let created = try await service.createContent(content)
            contents.append(created)
        } catch {
            errorMessage = "Failed to add item: \(error.localizedDescription)"
        }
    }

    func deleteContent(_ item: BoxItem) async {
        do {
            try await service.deleteContent(item.id)
            contents.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    // MARK: - AI Shape Generation

    func generateShape(from url: String) async -> ShapeData? {
        do {
            return try await service.generateShapeFromURL(url)
        } catch {
            errorMessage = "Failed to generate shape: \(error.localizedDescription)"
            return nil
        }
    }
}
