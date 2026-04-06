import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var manager: StorageManager
    @State private var showingAddItem = false
    @State private var searchText = ""
    @State private var filterCategory: ItemCategory?

    private var filteredItems: [Item] {
        var result = manager.inventoryItems
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let cat = filterCategory {
            result = result.filter { $0.category == cat }
        }
        return result
    }

    private var groupedItems: [(String, [Item])] {
        let grouped = Dictionary(grouping: filteredItems) { $0.category.displayName }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
        Group {
            if manager.inventoryItems.isEmpty && searchText.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Inventory Items")
                        .font(.title3.bold())
                    Text("Items you create here can be assigned to boxes and spaces later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Add Item") { showingAddItem = true }
                        .buttonStyle(.borderedProminent)
                    Spacer()
                }
            } else {
                List {
                    ForEach(groupedItems, id: \.0) { category, items in
                        Section(category) {
                            ForEach(items) { item in
                                InventoryRow(item: item)
                            }
                            .onDelete { indexSet in
                                Task {
                                    for index in indexSet {
                                        await manager.deleteItem(items[index])
                                    }
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search items...")
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemView()
        }
        .navigationTitle("Inventory")
        .task {
            await manager.loadInventory()
        }
        }
    }
}

struct InventoryRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon ?? item.category.iconName)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.name)
                        .font(.body)
                    if item.quantity > 1 {
                        Text("×\(item.quantity)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(.fill, in: Capsule())
                    }
                }
                HStack(spacing: 8) {
                    if let w = item.weight {
                        Text("\(String(format: "%.1f", w)) lbs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let w = item.width, let d = item.depth, let h = item.height {
                        Text("\(String(format: "%.0f", w))×\(String(format: "%.0f", d))×\(String(format: "%.0f", h))\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if item.isBreakable == true {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()

            Image(systemName: "arrow.right.circle")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Inventory Item

struct AddInventoryItemView: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ItemCategory = .item
    @State private var quantity = 1
    @State private var weight: Float?
    @State private var width: Float?
    @State private var height: Float?
    @State private var depth: Float?
    @State private var isBreakable = false
    @State private var isWrapped = false
    @State private var wrappingMaterial: WrappingMaterial = .none
    @State private var notes = ""
    @State private var icon: String?
    @State private var showingIconPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)

                    Button {
                        showingIconPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                                .foregroundStyle(.primary)
                            Spacer()
                            if let icon = icon {
                                Image(systemName: icon)
                                    .foregroundStyle(Color.accentColor)
                                Text(icon)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("None")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                }

                Section("Physical (Optional)") {
                    HStack { Text("Weight (lbs)"); Spacer()
                        TextField("lbs", value: $weight, format: .number)
                            .keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing) }
                    HStack { Text("Width (in)"); Spacer()
                        TextField("W", value: $width, format: .number)
                            .keyboardType(.decimalPad).frame(width: 60).multilineTextAlignment(.trailing) }
                    HStack { Text("Height (in)"); Spacer()
                        TextField("H", value: $height, format: .number)
                            .keyboardType(.decimalPad).frame(width: 60).multilineTextAlignment(.trailing) }
                    HStack { Text("Depth (in)"); Spacer()
                        TextField("D", value: $depth, format: .number)
                            .keyboardType(.decimalPad).frame(width: 60).multilineTextAlignment(.trailing) }
                }

                Section("Packing") {
                    Toggle("Breakable / Fragile", isOn: $isBreakable)
                    Toggle("Wrapped", isOn: $isWrapped)
                    if isWrapped {
                        Picker("Material", selection: $wrappingMaterial) {
                            ForEach(WrappingMaterial.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle("Add to Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await manager.addToInventory(
                                name: name, category: category,
                                width: width, height: height, depth: depth,
                                weight: weight, icon: icon, quantity: quantity,
                                isBreakable: isBreakable, isWrapped: isWrapped,
                                wrappingMaterial: isWrapped ? wrappingMaterial.rawValue : nil,
                                notes: notes.isEmpty ? nil : notes
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                SFSymbolPicker(selectedSymbol: $icon)
            }
        }
    }
}
