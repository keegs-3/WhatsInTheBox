import SwiftUI

struct BoxDetailView: View {
    @EnvironmentObject var manager: StorageManager
    let box: StorageBox
    @State private var showingAddItem = false

    var body: some View {
        List {
            Section("Box Info") {
                LabeledContent("Number", value: "#\(box.boxNumber)")
                LabeledContent("Label", value: box.label)
                if let w = box.weight {
                    LabeledContent("Weight", value: "\(String(format: "%.1f", w)) lbs")
                }
                LabeledContent("Size", value: "\(String(format: "%.1f", box.width))×\(String(format: "%.1f", box.depth))×\(String(format: "%.1f", box.height)) ft")
            }

            Section("Contents (\(manager.items.count) items)") {
                if manager.items.isEmpty {
                    Text("No items yet — tap + to add")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.items) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(item.name)
                                    .font(.body)
                                Spacer()
                                if item.quantity > 1 {
                                    Text("×\(item.quantity)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(.fill, in: Capsule())
                                }
                            }
                            if let notes = item.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await manager.deleteItem(manager.items[index])
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Box #\(box.boxNumber)")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView()
        }
        .task {
            await manager.loadItems(for: box)
        }
    }
}
