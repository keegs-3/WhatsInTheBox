import SwiftUI

struct AddItemToSpaceView: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var category: ItemCategory = .box
    @State private var selectedType: ItemType?
    @State private var weight: Float?
    @State private var width: Float = 18
    @State private var height: Float = 18
    @State private var depth: Float = 16
    @State private var stackable = false
    @State private var selectedColor = "#8B6914"
    @State private var bodyColor = ""  // empty = same as lid, "clear" = transparent
    @State private var notes = ""
    @State private var productUrl = ""
    @State private var isGeneratingShape = false
    @State private var fullnessPercent: Double = 0

    private let boxColors = [
        "#8B6914", "#D2691E", "#FF6600", "#4A90D9",
        "#2ECC71", "#E74C3C", "#9B59B6", "#F39C12",
        "#1ABC9C", "#1A5276", "#6B3A2A", "#C4A35A",
    ]

    private var containerCategories: [ItemCategory] { [.box, .tote, .furniture, .appliance, .misc] }

    private var filteredTypes: [ItemType] {
        manager.itemTypes.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Type", selection: $category) {
                        ForEach(containerCategories, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if !filteredTypes.isEmpty {
                    Section("Preset Type") {
                        Picker("Select a preset", selection: $selectedType) {
                            Text("Custom").tag(nil as ItemType?)
                            ForEach(filteredTypes) { type in
                                Text(type.displayName).tag(type as ItemType?)
                            }
                        }
                        .onChange(of: selectedType) { _, newType in
                            if let t = newType {
                                width = t.width; height = t.height; depth = t.depth
                                stackable = t.stackable
                                if let c = t.colorHex { selectedColor = c }
                                if label.isEmpty { label = t.displayName }
                            }
                        }
                    }
                }

                Section("Info") {
                    TextField("Name (e.g. \"Kitchen stuff\")", text: $label)
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("Optional", value: $weight, format: .number)
                            .keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing)
                    }
                    Toggle("Stackable", isOn: $stackable)
                }

                Section("Dimensions (inches)") {
                    HStack { Text("Width"); Spacer()
                        TextField("W", value: $width, format: .number)
                            .keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing) }
                    HStack { Text("Height"); Spacer()
                        TextField("H", value: $height, format: .number)
                            .keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing) }
                    HStack { Text("Depth"); Spacer()
                        TextField("D", value: $depth, format: .number)
                            .keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing) }
                }

                if category.isContainer {
                    Section("Packing") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fullness: \(Int(fullnessPercent))%").font(.subheadline)
                            Slider(value: $fullnessPercent, in: 0...100, step: 5)
                                .tint(fullnessPercent < 50 ? .green : fullnessPercent < 80 ? .yellow : .red)
                        }
                    }
                }

                Section("Lid Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(boxColors, id: \.self) { hex in
                            Circle().fill(Color(hex: hex) ?? .brown).frame(width: 40, height: 40)
                                .overlay(Circle().stroke(Color.primary, lineWidth: selectedColor == hex ? 3 : 0))
                                .onTapGesture { selectedColor = hex }
                        }
                    }.padding(.vertical, 4)
                }

                Section("Body Color") {
                    Picker("Body", selection: $bodyColor) {
                        Text("Same as Lid").tag("")
                        Text("Clear / Transparent").tag("clear")
                        Text("Black").tag("#1C1C1E")
                        Text("White").tag("#FFFFFF")
                        Text("Grey").tag("#8E8E93")
                        Text("Brown (Cardboard)").tag("#8B6914")
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle("Add \(category.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await manager.addContainerToSpace(
                                name: label, category: category, itemType: selectedType,
                                weight: weight, width: width, height: height, depth: depth,
                                stackable: stackable, colorHex: selectedColor,
                                bodyColorHex: bodyColor.isEmpty ? nil : bodyColor,
                                notes: notes.isEmpty ? nil : notes,
                                productUrl: productUrl.isEmpty ? nil : productUrl,
                                fullnessPct: Int(fullnessPercent)
                            )
                            dismiss()
                        }
                    }
                    .disabled(label.isEmpty)
                }
            }
        }
    }
}
