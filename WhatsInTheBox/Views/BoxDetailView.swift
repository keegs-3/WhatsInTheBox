import SwiftUI

struct BoxDetailView: View {
    @EnvironmentObject var manager: StorageManager
    @State var item: StorageItem
    @State private var showingAddContent = false
    @State private var showingLabelCreator = false
    @State private var fullness: Double = 0
    @State private var isEditing = false

    // Editable fields
    @State private var editLabel: String = ""
    @State private var editNumber: Int = 0
    @State private var editWeight: String = ""
    @State private var editNotes: String = ""

    var body: some View {
        List {
            // MARK: - Box Visual
            Section {
                BoxVisual(item: item, fullness: fullness)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // Fullness slider (boxes only)
            if item.category == .box {
                Section {
                    VStack(spacing: 8) {
                        Slider(value: $fullness, in: 0...100, step: 5)
                            .tint(fullnessColor(Int(fullness)))
                            .onChange(of: fullness) { _, newValue in
                                var updated = item
                                updated.fullnessPercent = Int(newValue)
                                item = updated
                                Task { await manager.updateItem(updated) }
                            }
                        Text("How full is this box?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Info (editable)
            Section("Info") {
                if isEditing {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Box name", text: $editLabel)
                            .multilineTextAlignment(.trailing)
                    }
                    if item.category == .box {
                        HStack {
                            Text("Number")
                            Spacer()
                            TextField("#", value: $editNumber, format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("lbs", text: $editWeight)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("Notes", text: $editNotes, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    if item.category == .box {
                        LabeledContent("Number", value: "#\(item.boxNumber)")
                    }
                    LabeledContent("Name", value: item.label)
                    LabeledContent("Category", value: item.category.rawValue.capitalized)
                    if let w = item.weight {
                        LabeledContent("Weight", value: "\(String(format: "%.1f", w)) lbs")
                    }
                    LabeledContent("Size", value: "\(String(format: "%.0f", item.width))×\(String(format: "%.0f", item.depth))×\(String(format: "%.0f", item.height))\"")
                    if item.stackable {
                        LabeledContent("Stackable", value: "Yes")
                    }
                    if let notes = item.notes, !notes.isEmpty {
                        LabeledContent("Notes", value: notes)
                    }
                    if let url = item.productUrl, !url.isEmpty, let link = URL(string: url) {
                        Link("Product Link", destination: link)
                    }
                }
            }

            // MARK: - Label
            Section {
                Button {
                    showingLabelCreator = true
                } label: {
                    Label("Create Physical Label", systemImage: "printer")
                }
            }

            // MARK: - Contents
            if item.category == .box {
                Section("Contents (\(manager.contents.count) items)") {
                    if manager.contents.isEmpty {
                        Text("No items yet — tap + to add")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.contents) { content in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(content.name)
                                    Spacer()
                                    if content.quantity > 1 {
                                        Text("×\(content.quantity)")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(.fill, in: Capsule())
                                    }
                                }
                                if let notes = content.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await manager.deleteContent(manager.contents[index])
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(item.category == .box ? (item.label.isEmpty ? "Box #\(item.boxNumber)" : item.label) : item.label)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveEdits()
                        } else {
                            startEditing()
                        }
                        isEditing.toggle()
                    }
                    if item.category == .box {
                        Button(action: { showingAddContent = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddContent) {
            AddItemView()
        }
        .sheet(isPresented: $showingLabelCreator) {
            LabelCreatorView(item: item)
        }
        .task {
            fullness = Double(item.fullnessPercent)
            await manager.loadContents(for: item)
        }
    }

    private func startEditing() {
        editLabel = item.label
        editNumber = item.boxNumber
        editWeight = item.weight.map { String(format: "%.1f", $0) } ?? ""
        editNotes = item.notes ?? ""
    }

    private func saveEdits() {
        item.label = editLabel
        item.boxNumber = editNumber
        item.weight = Float(editWeight)
        item.notes = editNotes.isEmpty ? nil : editNotes
        Task { await manager.updateItem(item) }
    }

    private func fullnessColor(_ percent: Int) -> Color {
        if percent < 50 { return .green }
        if percent < 80 { return .yellow }
        return .red
    }
}

// MARK: - Box Visual (colored top + container)

struct BoxVisual: View {
    let item: StorageItem
    let fullness: Double

    var body: some View {
        VStack(spacing: 0) {
            // Colored lid
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: item.colorHex) ?? .brown)
                .frame(height: 24)
                .overlay(alignment: .center) {
                    HStack(spacing: 6) {
                        if item.category == .box {
                            Text("#\(item.boxNumber)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                        if !item.label.isEmpty {
                            Text(item.label)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 4)

            // Box body
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(.systemGray6))
                .frame(height: 80)
                .overlay {
                    VStack(spacing: 4) {
                        // Fullness gauge
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 5)
                                .frame(width: 44, height: 44)
                            Circle()
                                .trim(from: 0, to: fullness / 100)
                                .stroke(
                                    fullnessColor(Int(fullness)),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                )
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(fullness))%")
                                .font(.system(size: 11, weight: .bold))
                        }
                        if let w = item.weight {
                            Text("\(String(format: "%.0f", w)) lbs")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if item.stackable {
                        Image(systemName: "square.stack.3d.up")
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .padding(6)
                    }
                }
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
    }

    private func fullnessColor(_ percent: Int) -> Color {
        if percent < 50 { return .green }
        if percent < 80 { return .yellow }
        return .red
    }
}

// MARK: - Label Creator

struct LabelCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    let item: StorageItem

    @State private var labelText: String = ""
    @State private var labelShape: LabelShape = .square
    @State private var labelColor: String = "#FF6600"
    @State private var labelSize: LabelSize = .medium
    @State private var useNumber = true

    enum LabelShape: String, CaseIterable {
        case circle, square, roundedSquare = "rounded"

        var displayName: String {
            switch self {
            case .circle: return "Circle"
            case .square: return "Square"
            case .roundedSquare: return "Rounded"
            }
        }
    }

    enum LabelSize: String, CaseIterable {
        case small, medium, large

        var dimension: CGFloat {
            switch self {
            case .small: return 120
            case .medium: return 180
            case .large: return 260
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 72
            }
        }
    }

    private let colors = [
        "#FF6600", "#E74C3C", "#2ECC71", "#3498DB",
        "#9B59B6", "#F39C12", "#1ABC9C", "#E91E63",
        "#000000", "#FFFFFF",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // Preview
                labelPreview
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                Spacer()

                // Controls
                VStack(spacing: 16) {
                    // Text
                    HStack {
                        Toggle("Use #", isOn: $useNumber)
                            .frame(width: 100)
                        TextField("Custom text", text: $labelText)
                            .textFieldStyle(.roundedBorder)
                            .disabled(useNumber)
                    }

                    // Shape
                    Picker("Shape", selection: $labelShape) {
                        ForEach(LabelShape.allCases, id: \.self) { shape in
                            Text(shape.displayName).tag(shape)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Size
                    Picker("Size", selection: $labelSize) {
                        ForEach(LabelSize.allCases, id: \.self) { size in
                            Text(size.rawValue.capitalized).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Colors
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(hex == "#FFFFFF" ? Color.gray : Color.clear, lineWidth: 1)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: labelColor == hex ? 3 : 0)
                                        .padding(-2)
                                )
                                .onTapGesture { labelColor = hex }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle("Label Creator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                labelText = item.label
                labelColor = item.colorHex
            }
        }
    }

    @ViewBuilder
    private var labelPreview: some View {
        let displayText = useNumber ? "#\(item.boxNumber)" : labelText
        let size = labelSize.dimension
        let bgColor = Color(hex: labelColor) ?? .orange
        let textColor: Color = (labelColor == "#FFFFFF" || labelColor == "#F39C12") ? .black : .white

        ZStack {
            switch labelShape {
            case .circle:
                Circle()
                    .fill(bgColor)
                    .frame(width: size, height: size)
            case .square:
                Rectangle()
                    .fill(bgColor)
                    .frame(width: size, height: size)
            case .roundedSquare:
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(bgColor)
                    .frame(width: size, height: size)
            }

            Text(displayText)
                .font(.system(size: labelSize.fontSize, weight: .black, design: .rounded))
                .foregroundStyle(textColor)
                .minimumScaleFactor(0.5)
                .padding(12)
        }
    }
}
