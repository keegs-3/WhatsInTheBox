import SwiftUI

struct SpaceDetailView: View {
    @EnvironmentObject var manager: StorageManager
    let space: StorageSpace

    @State private var showingAddItem = false
    @State private var selectedItem: Item?
    @State private var showScene = true

    var body: some View {
        VStack(spacing: 0) {
            if showScene {
                StorageSceneView(space: space, items: manager.items, selectedItem: $selectedItem) { movedItem, x, y, z in
                    var updated = movedItem
                    updated.posX = x
                    updated.posY = y
                    updated.posZ = z
                    Task { await manager.updateItem(updated) }
                }
                    .frame(height: 350)
                    .background(Color(.systemGroupedBackground))
            }

            Picker("View", selection: $showScene) {
                Label("3D", systemImage: "cube").tag(true)
                Label("Cards", systemImage: "square.grid.2x2").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if showScene {
                if let item = selectedItem {
                    ItemInfoPanel(item: item)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Text("Tap an item in the 3D view to inspect it")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            } else {
                ItemListView(space: space)
            }

            Spacer(minLength: 0)
        }
        .navigationTitle(space.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemToSpaceView()
        }
        .task {
            await manager.loadItems(for: space)
            await manager.loadItemTypes()
        }
    }
}

struct ItemInfoPanel: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    item.isContainer ? (item.boxNumber.map { "Box #\($0)" } ?? item.name) : item.name,
                    systemImage: item.isContainer ? "shippingbox.fill" : (item.icon ?? "cube")
                )
                .font(.headline)
                Spacer()
                if let w = item.weight {
                    Text("\(String(format: "%.1f", w)) lbs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if item.isContainer {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                if let w = item.width, let d = item.depth, let h = item.height {
                    Text("\(String(format: "%.0f", w))×\(String(format: "%.0f", d))×\(String(format: "%.0f", h))\"")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                if item.stackable == true {
                    Label("Stackable", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                Text(item.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.fill, in: Capsule())
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
