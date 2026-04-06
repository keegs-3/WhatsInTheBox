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
    @State private var notes = ""
    @State private var productUrl = ""
    @State private var isGeneratingShape = false

    private let boxColors = [
        "#8B6914", "#D2691E", "#FF6600", "#4A90D9",
        "#2ECC71", "#E74C3C", "#9B59B6", "#F39C12",
        "#1ABC9C", "#1A5276", "#6B3A2A", "#C4A35A",
    ]

    private var filteredTypes: [ItemType] {
        manager.itemTypes.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Type", selection: $category) {
                        ForEach(ItemCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
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
                                width = t.width
                                height = t.height
                                depth = t.depth
                                stackable = t.stackable
                                if let c = t.colorHex { selectedColor = c }
                                if label.isEmpty { label = t.displayName }
                            }
                        }
                    }
                }

                Section("Info") {
                    TextField("Label (e.g. \"Kitchen stuff\")", text: $label)
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("Optional", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle("Stackable", isOn: $stackable)
                }

                Section("Dimensions (inches)") {
                    HStack {
                        Text("Width")
                        Spacer()
                        TextField("W", value: $width, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("H", value: $height, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Depth")
                        Spacer()
                        TextField("D", value: $depth, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Product URL (optional)") {
                    TextField("https://...", text: $productUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    if !productUrl.isEmpty {
                        Button {
                            Task {
                                isGeneratingShape = true
                                if let shape = await manager.generateShape(from: productUrl) {
                                    // Apply AI-generated dimensions if available
                                    if let segments = shape.segments, let first = segments.first {
                                        width = first.width
                                        height = first.height
                                        depth = first.depth
                                    }
                                }
                                isGeneratingShape = false
                            }
                        } label: {
                            if isGeneratingShape {
                                ProgressView()
                            } else {
                                Label("Auto-detect dimensions", systemImage: "sparkles")
                            }
                        }
                        .disabled(isGeneratingShape)
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(boxColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .brown)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle().stroke(Color.primary, lineWidth: selectedColor == hex ? 3 : 0)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add \(category.rawValue.capitalized)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await manager.addItem(
                                label: label,
                                category: category,
                                itemType: selectedType,
                                weight: weight,
                                width: width,
                                height: height,
                                depth: depth,
                                stackable: stackable,
                                colorHex: selectedColor,
                                notes: notes.isEmpty ? nil : notes,
                                productUrl: productUrl.isEmpty ? nil : productUrl
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
