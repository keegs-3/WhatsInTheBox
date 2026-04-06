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
                            VStack(alignment: .leading, spacing: 12) {
                                // Section header
                                Text(type.displayName.uppercased())
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)

                                // Full-width cards
                                ForEach(locations) { location in
                                    NavigationLink(destination: LocationDetailView(location: location)) {
                                        LocationCard(location: location)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                }
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
            .background(Color(.systemGroupedBackground))
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
    @State private var confirmDelete = false
    @State private var showingEditLocation = false

    var body: some View {
        List {
            // Location info
            if let addr = location.address, !addr.isEmpty {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin")
                            .foregroundStyle(.secondary)
                        Text(addr)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Spaces / Units
            Section {
                if manager.spaces.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "door.left.hand.open")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Text("No spaces yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("Add Space") { showingAddSpace = true }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                } else {
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
            } header: {
                Text("Spaces & Units")
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

            Section {
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete Location", systemImage: "trash")
                }
            }
        }
        .navigationTitle(location.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button { showingAddSpace = true } label: {
                        Image(systemName: "plus")
                    }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(alignment: .top) {
                Image(systemName: location.displayIcon)
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.headline)
                    Text(location.locationType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            // Details
            if let addr = location.address, !addr.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(addr)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            // Bottom row: quick stats
            HStack(spacing: 16) {
                if let phone = location.phone, !phone.isEmpty {
                    Label(phone, systemImage: "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let hours = location.accessHours, !hours.isEmpty {
                    Label(hours, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
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
