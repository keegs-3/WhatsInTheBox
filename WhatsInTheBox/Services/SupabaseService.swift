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

    // MARK: - Locations

    func fetchLocations() async throws -> [Location] {
        try await client
            .from("locations")
            .select()
            .order("sort_order")
            .order("name")
            .execute()
            .value
    }

    func createLocation(_ location: Location) async throws -> Location {
        try await client
            .from("locations")
            .insert(location)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteLocation(_ id: UUID) async throws {
        try await client
            .from("locations")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Storage Spaces

    func fetchSpaces(for locationId: UUID) async throws -> [StorageSpace] {
        try await client
            .from("storage_spaces")
            .select()
            .eq("location_id", value: locationId.uuidString)
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

    // MARK: - Item Types

    func fetchItemTypes() async throws -> [ItemType] {
        try await client
            .from("item_types")
            .select()
            .order("category")
            .order("brand")
            .order("name")
            .execute()
            .value
    }

    func createItemType(_ itemType: ItemType) async throws -> ItemType {
        try await client
            .from("item_types")
            .insert(itemType)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Storage Items

    func fetchItems(for spaceId: UUID) async throws -> [StorageItem] {
        try await client
            .from("storage_boxes")
            .select()
            .eq("space_id", value: spaceId.uuidString)
            .order("box_number")
            .execute()
            .value
    }

    func createItem(_ item: StorageItem) async throws -> StorageItem {
        try await client
            .from("storage_boxes")
            .insert(item)
            .select()
            .single()
            .execute()
            .value
    }

    func updateItem(_ item: StorageItem) async throws -> StorageItem {
        try await client
            .from("storage_boxes")
            .update(item)
            .eq("id", value: item.id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteItem(_ id: UUID) async throws {
        try await client
            .from("storage_boxes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Box Contents

    func fetchContents(for boxId: UUID) async throws -> [BoxItem] {
        try await client
            .from("box_items")
            .select()
            .eq("box_id", value: boxId.uuidString)
            .execute()
            .value
    }

    func createContent(_ item: BoxItem) async throws -> BoxItem {
        try await client
            .from("box_items")
            .insert(item)
            .select()
            .single()
            .execute()
            .value
    }

    func updateContent(_ item: BoxItem) async throws -> BoxItem {
        try await client
            .from("box_items")
            .update(item)
            .eq("id", value: item.id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteContent(_ id: UUID) async throws {
        try await client
            .from("box_items")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Edge Function: URL to 3D Shape

    func generateShapeFromURL(_ url: String) async throws -> ShapeData {
        struct Request: Encodable {
            let url: String
        }
        struct Response: Decodable {
            let shapeData: ShapeData
            enum CodingKeys: String, CodingKey {
                case shapeData = "shape_data"
            }
        }
        let response: Response = try await client.functions
            .invoke(
                "generate-shape",
                options: .init(body: Request(url: url))
            )
        return response.shapeData
    }
}
