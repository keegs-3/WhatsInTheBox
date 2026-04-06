import SwiftUI

struct SFSymbolPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSymbol: String?
    @State private var searchText = ""
    @State private var customName = ""

    private var filteredGroups: [(String, [String])] {
        if searchText.isEmpty { return Self.symbolGroups }
        return Self.symbolGroups.compactMap { group, symbols in
            let filtered = symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
            return filtered.isEmpty ? nil : (group, filtered)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // Custom entry
                    Section {
                        HStack {
                            TextField("Custom SF Symbol name", text: $customName)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            if !customName.isEmpty {
                                Button("Use") {
                                    selectedSymbol = customName
                                    dismiss()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(.horizontal)

                    ForEach(filteredGroups, id: \.0) { group, symbols in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                ForEach(symbols, id: \.self) { name in
                                    Button {
                                        selectedSymbol = name
                                        dismiss()
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: name)
                                                .font(.title3)
                                                .frame(height: 28)
                                            Text(name.split(separator: ".").last.map(String.init) ?? name)
                                                .font(.system(size: 8))
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedSymbol == name ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemGroupedBackground),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .searchable(text: $searchText, prompt: "Search symbols...")
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if selectedSymbol != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Clear") {
                            selectedSymbol = nil
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    static let symbolGroups: [(String, [String])] = [
        ("Kitchen", [
            "cup.and.saucer.fill", "fork.knife", "refrigerator.fill",
            "oven.fill", "frying.pan.fill", "wineglass.fill",
            "mug.fill", "waterbottle.fill", "takeoutbag.and.cup.and.straw.fill"
        ]),
        ("Electronics", [
            "tv.fill", "laptopcomputer", "desktopcomputer",
            "headphones", "gamecontroller.fill", "cable.connector",
            "battery.100percent", "printer.fill", "wifi.router.fill",
            "camera.fill", "video.fill", "speaker.wave.3.fill"
        ]),
        ("Clothing & Shoes", [
            "tshirt.fill", "shoe.fill", "hanger",
            "eyeglasses", "bag.fill", "backpack.fill"
        ]),
        ("Books & Documents", [
            "book.fill", "books.vertical.fill", "doc.fill",
            "folder.fill", "newspaper.fill", "magazine.fill",
            "photo.fill", "paintpalette.fill"
        ]),
        ("Tools & Hardware", [
            "wrench.fill", "hammer.fill", "screwdriver.fill",
            "scissors", "paintbrush.fill", "ruler.fill",
            "level.fill", "flashlight.on.fill"
        ]),
        ("Sports & Outdoors", [
            "figure.hiking", "bicycle", "tennisball.fill",
            "soccerball", "football.fill", "basketball.fill",
            "dumbbell.fill", "figure.run", "tent.fill",
            "binoculars.fill", "surfboard.fill"
        ]),
        ("Containers & Storage", [
            "shippingbox.fill", "archivebox.fill", "tray.full.fill",
            "bag.fill", "suitcase.fill", "basket.fill",
            "cart.fill"
        ]),
        ("Furniture", [
            "bed.double.fill", "sofa.fill", "chair.fill",
            "table.furniture.fill", "lamp.desk.fill",
            "cabinet.fill", "bathtub.fill", "toilet.fill",
            "fan.desk.fill", "chandelier.fill"
        ]),
        ("Holiday & Seasonal", [
            "gift.fill", "balloon.2.fill", "party.popper.fill",
            "tree.fill", "snowflake", "sun.max.fill",
            "leaf.fill", "flame.fill"
        ]),
        ("Personal & Bathroom", [
            "comb.fill", "mouth.fill", "pills.fill",
            "cross.case.fill", "stethoscope", "bandage.fill",
            "drop.fill", "shower.fill"
        ]),
        ("Baby & Kids", [
            "stroller.fill", "teddybear.fill",
            "figure.and.child.holdinghands", "puzzlepiece.fill"
        ]),
        ("Pets", [
            "pawprint.fill", "cat.fill", "dog.fill",
            "fish.fill", "bird.fill"
        ]),
        ("Music", [
            "pianokeys", "guitars.fill", "music.note",
            "music.mic", "headphones.circle.fill"
        ]),
        ("Office", [
            "paperclip", "stapler.fill", "pencil",
            "envelope.fill", "phone.fill", "clock.fill",
            "calendar", "trash.fill"
        ]),
        ("Misc", [
            "star.fill", "heart.fill", "flag.fill",
            "bell.fill", "tag.fill", "pin.fill",
            "key.fill", "lock.fill", "lightbulb.fill",
            "bolt.fill", "globe.americas.fill"
        ]),
    ]
}
