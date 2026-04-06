import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: StorageManager
    @State private var showingAddLocation = false
    @State private var showingAddSpace = false
    @State private var showingLocationDetail = false
    @State private var confirmDeleteLocation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                locationsContent
            }
            .navigationTitle("What's In The Box?")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if manager.selectedLocation != nil {
                        Menu {
                            Button { showingLocationDetail = true } label: {
                                Label("Location Info", systemImage: "info.circle")
                            }
                            Button(role: .destructive) { confirmDeleteLocation = true } label: {
                                Label("Delete Location", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddLocation) { AddLocationView() }
            .sheet(isPresented: $showingAddSpace) { AddSpaceView() }
            .sheet(isPresented: $showingLocationDetail) {
                if let location = manager.selectedLocation {
                    LocationDetailSheet(location: location)
                }
            }
            .confirmationDialog(
                "Delete \(manager.selectedLocation?.name ?? "location")?",
                isPresented: $confirmDeleteLocation, titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let loc = manager.selectedLocation {
                        Task { await manager.deleteLocation(loc) }
                    }
                }
            } message: {
                Text("This will also delete all units and items inside.")
            }
            .task { await manager.loadLocations() }
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

    // MARK: - Locations Tab Content

    @ViewBuilder
    private var locationsContent: some View {
        if manager.locations.isEmpty {
            Spacer()
            ContentUnavailableView(
                "No Locations Yet",
                systemImage: "building.2",
                description: Text("Add a location to get started")
            )
            Button("Add Location") { showingAddLocation = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        } else {
            // Location cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(manager.locations) { location in
                        LocationCard(
                            location: location,
                            isSelected: manager.selectedLocation?.id == location.id,
                            spaceCount: location.id == manager.selectedLocation?.id ? manager.spaces.count : 0
                        )
                        .onTapGesture {
                            Task { await manager.selectLocation(location) }
                        }
                        .contextMenu {
                            Button {
                                Task { await manager.selectLocation(location) }
                                showingLocationDetail = true
                            } label: { Label("Location Info", systemImage: "info.circle") }
                            Divider()
                            Button(role: .destructive) {
                                Task { await manager.selectLocation(location) }
                                confirmDeleteLocation = true
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                    Button { showingAddLocation = true } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill").font(.title2)
                            Text("Add Location").font(.caption2)
                        }
                        .frame(width: 140, height: 90)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            Divider()

            // Spaces for selected location
            if manager.spaces.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Spaces",
                    systemImage: "door.left.hand.open",
                    description: Text("Add a room or unit to \(manager.selectedLocation?.name ?? "this location")")
                )
                Button("Add Space") { showingAddSpace = true }
                    .buttonStyle(.borderedProminent)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(manager.spaces) { space in
                            NavigationLink(destination: SpaceDetailView(space: space)) {
                                SpaceCard(space: space)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await manager.deleteSpace(space) }
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                    .padding()
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: location.displayIcon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : Color.accentColor)
                Spacer()
            }
            Spacer()
            Text(location.name)
                .font(.caption.bold())
                .lineLimit(1)
            Text(location.locationType.displayName)
                .font(.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
        }
        .padding(12)
        .frame(width: 140, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
        )
        .foregroundStyle(isSelected ? .white : .primary)
    }
}

// MARK: - Space Card

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

// MARK: - Location Detail Sheet

struct LocationDetailSheet: View {
    @EnvironmentObject var manager: StorageManager
    @Environment(\.dismiss) private var dismiss
    let location: Location

    var body: some View {
        NavigationStack {
            List {
                Section("Location") {
                    LabeledContent("Name", value: location.name)
                    LabeledContent("Type", value: location.locationType.displayName)
                    if let addr = location.address, !addr.isEmpty {
                        LabeledContent("Address", value: addr)
                    }
                }
                if location.phone != nil || location.websiteUrl != nil || location.accessHours != nil {
                    Section("Facility Info") {
                        if let phone = location.phone, !phone.isEmpty {
                            Link(destination: URL(string: "tel:\(phone)")!) {
                                LabeledContent("Phone", value: phone)
                            }
                        }
                        if let url = location.websiteUrl, !url.isEmpty, let link = URL(string: url) {
                            Link("Website", destination: link)
                        }
                        if let hours = location.accessHours, !hours.isEmpty {
                            LabeledContent("Access Hours", value: hours)
                        }
                        if let hours = location.officeHours, !hours.isEmpty {
                            LabeledContent("Office Hours", value: hours)
                        }
                    }
                }
                Section("Units (\(manager.spaces.count))") {
                    if manager.spaces.isEmpty {
                        Text("No units yet").foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.spaces) { space in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(space.displayName)
                                    Text(space.sizeLabel + " ft").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let rate = space.monthlyRate {
                                    Text("$\(String(format: "%.0f", rate))/mo").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(location.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
