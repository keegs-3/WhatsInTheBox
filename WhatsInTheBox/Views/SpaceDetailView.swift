import SwiftUI

struct SpaceDetailView: View {
    @EnvironmentObject var manager: StorageManager
    let space: StorageSpace

    @State private var showingAddItem = false
    @State private var selectedItem: Item?
    @State private var show3D = true

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Collapsible 3D View
            if show3D {
                StorageSceneView(space: space, items: manager.items, selectedItem: $selectedItem) { movedItem, x, y, z in
                    var updated = movedItem
                    updated.posX = x
                    updated.posY = y
                    updated.posZ = z
                    Task { await manager.updateItem(updated) }
                }
                .frame(height: 300)
                .background(Color(.systemGroupedBackground))
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // 3D toggle bar
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { show3D.toggle() }
            } label: {
                HStack {
                    Image(systemName: show3D ? "chevron.up" : "cube.transparent")
                        .font(.caption)
                    Text(show3D ? "Hide 3D" : "Show 3D")
                        .font(.caption.bold())
                    Spacer()
                    if let item = selectedItem {
                        Text(item.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .buttonStyle(.plain)

            // MARK: - Items List (always visible)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(manager.items) { item in
                        NavigationLink(destination: BoxDetailView(item: item)) {
                            ItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await manager.deleteItem(item) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        Divider().padding(.leading, 60)
                    }
                }
                .padding(.top, 4)
            }
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

// MARK: - Item Row (replaces cards)

struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            // Color swatch with number
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: item.colorHex ?? "#8B6914") ?? .brown)
                    .frame(width: 44, height: 44)
                if let num = item.boxNumber {
                    Text("#\(num)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: item.icon ?? item.category.iconName)
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if let w = item.weight {
                        Label("\(String(format: "%.0f", w)) lbs", systemImage: "scalemass")
                    }
                    if let w = item.width, let d = item.depth, let h = item.height {
                        Text("\(String(format: "%.0f", w))×\(String(format: "%.0f", d))×\(String(format: "%.0f", h))\"")
                    }
                    if item.stackable == true {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Fullness indicator for containers
            if item.isContainer, let pct = item.fullnessPct {
                VStack(spacing: 2) {
                    Text("\(pct)%")
                        .font(.caption2.bold())
                        .foregroundStyle(fullnessColor(pct))
                    Circle()
                        .trim(from: 0, to: CGFloat(pct) / 100)
                        .stroke(fullnessColor(pct), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(-90))
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func fullnessColor(_ pct: Int) -> Color {
        if pct < 50 { return .green }
        if pct < 80 { return .yellow }
        return .red
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
            if let w = item.width, let d = item.depth, let h = item.height {
                Text("\(String(format: "%.0f", w))×\(String(format: "%.0f", d))×\(String(format: "%.0f", h))\"")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
