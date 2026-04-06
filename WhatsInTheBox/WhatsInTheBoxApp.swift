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
            // Content
            Group {
                switch selectedTab {
                case 0: ContentView()
                case 1: InventoryView()
                case 2: BoxesView()
                case 3: ProfileView()
                default: ContentView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            HStack(spacing: 16) {
                // Tab bubble
                HStack(spacing: 0) {
                    TabBarButton(icon: "building.2", label: "Locations", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    TabBarButton(icon: "tray.full", label: "Inventory", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    TabBarButton(icon: "shippingbox", label: "Boxes", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    TabBarButton(icon: "person.circle", label: "Profile", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())

                // FAB
                Button {
                    showQuickAdd = true
                } label: {
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
    @State private var showAddLocation = false
    @State private var showAddInventory = false
    @State private var showAddBox = false
    @State private var showAddSpace = false

    var body: some View {
        NavigationStack {
            List {
                Section("Add to Storage") {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAddLocation = true
                        }
                    } label: {
                        QuickAddRow(icon: "building.2.fill", title: "New Location",
                                    subtitle: "Storage facility, house, garage", color: .blue)
                    }

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAddSpace = true
                        }
                    } label: {
                        QuickAddRow(icon: "door.left.hand.open", title: "New Unit / Space",
                                    subtitle: "Room or storage unit in current location", color: .indigo)
                    }
                    .disabled(manager.selectedLocation == nil)
                }

                Section("Add Items") {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAddBox = true
                        }
                    } label: {
                        QuickAddRow(icon: "shippingbox.fill", title: "New Box / Container",
                                    subtitle: "Add a box to the current space", color: .orange)
                    }
                    .disabled(manager.selectedSpace == nil)

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAddInventory = true
                        }
                    } label: {
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
        }
        .sheet(isPresented: $showAddLocation) { AddLocationView() }
        .sheet(isPresented: $showAddSpace) { AddSpaceView() }
        .sheet(isPresented: $showAddBox) { AddItemToSpaceView() }
        .sheet(isPresented: $showAddInventory) { AddInventoryItemView() }
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
