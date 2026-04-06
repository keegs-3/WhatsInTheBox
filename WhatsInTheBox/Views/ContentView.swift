import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: StorageManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddLocation = false
    @State private var showingAddSpace = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Location Cards (horizontal scroll)
                if !manager.locations.isEmpty {
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
                                    Button(role: .destructive) {
                                        Task { await manager.deleteLocation(location) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }

                            // Add location card
                            Button { showingAddLocation = true } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Add Location")
                                        .font(.caption2)
                                }
                                .frame(width: 140, height: 90)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }

                Divider()

                // MARK: - Spaces Grid
                if manager.locations.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Locations Yet",
                        systemImage: "building.2",
                        description: Text("Add a location to get started — a storage facility, house, garage, etc.")
                    )
                    Button("Add Location") { showingAddLocation = true }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    Spacer()
                } else if manager.spaces.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Spaces",
                        systemImage: "door.left.hand.open",
                        description: Text("Add a room or unit to \(manager.selectedLocation?.name ?? "this location")")
                    )
                    Button("Add Space") { showingAddSpace = true }
                        .buttonStyle(.borderedProminent)
                        .padding()
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
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("What's In The Box?")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showingAddSpace = true } label: {
                            Label("New Space", systemImage: "door.left.hand.open")
                        }
                        .disabled(manager.selectedLocation == nil)
                        Button { showingAddLocation = true } label: {
                            Label("New Location", systemImage: "building.2")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        if let family = authManager.currentFamily {
                            Section {
                                Label(family.name, systemImage: "person.2")
                                Text("Invite code: \(family.inviteCode)")
                            }
                        }
                        Button(role: .destructive) {
                            Task { await authManager.signOut() }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView()
            }
            .sheet(isPresented: $showingAddSpace) {
                AddSpaceView()
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
            if let unit = location.unitNumber, !unit.isEmpty {
                Text("Unit \(unit)")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            }
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
            Image(systemName: "cube.transparent")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            Text(space.name)
                .font(.headline)
                .lineLimit(1)

            Text("\(String(format: "%.0f", space.width))×\(String(format: "%.0f", space.depth))×\(String(format: "%.0f", space.height)) ft")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
