import SwiftUI
import MapKit

struct AddLocationView: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss

    // Location info
    @State private var name = ""
    @State private var locationType: LocationType = .storageFacility
    @State private var address = ""
    @State private var phone = ""
    @State private var websiteUrl = ""
    // Access hours (gate)
    @State private var gateOpen = Calendar.current.date(from: DateComponents(hour: 6, minute: 0))!
    @State private var gateClose = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
    // Office hours
    @State private var weekdayOpen = Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!
    @State private var weekdayClose = Calendar.current.date(from: DateComponents(hour: 17, minute: 30))!
    @State private var weekendOpen = Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!
    @State private var weekendClose = Calendar.current.date(from: DateComponents(hour: 16, minute: 0))!
    @State private var hasWeekendHours = true
    @State private var trackHours = false

    // Unit info (for storage facilities)
    @State private var addUnit = true
    @State private var unitNumber = ""
    @State private var unitWidth: Float = 10
    @State private var unitDepth: Float = 10
    @State private var unitHeight: Float = 8
    @State private var unitFloor: Int = 1
    @State private var monthlyRate: Float?
    @State private var isClimateControlled = false

    // Contract
    @State private var moveInDate = Date()
    @State private var trackMoveIn = false
    @State private var contractEndDate = Date()
    @State private var trackContractEnd = false
    @State private var discountMonths: Int?
    @State private var discountRate: Float?
    @State private var unitNotes = ""

    // Address search
    @StateObject private var addressSearch = AddressSearchCompleter()
    @State private var showingSuggestions = false

    private var isStorageType: Bool {
        locationType == .storageFacility || locationType == .warehouse
    }

    // Common unit sizes
    private let commonSizes: [(String, Float, Float)] = [
        ("5×5", 5, 5), ("5×10", 5, 10), ("10×10", 10, 10),
        ("10×15", 10, 15), ("10×20", 10, 20), ("10×25", 10, 25),
        ("10×30", 10, 30), ("20×15", 20, 15), ("20×20", 20, 20),
    ]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Location
                Section("Location") {
                    TextField("Name", text: $name)

                    Picker("Type", selection: $locationType) {
                        ForEach(LocationType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                }

                // MARK: - Address
                Section("Address") {
                    TextField("Search for an address…", text: $addressSearch.query)
                        .textContentType(.fullStreetAddress)
                        .autocorrectionDisabled()
                        .onChange(of: addressSearch.query) { _, newValue in
                            showingSuggestions = true
                            addressSearch.updateQuery(newValue)
                        }

                    if showingSuggestions && !addressSearch.suggestions.isEmpty {
                        ForEach(addressSearch.suggestions, id: \.self) { suggestion in
                            Button {
                                address = [suggestion.title, suggestion.subtitle]
                                    .filter { !$0.isEmpty }
                                    .joined(separator: ", ")
                                addressSearch.query = address
                                showingSuggestions = false
                                if name.isEmpty { name = suggestion.title }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .foregroundStyle(.primary)
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // MARK: - Facility Details
                if isStorageType {
                    Section("Facility Details (Optional)") {
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                        TextField("Website URL", text: $websiteUrl)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Section {
                        Toggle("Track Hours", isOn: $trackHours)
                    }

                    if trackHours {
                        Section("Gate / Access Hours") {
                            DatePicker("Opens", selection: $gateOpen, displayedComponents: .hourAndMinute)
                            DatePicker("Closes", selection: $gateClose, displayedComponents: .hourAndMinute)
                        }

                        Section("Office Hours — Weekdays") {
                            DatePicker("Mon-Fri Open", selection: $weekdayOpen, displayedComponents: .hourAndMinute)
                            DatePicker("Mon-Fri Close", selection: $weekdayClose, displayedComponents: .hourAndMinute)
                        }

                        Section("Office Hours — Weekends") {
                            Toggle("Open on Weekends", isOn: $hasWeekendHours)
                            if hasWeekendHours {
                                DatePicker("Sat-Sun Open", selection: $weekendOpen, displayedComponents: .hourAndMinute)
                                DatePicker("Sat-Sun Close", selection: $weekendClose, displayedComponents: .hourAndMinute)
                            }
                        }
                    }
                }

                // MARK: - Unit Setup
                if isStorageType {
                    Section {
                        Toggle("Add a unit now", isOn: $addUnit)
                    }

                    if addUnit {
                        Section("Your Unit") {
                            TextField("Unit number", text: $unitNumber)

                            HStack {
                                Text("Floor")
                                Spacer()
                                Picker("Floor", selection: $unitFloor) {
                                    ForEach(1...5, id: \.self) { f in
                                        Text("\(f)").tag(f)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            Toggle("Climate Controlled", isOn: $isClimateControlled)
                        }

                        Section("Unit Size") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(commonSizes, id: \.0) { size in
                                        Button(size.0) {
                                            unitWidth = size.1
                                            unitDepth = size.2
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(unitWidth == size.1 && unitDepth == size.2 ? .blue : .gray)
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                            HStack {
                                Text("Width (ft)")
                                Spacer()
                                TextField("W", value: $unitWidth, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("Depth (ft)")
                                Spacer()
                                TextField("D", value: $unitDepth, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("Height (ft)")
                                Spacer()
                                TextField("H", value: $unitHeight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                            }
                        }

                        Section("Rental & Contract") {
                            HStack {
                                Text("$/month")
                                Spacer()
                                TextField("Rate", value: $monthlyRate, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 80)
                                    .multilineTextAlignment(.trailing)
                            }

                            Toggle("Move-in date", isOn: $trackMoveIn)
                            if trackMoveIn {
                                DatePicker("Move-in", selection: $moveInDate, displayedComponents: .date)
                            }

                            Toggle("Contract end date", isOn: $trackContractEnd)
                            if trackContractEnd {
                                DatePicker("Ends", selection: $contractEndDate, displayedComponents: .date)
                            }
                        }

                        Section("Discounts (Optional)") {
                            HStack {
                                Text("Discounted months")
                                Spacer()
                                TextField("#", value: $discountMonths, format: .number)
                                    .keyboardType(.numberPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("Discount rate ($/mo)")
                                Spacer()
                                TextField("$", value: $discountRate, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 80)
                                    .multilineTextAlignment(.trailing)
                            }
                        }

                        Section("Unit Notes") {
                            TextField("Notes about this unit", text: $unitNotes, axis: .vertical)
                                .lineLimit(2...4)
                        }
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
                            let finalAddress = address.isEmpty ? (addressSearch.query.isEmpty ? nil : addressSearch.query) : address

                            let fmt = DateFormatter()
                            fmt.dateFormat = "h:mm a"

                            let accessStr: String? = trackHours ? "\(fmt.string(from: gateOpen)) – \(fmt.string(from: gateClose))" : nil

                            var officeStr: String? = nil
                            if trackHours {
                                var parts = ["Mon-Fri \(fmt.string(from: weekdayOpen)) – \(fmt.string(from: weekdayClose))"]
                                if hasWeekendHours {
                                    parts.append("Sat-Sun \(fmt.string(from: weekendOpen)) – \(fmt.string(from: weekendClose))")
                                } else {
                                    parts.append("Sat-Sun Closed")
                                }
                                officeStr = parts.joined(separator: "\n")
                            }

                            await manager.addLocation(
                                name: name,
                                type: locationType,
                                address: finalAddress,
                                unitNumber: nil,
                                phone: phone.isEmpty ? nil : phone,
                                websiteUrl: websiteUrl.isEmpty ? nil : websiteUrl,
                                accessHours: accessStr,
                                officeHours: officeStr
                            )

                            // Auto-create the unit as a space if requested
                            if addUnit && isStorageType, let created = manager.locations.last {
                                let unitName = unitNumber.isEmpty ? "\(String(format: "%.0f", unitWidth))×\(String(format: "%.0f", unitDepth)) Unit" : "Unit \(unitNumber)"
                                await manager.addSpace(
                                    name: unitName,
                                    width: unitWidth,
                                    height: unitHeight,
                                    depth: unitDepth,
                                    unitNumber: unitNumber.isEmpty ? nil : unitNumber,
                                    floor: unitFloor,
                                    monthlyRate: monthlyRate,
                                    isClimateControlled: isClimateControlled,
                                    moveInDate: trackMoveIn ? moveInDate : nil,
                                    contractEndDate: trackContractEnd ? contractEndDate : nil,
                                    discountMonths: discountMonths,
                                    discountRate: discountRate,
                                    notes: unitNotes.isEmpty ? nil : unitNotes,
                                    locationOverride: created
                                )
                            }

                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Address Search Completer

class AddressSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateQuery(_ newQuery: String) {
        completer.queryFragment = newQuery
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = Array(completer.results.prefix(5))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}
