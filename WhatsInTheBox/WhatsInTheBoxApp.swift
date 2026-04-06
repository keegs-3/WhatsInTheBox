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
                    ContentView()
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
