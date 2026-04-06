import SwiftUI

struct AddSpaceView: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var width: Float = 10
    @State private var height: Float = 8
    @State private var depth: Float = 10

    var body: some View {
        NavigationStack {
            Form {
                Section("Space Info") {
                    TextField("Name (e.g. \"Unit #42\")", text: $name)
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
            }
            .navigationTitle("New Storage Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await manager.addSpace(name: name, width: width, height: height, depth: depth)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
