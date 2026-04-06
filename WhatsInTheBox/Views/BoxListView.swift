import SwiftUI

struct ItemListView: View {
    @EnvironmentObject var manager: StorageManager
    let space: StorageSpace

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(manager.items) { item in
                    NavigationLink(destination: BoxDetailView(item: item)) {
                        ItemCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { await manager.deleteItem(item) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

// MARK: - Item Card (HomeKit-style tile)

struct ItemCard: View {
    let item: StorageItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Color strip + icon
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: item.colorHex) ?? .brown)
                        .frame(width: 36, height: 36)
                    if item.category == .box {
                        Text("#\(item.boxNumber)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: iconFor(item.category))
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                if item.stackable {
                    Image(systemName: "square.stack.3d.up")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Text(item.label)
                .font(.caption.bold())
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Weight badge
            if let w = item.weight {
                Label("\(String(format: "%.0f", w)) lbs", systemImage: "scalemass")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Fullness bar (boxes only)
            if item.category == .box {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(item.fullnessPercent)% full")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray5))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(fullnessColor(item.fullnessPercent))
                                .frame(width: geo.size.width * CGFloat(item.fullnessPercent) / 100, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func iconFor(_ category: ItemCategory) -> String {
        switch category {
        case .box: return "shippingbox"
        case .furniture: return "cabinet"
        case .appliance: return "washer"
        case .misc: return "archivebox"
        }
    }

    private func fullnessColor(_ percent: Int) -> Color {
        if percent < 50 { return .green }
        if percent < 80 { return .yellow }
        return .red
    }
}

// MARK: - Color hex helper

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
