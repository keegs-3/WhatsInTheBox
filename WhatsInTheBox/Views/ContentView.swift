import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: StorageManager
    @State private var showingAddSpace = false

    var body: some View {
        NavigationStack {
            Group {
                if manager.isLoading && manager.spaces.isEmpty {
                    ProgressView("Loading…")
                } else if manager.spaces.isEmpty {
                    ContentUnavailableView(
                        "No Storage Spaces",
                        systemImage: "shippingbox",
                        description: Text("Tap + to create your first storage space")
                    )
                } else {
                    List {
                        ForEach(manager.spaces) { space in
                            NavigationLink(destination: SpaceDetailView(space: space)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(space.name)
                                        .font(.headline)
                                    Text("\(String(format: "%.0f", space.width))×\(String(format: "%.0f", space.depth))×\(String(format: "%.0f", space.height)) ft")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await manager.deleteSpace(manager.spaces[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("What's In The Box?")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSpace = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSpace) {
                AddSpaceView()
            }
            .task {
                await manager.loadSpaces()
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
