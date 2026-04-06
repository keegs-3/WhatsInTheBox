import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    // MARK: - Storage Spaces

    func fetchSpaces() async throws -> [StorageSpace] {
        try await client
            .from("storage_spaces")
            .select()
            .execute()
            .value
    }

    func createSpace(_ space: StorageSpace) async throws -> StorageSpace {
        try await client
            .from("storage_spaces")
            .insert(space)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteSpace(_ id: UUID) async throws {
        try await client
            .from("storage_spaces")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Boxes

    func fetchBoxes(for spaceId: UUID) async throws -> [StorageBox] {
        try await client
            .from("storage_boxes")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .order("box_number")
            .execute()
            .value
    }

    func createBox(_ box: StorageBox) async throws -> StorageBox {
        try await client
            .from("storage_boxes")
            .insert(box)
            .select()
            .single()
            .execute()
            .value
    }

    func updateBox(_ box: StorageBox) async throws -> StorageBox {
        try await client
            .from("storage_boxes")
            .update(box)
            .eq("id", value: box.id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteBox(_ id: UUID) async throws {
        try await client
            .from("storage_boxes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Box Items

    func fetchItems(for boxId: UUID) async throws -> [BoxItem] {
        try await client
            .from("box_items")
            .select()
            .eq("box_id", value: boxId.uuidString)
            .execute()
            .value
    }

    func createItem(_ item: BoxItem) async throws -> BoxItem {
        try await client
            .from("box_items")
            .insert(item)
            .select()
            .single()
            .execute()
            .value
    }

    func updateItem(_ item: BoxItem) async throws -> BoxItem {
        try await client
            .from("box_items")
            .update(item)
            .eq("id", value: item.id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteItem(_ id: UUID) async throws {
        try await client
            .from("box_items")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
