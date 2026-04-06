import SwiftUI

struct AddSpaceView: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var unitNumber = ""
    @State private var width: Float = 10
    @State private var height: Float = 8
    @State private var depth: Float = 10
    @State private var floor: Int = 1
    @State private var monthlyRate: Float?
    @State private var isClimateControlled = false

    private let commonSizes: [(String, Float, Float)] = [
        ("5×5", 5, 5), ("5×10", 5, 10), ("10×10", 10, 10),
        ("10×15", 10, 15), ("10×20", 10, 20), ("10×25", 10, 25),
        ("10×30", 10, 30), ("20×15", 20, 15), ("20×20", 20, 20),
    ]

    private var isStorageLocation: Bool {
        let type = manager.selectedLocation?.locationType
        return type == .storageFacility || type == .warehouse
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(isStorageLocation ? "Unit Info" : "Space Info") {
                    if isStorageLocation {
                        TextField("Unit number", text: $unitNumber)
                    }
                    TextField("Name (optional)", text: $name)
                }

                if isStorageLocation {
                    Section("Quick Size") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(commonSizes, id: \.0) { size in
                                    Button(size.0) {
                                        width = size.1
                                        depth = size.2
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(width == size.1 && depth == size.2 ? .blue : .gray)
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
                        Text("Depth")
                        Spacer()
                        TextField("D", value: $depth, format: .number)
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
                }

                if isStorageLocation {
                    Section("Details") {
                        HStack {
                            Text("Floor")
                            Spacer()
                            Picker("Floor", selection: $floor) {
                                ForEach(1...5, id: \.self) { f in
                                    Text("\(f)").tag(f)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        Toggle("Climate Controlled", isOn: $isClimateControlled)
                        HStack {
                            Text("$/month")
                            Spacer()
                            TextField("Rate", value: $monthlyRate, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle(isStorageLocation ? "New Unit" : "New Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            let spaceName: String
                            if !name.isEmpty {
                                spaceName = name
                            } else if !unitNumber.isEmpty {
                                spaceName = "Unit \(unitNumber)"
                            } else {
                                spaceName = "\(String(format: "%.0f", width))×\(String(format: "%.0f", depth)) Space"
                            }
                            await manager.addSpace(
                                name: spaceName,
                                width: width,
                                height: height,
                                depth: depth,
                                unitNumber: unitNumber.isEmpty ? nil : unitNumber,
                                floor: floor,
                                monthlyRate: monthlyRate,
                                isClimateControlled: isClimateControlled
                            )
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
