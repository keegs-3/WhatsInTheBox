import SwiftUI

struct BoxDetailView: View {
    @EnvironmentObject var manager: StorageManager
    let item: StorageItem
    @State private var showingAddContent = false
    @State private var fullness: Double = 0

    var body: some View {
        List {
            // Fullness gauge (boxes only)
            if item.category == .box {
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 8)
                                .frame(width: 100, height: 100)
                            Circle()
                                .trim(from: 0, to: fullness / 100)
                                .stroke(
                                    fullnessColor(Int(fullness)),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: fullness)
                            Text("\(Int(fullness))%")
                                .font(.title2.bold())
                        }

                        Slider(value: $fullness, in: 0...100, step: 5) {
                            Text("Fullness")
                        }
                        .onChange(of: fullness) { _, newValue in
                            var updated = item
                            updated.fullnessPercent = Int(newValue)
                            Task { await manager.updateItem(updated) }
                        }
                        .tint(fullnessColor(Int(fullness)))

                        Text("How full is this box?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }

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
                if let url = item.productUrl, !url.isEmpty, let link = URL(string: url) {
                    Link("Product Link", destination: link)
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
            fullness = Double(item.fullnessPercent)
            await manager.loadContents(for: item)
        }
    }

    private func fullnessColor(_ percent: Int) -> Color {
        if percent < 50 { return .green }
        if percent < 80 { return .yellow }
        return .red
    }
}
