import SwiftUI

struct BoxListView: View {
    @EnvironmentObject var manager: StorageManager
    let space: StorageSpace

    var body: some View {
        List {
            ForEach(manager.boxes) { box in
                NavigationLink(destination: BoxDetailView(box: box)) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: box.colorHex) ?? .brown)
                                .frame(width: 44, height: 44)
                            Text("#\(box.boxNumber)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(box.label)
                                .font(.headline)
                            HStack(spacing: 12) {
                                if let w = box.weight {
                                    Label("\(String(format: "%.0f", w)) lbs", systemImage: "scalemass")
                                }
                                Label("\(String(format: "%.1f", box.width))×\(String(format: "%.1f", box.depth))×\(String(format: "%.1f", box.height))", systemImage: "cube")
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
                        await manager.deleteBox(manager.boxes[index])
                    }
                }
            }
        }
    }
}

// MARK: - Color hex helper for SwiftUI

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
