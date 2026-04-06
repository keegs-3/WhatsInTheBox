import Foundation
import SwiftUI

@MainActor
class StorageManager: ObservableObject {
    @Published var spaces: [StorageSpace] = []
    @Published var selectedSpace: StorageSpace?
    @Published var boxes: [StorageBox] = []
    @Published var selectedBox: StorageBox?
    @Published var items: [BoxItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SupabaseService.shared

    // MARK: - Spaces

    func loadSpaces() async {
        isLoading = true
        do {
            spaces = try await service.fetchSpaces()
        } catch {
            errorMessage = "Failed to load spaces: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func addSpace(name: String, width: Float, height: Float, depth: Float) async {
        let space = StorageSpace(name: name, width: width, height: height, depth: depth)
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

    // MARK: - Boxes

    func loadBoxes(for space: StorageSpace) async {
        selectedSpace = space
        isLoading = true
        do {
            boxes = try await service.fetchBoxes(for: space.id)
        } catch {
            errorMessage = "Failed to load boxes: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func addBox(label: String, weight: Float?, width: Float, height: Float, depth: Float) async {
        guard let space = selectedSpace else { return }
        let nextNumber = (boxes.map(\.boxNumber).max() ?? 0) + 1
        let box = StorageBox(
            spaceId: space.id,
            boxNumber: nextNumber,
            label: label,
            weight: weight,
            width: width,
            height: height,
            depth: depth
        )
        do {
            let created = try await service.createBox(box)
            boxes.append(created)
        } catch {
            errorMessage = "Failed to create box: \(error.localizedDescription)"
        }
    }

    func updateBox(_ box: StorageBox) async {
        do {
            let updated = try await service.updateBox(box)
            if let idx = boxes.firstIndex(where: { $0.id == box.id }) {
                boxes[idx] = updated
            }
        } catch {
            errorMessage = "Failed to update box: \(error.localizedDescription)"
        }
    }

    func deleteBox(_ box: StorageBox) async {
        do {
            try await service.deleteBox(box.id)
            boxes.removeAll { $0.id == box.id }
            if selectedBox?.id == box.id {
                selectedBox = nil
            }
        } catch {
            errorMessage = "Failed to delete box: \(error.localizedDescription)"
        }
    }

    // MARK: - Items

    func loadItems(for box: StorageBox) async {
        selectedBox = box
        do {
            items = try await service.fetchItems(for: box.id)
        } catch {
            errorMessage = "Failed to load items: \(error.localizedDescription)"
        }
    }

    func addItem(name: String, quantity: Int, notes: String?) async {
        guard let box = selectedBox else { return }
        let item = BoxItem(boxId: box.id, name: name, quantity: quantity, notes: notes)
        do {
            let created = try await service.createItem(item)
            items.append(created)
        } catch {
            errorMessage = "Failed to add item: \(error.localizedDescription)"
        }
    }

    func deleteItem(_ item: BoxItem) async {
        do {
            try await service.deleteItem(item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }
}
