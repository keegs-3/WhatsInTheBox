import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: StorageManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddLocation = false
    @State private var showingAddSpace = false
    @State private var showMenu = false

    private var groupedLocations: [(LocationType, [Location])] {
        let grouped = Dictionary(grouping: manager.locations) { $0.locationType }
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if manager.locations.isEmpty {
                        ContentUnavailableView(
                            "No Locations Yet",
                            systemImage: "building.2",
                            description: Text("Tap + to add a storage facility, house, or garage")
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(groupedLocations, id: \.0) { type, locations in
                            VStack(alignment: .leading, spacing: 10) {
                                // Section header
                                HStack {
                                    Image(systemName: type.iconName)
                                        .foregroundStyle(Color.accentColor)
                                    Text(type.displayName)
                                        .font(.headline)
                                }
                                .padding(.horizontal)

                                // 2-column grid
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(locations) { location in
                                        NavigationLink(destination: LocationDetailView(location: location)) {
                                            LocationCard(location: location, isSelected: false, spaceCount: 0)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
            .navigationTitle("Locations")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showMenu = true } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
            .sheet(isPresented: $showMenu) {
                MenuSheet()
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView()
            }
            .task {
                await manager.loadLocations()
            }
            .alert("Error", isPresented: .init(
                get: { manager.errorMessage != nil },
                set: { if !$0 { manager.errorMessage = nil } }
            )) {
                Button("OK") { manager.errorMessage = nil }
            } message: {
                Text(manager.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Location Detail (drill-down from card tap)

struct LocationDetailView: View {
    @EnvironmentObject var manager: StorageManager
    let location: Location
    @State private var showingAddSpace = false
    @State private var showingLocationInfo = false
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if manager.spaces.isEmpty {
                VStack {
                    Spacer()
                    ContentUnavailableView(
                        "No Spaces",
                        systemImage: "door.left.hand.open",
                        description: Text("Add a room or unit to get started")
                    )
                    Button("Add Space") { showingAddSpace = true }
                        .buttonStyle(.borderedProminent)
                    Spacer()
                }
            } else {
                List {
                    // Location summary
                    if let addr = location.address, !addr.isEmpty {
                        Section {
                            Label(addr, systemImage: "mappin.circle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Spaces / Units
                    Section("Spaces & Units") {
                        ForEach(manager.spaces) { space in
                            NavigationLink(destination: SpaceDetailView(space: space)) {
                                HStack(spacing: 12) {
                                    Image(systemName: space.isClimateControlled ? "snowflake" : "cube.transparent")
                                        .font(.title3)
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(space.displayName)
                                            .font(.body.weight(.medium))
                                        HStack(spacing: 8) {
                                            Text(space.sizeLabel + " ft")
                                            if let fl = space.floor { Text("Floor \(fl)") }
                                            if let rate = space.monthlyRate {
                                                Text("$\(String(format: "%.0f", rate))/mo")
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for i in indexSet { await manager.deleteSpace(manager.spaces[i]) }
                            }
                        }
                    }

                    // Facility info
                    if location.phone != nil || location.accessHours != nil || location.websiteUrl != nil {
                        Section("Facility Info") {
                            if let phone = location.phone, !phone.isEmpty {
                                Link(destination: URL(string: "tel:\(phone)")!) {
                                    LabeledContent("Phone", value: phone)
                                }
                            }
                            if let hours = location.accessHours, !hours.isEmpty {
                                LabeledContent("Access Hours", value: hours)
                            }
                            if let hours = location.officeHours, !hours.isEmpty {
                                LabeledContent("Office Hours", value: hours)
                            }
                            if let url = location.websiteUrl, !url.isEmpty, let link = URL(string: url) {
                                Link("Website", destination: link)
                            }
                        }
                    }

                    // Danger zone
                    Section {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete Location", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(location.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSpace = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSpace) { AddSpaceView() }
        .confirmationDialog("Delete \(location.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await manager.deleteLocation(location) }
            }
        } message: {
            Text("This will delete all units and items inside.")
        }
        .task {
            await manager.selectLocation(location)
        }
    }
}

// MARK: - Menu Sheet (hamburger menu)

struct MenuSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let family = authManager.currentFamily {
                    Section("Family") {
                        LabeledContent("Name", value: family.name)
                        HStack {
                            LabeledContent("Invite Code", value: family.inviteCode)
                            Button {
                                UIPasteboard.general.string = family.inviteCode
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section("Account") {
                    Button(role: .destructive) {
                        Task {
                            await authManager.signOut()
                            dismiss()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Location Card

struct LocationCard: View {
    let location: Location
    let isSelected: Bool
    let spaceCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: location.displayIcon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(location.name)
                .font(.subheadline.bold())
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let addr = location.address, !addr.isEmpty {
                Text(addr)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Space Card (kept for potential grid use)

struct SpaceCard: View {
    let space: StorageSpace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: space.isClimateControlled ? "snowflake" : "cube.transparent")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                if let rate = space.monthlyRate {
                    Text("$\(String(format: "%.0f", rate))/mo")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                }
            }
            Text(space.displayName).font(.headline).lineLimit(1)
            HStack(spacing: 8) {
                Text(space.sizeLabel + " ft").font(.caption).foregroundStyle(.secondary)
                if let fl = space.floor {
                    Text("Floor \(fl)").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
