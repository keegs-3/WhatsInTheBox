import SwiftUI

struct AddBoxView: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var weight: Float?
    @State private var width: Float = 1.5
    @State private var height: Float = 1.5
    @State private var depth: Float = 1.5
    @State private var selectedColor = "#8B6914"

    private let boxColors = [
        "#8B6914", // cardboard brown
        "#D2691E", // chocolate
        "#4A90D9", // blue
        "#2ECC71", // green
        "#E74C3C", // red
        "#9B59B6", // purple
        "#F39C12", // orange
        "#1ABC9C", // teal
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Box Info") {
                    TextField("Label (e.g. \"Kitchen stuff\")", text: $label)
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("Optional", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Dimensions (feet)") {
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
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(boxColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .brown)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == hex ? 3 : 0)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Box")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await manager.addBox(label: label, weight: weight, width: width, height: height, depth: depth)
                            dismiss()
                        }
                    }
                    .disabled(label.isEmpty)
                }
            }
        }
    }
}
