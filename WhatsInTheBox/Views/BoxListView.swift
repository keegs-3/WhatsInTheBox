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

struct ItemCard: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: item.colorHex ?? "#8B6914") ?? .brown)
                        .frame(width: 36, height: 36)
                    if let num = item.boxNumber {
                        Text("#\(num)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: item.icon ?? item.category.iconName)
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                if item.stackable == true {
                    Image(systemName: "square.stack.3d.up")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Text(item.name)
                .font(.caption.bold())
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let w = item.weight {
                Label("\(String(format: "%.0f", w)) lbs", systemImage: "scalemass")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if item.isContainer {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(item.fullnessPct ?? 0)% full")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray5))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(fullnessColor(item.fullnessPct ?? 0))
                                .frame(width: geo.size.width * CGFloat(item.fullnessPct ?? 0) / 100, height: 4)
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

    private func fullnessColor(_ percent: Int) -> Color {
        if percent < 50 { return .green }
        if percent < 80 { return .yellow }
        return .red
    }
}

