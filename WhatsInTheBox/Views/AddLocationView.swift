import SwiftUI

struct AddLocationView: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var locationType: LocationType = .storageFacility
    @State private var address = ""
    @State private var unitNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("Name (e.g. \"Public Storage - Raleigh\")", text: $name)

                    Picker("Type", selection: $locationType) {
                        ForEach(LocationType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                }

                Section("Address (Optional)") {
                    TextField("Street address", text: $address)
                        .textContentType(.fullStreetAddress)
                }

                if locationType == .storageFacility || locationType == .warehouse {
                    Section("Unit") {
                        TextField("Unit number (e.g. \"42\")", text: $unitNumber)
                    }
                }
            }
            .navigationTitle("New Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await manager.addLocation(
                                name: name,
                                type: locationType,
                                address: address.isEmpty ? nil : address,
                                unitNumber: unitNumber.isEmpty ? nil : unitNumber
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
