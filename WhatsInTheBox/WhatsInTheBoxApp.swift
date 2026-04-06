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

// MARK: - Bottom Tab Bar

struct MainTabView: View {
    @EnvironmentObject var manager: StorageManager

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Locations", systemImage: "building.2")
                }

            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "tray.full")
                }

            BoxesView()
                .tabItem {
                    Label("Boxes", systemImage: "shippingbox")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

// MARK: - Boxes View (all containers across all spaces)

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
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Boxes")
            .task {
                await manager.loadAllBoxes()
            }
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
