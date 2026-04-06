import SwiftUI

struct SpaceDetailView: View {
    @EnvironmentObject var manager: StorageManager
    let space: StorageSpace

    @State private var showingAddBox = false
    @State private var selectedBox: StorageBox?
    @State private var showScene = true

    var body: some View {
        VStack(spacing: 0) {
            if showScene {
                StorageSceneView(space: space, boxes: manager.boxes, selectedBox: $selectedBox)
                    .frame(height: 350)
                    .background(Color(.systemGroupedBackground))
            }

            // Toggle between 3D and list
            Picker("View", selection: $showScene) {
                Label("3D", systemImage: "cube").tag(true)
                Label("List", systemImage: "list.bullet").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if showScene {
                // Box info panel below 3D view
                if let box = selectedBox {
                    BoxInfoPanel(box: box)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Text("Tap a box in the 3D view to inspect it")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            } else {
                BoxListView(space: space)
            }

            Spacer(minLength: 0)
        }
        .navigationTitle(space.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddBox = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBox) {
            AddBoxView()
        }
        .task {
            await manager.loadBoxes(for: space)
        }
    }
}

struct BoxInfoPanel: View {
    let box: StorageBox

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Box #\(box.boxNumber)", systemImage: "shippingbox.fill")
                    .font(.headline)
                Spacer()
                if let w = box.weight {
                    Text("\(String(format: "%.1f", w)) lbs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Text(box.label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(String(format: "%.1f", box.width))×\(String(format: "%.1f", box.depth))×\(String(format: "%.1f", box.height)) ft")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
