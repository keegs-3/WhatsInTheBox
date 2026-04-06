import SwiftUI

@main
struct WhatsInTheBoxApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var storageManager = StorageManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    ProgressView("Loading…")
                } else if !authManager.isAuthenticated {
                    AuthView()
                } else if authManager.currentFamily == nil {
                    FamilySetupView()
                } else {
                    MainTabView()
                        .environmentObject(storageManager)
                        .onAppear {
                            storageManager.familyId = authManager.currentFamily?.id
                        }
                }
            }
            .environmentObject(authManager)
        }
    }
}

// MARK: - Main Tab View with Custom Tab Bar + FAB

struct MainTabView: View {
    @EnvironmentObject var manager: StorageManager
    @State private var selectedTab = 0
    @State private var showQuickAdd = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: ContentView()
                case 1: InventoryView()
                case 2: BoxesView()
                default: ContentView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 70) // Space for tab bar

            // Tab bar + FAB
            HStack(spacing: 16) {
                HStack(spacing: 0) {
                    TabBarButton(icon: "building.2", label: "Locations", isSelected: selectedTab == 0) { selectedTab = 0 }
                    TabBarButton(icon: "tray.full", label: "Inventory", isSelected: selectedTab == 1) { selectedTab = 1 }
                    TabBarButton(icon: "shippingbox", label: "Boxes", isSelected: selectedTab == 2) { selectedTab = 2 }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())

                Button { showQuickAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor, in: Circle())
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 8, y: 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddSheet()
        }
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            .frame(width: 70, height: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Add Sheet

struct QuickAddSheet: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss
    @State private var destination: QuickAddDestination?

    enum QuickAddDestination: Identifiable {
        case location, space, box, inventory
        var id: Self { self }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Add to Storage") {
                    Button { destination = .location } label: {
                        QuickAddRow(icon: "building.2.fill", title: "New Location",
                                    subtitle: "Storage facility, house, garage", color: .blue)
                    }

                    Button { destination = .space } label: {
                        QuickAddRow(icon: "door.left.hand.open", title: "New Unit / Space",
                                    subtitle: "Room or storage unit in current location", color: .indigo)
                    }
                    .disabled(manager.selectedLocation == nil)
                }

                Section("Add Items") {
                    Button { destination = .box } label: {
                        QuickAddRow(icon: "shippingbox.fill", title: "New Box / Container",
                                    subtitle: "Create a box (assign to space later)", color: .orange)
                    }

                    Button { destination = .inventory } label: {
                        QuickAddRow(icon: "tray.and.arrow.down.fill", title: "New Inventory Item",
                                    subtitle: "Add an item to your inventory", color: .green)
                    }
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(item: $destination) { dest in
                switch dest {
                case .location: AddLocationView()
                case .space: AddSpaceView()
                case .box: AddBoxStandaloneView()
                case .inventory: AddInventoryItemView()
                }
            }
        }
    }
}

// MARK: - Add Box (standalone, not tied to a space)

struct AddBoxStandaloneView: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ItemCategory = .box
    @State private var selectedType: ItemType?
    @State private var weight: Float?
    @State private var width: Float = 18
    @State private var height: Float = 18
    @State private var depth: Float = 16
    @State private var stackable = false
    @State private var lidColor = "#FF6600"
    @State private var bodyColor = ""
    @State private var notes = ""

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
                Section("Type") {
                    Picker("Category", selection: $category) {
                        Text("Box").tag(ItemCategory.box)
                        Text("Tote").tag(ItemCategory.tote)
                    }
                    .pickerStyle(.segmented)
                }

                if !filteredTypes.isEmpty {
                    Section("Preset") {
                        Picker("Select", selection: $selectedType) {
                            Text("Custom").tag(nil as ItemType?)
                            ForEach(filteredTypes) { type in
                                Text(type.displayName).tag(type as ItemType?)
                            }
                        }
                        .onChange(of: selectedType) { _, t in
                            if let t {
                                width = t.width; height = t.height; depth = t.depth
                                stackable = t.stackable
                                if let c = t.colorHex { lidColor = c }
                                if name.isEmpty { name = t.displayName }
                            }
                        }
                    }
                }

                Section("Info") {
                    TextField("Name (e.g. \"Kitchen #1\")", text: $name)
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("lbs", value: $weight, format: .number)
                            .keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing)
                    }
                    Toggle("Stackable", isOn: $stackable)
                }

                Section("Dimensions (inches)") {
                    HStack { Text("Width"); Spacer(); TextField("W", value: $width, format: .number).keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing) }
                    HStack { Text("Height"); Spacer(); TextField("H", value: $height, format: .number).keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing) }
                    HStack { Text("Depth"); Spacer(); TextField("D", value: $depth, format: .number).keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing) }
                }

                Section("Lid Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(boxColors, id: \.self) { hex in
                            Circle().fill(Color(hex: hex) ?? .brown).frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.primary, lineWidth: lidColor == hex ? 3 : 0))
                                .onTapGesture { lidColor = hex }
                        }
                    }
                }

                Section("Body Color") {
                    Picker("Body", selection: $bodyColor) {
                        Text("Same as Lid").tag("")
                        Text("Clear / Transparent").tag("clear")
                        Text("Black").tag("#1C1C1E")
                        Text("White").tag("#FFFFFF")
                        Text("Brown (Cardboard)").tag("#8B6914")
                    }
                }
            }
            .navigationTitle("New Box")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await manager.addBox(
                                name: name.isEmpty ? (selectedType?.displayName ?? "Box") : name,
                                category: category,
                                width: width, height: height, depth: depth,
                                weight: weight, stackable: stackable,
                                colorHex: lidColor,
                                bodyColorHex: bodyColor.isEmpty ? nil : bodyColor,
                                itemTypeId: selectedType?.id
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty && selectedType == nil)
                }
            }
            .task { await manager.loadItemTypes() }
        }
    }
}

struct QuickAddRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Boxes View

struct BoxesView: View {
    @EnvironmentObject var manager: StorageManager

    var body: some View {
        NavigationStack {
            Group {
                if manager.allBoxes.isEmpty {
                    ContentUnavailableView(
                        "No Boxes Yet",
                        systemImage: "shippingbox",
                        description: Text("Add boxes to your spaces and they'll appear here")
                    )
                } else {
                    List {
                        ForEach(manager.allBoxes) { box in
                            NavigationLink(destination: BoxDetailView(item: box)) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: box.colorHex ?? "#8B6914") ?? .brown)
                                            .frame(width: 44, height: 44)
                                        if let num = box.boxNumber {
                                            Text("#\(num)")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(box.name).font(.body.weight(.medium))
                                        HStack(spacing: 8) {
                                            if let w = box.weight {
                                                Text("\(String(format: "%.0f", w)) lbs")
                                            }
                                            Text("\(box.fullnessPct ?? 0)% full")
                                        }
                                        .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Boxes")
            .task { await manager.loadAllBoxes() }
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            List {
                if let family = authManager.currentFamily {
                    Section("Family") {
                        LabeledContent("Name", value: family.name)
                        LabeledContent("Invite Code", value: family.inviteCode)
                    }
                }
                Section {
                    Button(role: .destructive) {
                        Task { await authManager.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
