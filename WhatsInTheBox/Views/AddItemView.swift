import SwiftUI

struct AddChildView: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss
    let parentId: UUID

    @State private var name = ""
    @State private var category: ItemCategory = .item
    @State private var quantity = 1
    @State private var notes = ""
    @State private var weight: Float?
    @State private var width: Float?
    @State private var height: Float?
    @State private var depth: Float?
    @State private var isBreakable = false
    @State private var isWrapped = false
    @State private var wrappingMaterial: WrappingMaterial = .none
    @State private var isContainer = false
    @State private var colorHex = "#4A90D9"

    var body: some View {
        NavigationStack {
            Form {
                Section("What are you adding?") {
                    Picker("Type", selection: $category) {
                        Text("Item").tag(ItemCategory.item)
                        Text("Box/Tote").tag(ItemCategory.tote)
                        Text("Misc").tag(ItemCategory.misc)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: category) { _, newVal in
                        isContainer = newVal.isContainer
                    }
                }

                Section("Item") {
                    TextField("Name", text: $name)
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                }

                Section("Physical (Optional)") {
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("lbs", value: $weight, format: .number)
                            .keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Width (in)")
                        Spacer()
                        TextField("W", value: $width, format: .number)
                            .keyboardType(.decimalPad).frame(width: 60).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Height (in)")
                        Spacer()
                        TextField("H", value: $height, format: .number)
                            .keyboardType(.decimalPad).frame(width: 60).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Depth (in)")
                        Spacer()
                        TextField("D", value: $depth, format: .number)
                            .keyboardType(.decimalPad).frame(width: 60).multilineTextAlignment(.trailing)
                    }
                }

                Section("Packing") {
                    Toggle("Breakable / Fragile", isOn: $isBreakable)
                    Toggle("Wrapped", isOn: $isWrapped)
                    if isWrapped {
                        Picker("Material", selection: $wrappingMaterial) {
                            ForEach(WrappingMaterial.allCases, id: \.self) { mat in
                                Text(mat.displayName).tag(mat)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add to Box")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await manager.addChild(
                                name: name,
                                parentId: parentId,
                                category: category,
                                quantity: quantity,
                                width: width, height: height, depth: depth,
                                weight: weight,
                                isBreakable: isBreakable,
                                isWrapped: isWrapped,
                                wrappingMaterial: isWrapped ? wrappingMaterial.rawValue : nil,
                                notes: notes.isEmpty ? nil : notes,
                                isContainer: isContainer,
                                colorHex: isContainer ? colorHex : nil
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
