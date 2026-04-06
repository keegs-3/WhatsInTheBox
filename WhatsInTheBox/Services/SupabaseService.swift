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
        try await client.from("locations").select().order("sort_order").order("name").execute().value
    }

    func createLocation(_ location: Location) async throws -> Location {
        try await client.from("locations").insert(location).select().single().execute().value
    }

    func deleteLocation(_ id: UUID) async throws {
        try await client.from("locations").delete().eq("id", value: id.uuidString).execute()
    }

    // MARK: - Storage Spaces

    func fetchSpaces(for locationId: UUID) async throws -> [StorageSpace] {
        try await client.from("storage_spaces").select().eq("location_id", value: locationId.uuidString).execute().value
    }

    func createSpace(_ space: StorageSpace) async throws -> StorageSpace {
        try await client.from("storage_spaces").insert(space).select().single().execute().value
    }

    func deleteSpace(_ id: UUID) async throws {
        try await client.from("storage_spaces").delete().eq("id", value: id.uuidString).execute()
    }

    // MARK: - Item Types

    func fetchItemTypes() async throws -> [ItemType] {
        try await client.from("item_types").select().order("category").order("brand").order("name").execute().value
    }

    func createItemType(_ itemType: ItemType) async throws -> ItemType {
        try await client.from("item_types").insert(itemType).select().single().execute().value
    }

    // MARK: - Items (unified table)

    /// Top-level items placed in a space (containers on the floor)
    func fetchSpaceItems(for spaceId: UUID) async throws -> [Item] {
        try await client.from("items").select()
            .eq("space_id", value: spaceId.uuidString)
            .is("parent_id", value: "null")
            .order("box_number")
            .execute().value
    }

    /// Children of a container
    func fetchChildren(of parentId: UUID) async throws -> [Item] {
        try await client.from("items").select()
            .eq("parent_id", value: parentId.uuidString)
            .order("created_at")
            .execute().value
    }

    /// Unassigned inventory items (no space, no parent)
    func fetchInventory(familyId: UUID) async throws -> [Item] {
        try await client.from("items").select()
            .eq("family_id", value: familyId.uuidString)
            .is("space_id", value: "null")
            .is("parent_id", value: "null")
            .order("name")
            .execute().value
    }

    func createItem(_ item: Item) async throws -> Item {
        try await client.from("items").insert(item).select().single().execute().value
    }

    func updateItem(_ item: Item) async throws -> Item {
        try await client.from("items").update(item).eq("id", value: item.id.uuidString).select().single().execute().value
    }

    func deleteItem(_ id: UUID) async throws {
        try await client.from("items").delete().eq("id", value: id.uuidString).execute()
    }

    // MARK: - Edge Function: URL to 3D Shape

    func generateShapeFromURL(_ url: String) async throws -> ShapeData {
        struct Request: Encodable { let url: String }
        struct Response: Decodable {
            let shapeData: ShapeData
            enum CodingKeys: String, CodingKey { case shapeData = "shape_data" }
        }
        let response: Response = try await client.functions.invoke("generate-shape", options: .init(body: Request(url: url)))
        return response.shapeData
    }
}
