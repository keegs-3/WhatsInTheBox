import SwiftUI

@main
struct WhatsInTheBoxApp: App {
    @StateObject private var storageManager = StorageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storageManager)
        }
    }
}
