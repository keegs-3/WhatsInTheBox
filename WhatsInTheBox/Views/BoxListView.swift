import SwiftUI

struct ItemListView: View {
    @EnvironmentObject var manager: StorageManager
    let space: StorageSpace

    var body: some View {
        List {
            ForEach(manager.items) { item in
                NavigationLink(destination: BoxDetailView(item: item)) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: item.colorHex) ?? .brown)
                                .frame(width: 44, height: 44)
                            if item.category == .box {
                                Text("#\(item.boxNumber)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else {
                                Image(systemName: iconFor(item.category))
                                    .foregroundStyle(.white)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .font(.headline)
                            HStack(spacing: 12) {
                                if let w = item.weight {
                                    Label("\(String(format: "%.0f", w)) lbs", systemImage: "scalemass")
                                }
                                Label("\(String(format: "%.0f", item.width))×\(String(format: "%.0f", item.depth))×\(String(format: "%.0f", item.height))\"", systemImage: "cube")
                                if item.stackable {
                                    Image(systemName: "square.stack.3d.up")
                                        .foregroundStyle(.green)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await manager.deleteItem(manager.items[index])
                    }
                }
            }
        }
    }

    private func iconFor(_ category: ItemCategory) -> String {
        switch category {
        case .box: return "shippingbox"
        case .furniture: return "cabinet"
        case .appliance: return "washer"
        case .misc: return "archivebox"
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6 else { return nil }
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
