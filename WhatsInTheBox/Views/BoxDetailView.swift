import SwiftUI

struct BoxDetailView: View {
    @EnvironmentObject var manager: StorageManager
    let item: StorageItem
    @State private var showingAddContent = false

    var body: some View {
        List {
            Section("Info") {
                if item.category == .box {
                    LabeledContent("Number", value: "#\(item.boxNumber)")
                }
                LabeledContent("Label", value: item.label)
                LabeledContent("Category", value: item.category.rawValue.capitalized)
                if let w = item.weight {
                    LabeledContent("Weight", value: "\(String(format: "%.1f", w)) lbs")
                }
                LabeledContent("Size", value: "\(String(format: "%.0f", item.width))×\(String(format: "%.0f", item.depth))×\(String(format: "%.0f", item.height))\"")
                if item.stackable {
                    LabeledContent("Stackable", value: "Yes")
                }
                if let notes = item.notes, !notes.isEmpty {
                    LabeledContent("Notes", value: notes)
                }
                if let url = item.productUrl, !url.isEmpty {
                    Link("Product Link", destination: URL(string: url)!)
                }
            }

            if item.category == .box {
                Section("Contents (\(manager.contents.count) items)") {
                    if manager.contents.isEmpty {
                        Text("No items yet — tap + to add")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.contents) { content in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(content.name)
                                    Spacer()
                                    if content.quantity > 1 {
                                        Text("×\(content.quantity)")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(.fill, in: Capsule())
                                    }
                                }
                                if let notes = content.notes, !notes.isEmpty {
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
                                    await manager.deleteContent(manager.contents[index])
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(item.category == .box ? "Box #\(item.boxNumber)" : item.label)
        .toolbar {
            if item.category == .box {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddContent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddContent) {
            AddItemView()
        }
        .task {
            await manager.loadContents(for: item)
        }
    }
}
