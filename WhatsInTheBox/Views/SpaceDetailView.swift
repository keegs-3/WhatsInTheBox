import SwiftUI

struct SpaceDetailView: View {
    @EnvironmentObject var manager: StorageManager
    let space: StorageSpace

    @State private var showingAddItem = false
    @State private var selectedItem: StorageItem?
    @State private var showScene = true

    var body: some View {
        VStack(spacing: 0) {
            if showScene {
                StorageSceneView(space: space, items: manager.items, selectedItem: $selectedItem)
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
        .navigationTitle(space.name)
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
    let item: StorageItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    item.category == .box ? "Box #\(item.boxNumber)" : item.label,
                    systemImage: item.category == .box ? "shippingbox.fill" : "cabinet.fill"
                )
                .font(.headline)
                Spacer()
                if let w = item.weight {
                    Text("\(String(format: "%.1f", w)) lbs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if item.category == .box {
                Text(item.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Text("\(String(format: "%.0f", item.width))×\(String(format: "%.0f", item.depth))×\(String(format: "%.0f", item.height))\"")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if item.stackable {
                    Label("Stackable", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                Text(item.category.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.fill, in: Capsule())
            }
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
