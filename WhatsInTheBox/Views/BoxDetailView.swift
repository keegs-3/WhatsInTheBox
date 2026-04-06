import SwiftUI

struct BoxDetailView: View {
    @EnvironmentObject var manager: StorageManager
    @State var item: Item
    @State private var showingAddChild = false
    @State private var showingLabelCreator = false
    @State private var fullness: Double = 0
    @State private var isEditing = false

    // Editable fields
    @State private var editName = ""
    @State private var editNumber: Int = 0
    @State private var editWeight = ""
    @State private var editNotes = ""
    @State private var editWidth = ""
    @State private var editHeight = ""
    @State private var editDepth = ""
    @State private var editStackable = false
    @State private var editLidColor = "#FF6600"
    @State private var editBodyColor = ""

    private let boxColors = [
        "#8B6914", "#D2691E", "#FF6600", "#4A90D9",
        "#2ECC71", "#E74C3C", "#9B59B6", "#F39C12",
        "#1ABC9C", "#1A5276", "#6B3A2A", "#C4A35A",
    ]

    private var totalWeight: Float {
        let base = item.weight ?? 0
        let childWeight = manager.children.compactMap(\.weight).reduce(0, +)
        return base + childWeight
    }

    var body: some View {
        List {
            // Box Visual
            if item.isContainer {
                Section {
                    BoxVisual(item: item, fullness: fullness, totalWeight: totalWeight)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    VStack(spacing: 8) {
                        Slider(value: $fullness, in: 0...100, step: 5)
                            .tint(fullnessColor(Int(fullness)))
                            .onChange(of: fullness) { _, newValue in
                                var updated = item
                                updated.fullnessPct = Int(newValue)
                                item = updated
                                Task { await manager.updateItem(updated) }
                            }
                        Text("How full is this box?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Info
            Section("Info") {
                if isEditing {
                    TextField("Name", text: $editName)
                    if item.isContainer {
                        HStack { Text("Number"); Spacer()
                            TextField("#", value: $editNumber, format: .number)
                                .keyboardType(.numberPad).frame(width: 60).multilineTextAlignment(.trailing) }
                    }
                    HStack { Text("Weight (lbs)"); Spacer()
                        TextField("lbs", text: $editWeight)
                            .keyboardType(.decimalPad).frame(width: 80).multilineTextAlignment(.trailing) }
                    HStack { Text("Width (in)"); Spacer()
                        TextField("W", text: $editWidth)
                            .keyboardType(.decimalPad).frame(width: 60).multilineTextAlignment(.trailing) }
                    HStack { Text("Height (in)"); Spacer()
                        TextField("H", text: $editHeight)
                            .keyboardType(.decimalPad).frame(width: 60).multilineTextAlignment(.trailing) }
                    HStack { Text("Depth (in)"); Spacer()
                        TextField("D", text: $editDepth)
                            .keyboardType(.decimalPad).frame(width: 60).multilineTextAlignment(.trailing) }
                    Toggle("Stackable", isOn: $editStackable)
                    TextField("Notes", text: $editNotes, axis: .vertical).lineLimit(2...4)
                } else {
                    if let num = item.boxNumber { LabeledContent("Number", value: "#\(num)") }
                    LabeledContent("Name", value: item.name)
                    LabeledContent("Category", value: item.category.displayName)
                    LabeledContent("Own Weight", value: item.weight.map { "\(String(format: "%.1f", $0)) lbs" } ?? "—")
                    if totalWeight > 0 && !manager.children.isEmpty {
                        LabeledContent("Total Weight", value: "\(String(format: "%.1f", totalWeight)) lbs")
                            .foregroundStyle(.blue)
                    }
                    if let w = item.width, let d = item.depth, let h = item.height {
                        LabeledContent("Size", value: "\(String(format: "%.0f", w))×\(String(format: "%.0f", d))×\(String(format: "%.0f", h))\"")
                    }
                    if item.stackable == true { LabeledContent("Stackable", value: "Yes") }
                    if item.isBreakable == true { LabeledContent("Breakable", value: "Yes") }
                    if item.isWrapped == true {
                        LabeledContent("Wrapped", value: item.wrappingMaterial ?? "Yes")
                    }
                    if let notes = item.notes, !notes.isEmpty { LabeledContent("Notes", value: notes) }
                    if let url = item.productUrl, !url.isEmpty, let link = URL(string: url) {
                        Link("Product Link", destination: link)
                    }
                }
            }

            // Colors (edit mode)
            if isEditing && item.isContainer {
                Section("Lid Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(boxColors, id: \.self) { hex in
                            Circle().fill(Color(hex: hex) ?? .brown).frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.primary, lineWidth: editLidColor == hex ? 3 : 0))
                                .onTapGesture { editLidColor = hex }
                        }
                    }
                }
                Section("Body Color") {
                    Picker("Body", selection: $editBodyColor) {
                        Text("Same as Lid").tag("")
                        Text("Clear / Transparent").tag("clear")
                        Text("Black").tag("#1C1C1E")
                        Text("White").tag("#FFFFFF")
                        Text("Brown").tag("#8B6914")
                    }
                }
            }

            // Label
            if item.isContainer {
                Section {
                    Button { showingLabelCreator = true } label: {
                        Label("Create Physical Label", systemImage: "printer")
                    }
                }
            }

            // Contents
            if item.isContainer {
                Section("Contents (\(manager.children.count) items)") {
                    if manager.children.isEmpty {
                        Text("No items yet — tap + to add")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.children) { child in
                            if child.isContainer {
                                NavigationLink(destination: BoxDetailView(item: child)) {
                                    childRow(child)
                                }
                            } else {
                                childRow(child)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await manager.deleteChild(manager.children[index])
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(item.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing { saveEdits() } else { startEditing() }
                        isEditing.toggle()
                    }
                    if item.isContainer {
                        Button(action: { showingAddChild = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddChild) {
            AddChildView(parentId: item.id)
        }
        .sheet(isPresented: $showingLabelCreator) {
            LabelCreatorView(item: item)
        }
        .task {
            fullness = Double(item.fullnessPct ?? 0)
            await manager.loadChildren(for: item)
        }
    }

    @ViewBuilder
    private func childRow(_ child: Item) -> some View {
        HStack {
            if let icon = child.icon {
                Image(systemName: icon).foregroundStyle(.secondary).frame(width: 24)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(child.name)
                    if child.isContainer {
                        Image(systemName: "shippingbox").font(.caption2).foregroundStyle(.orange)
                    }
                    Spacer()
                    if child.quantity > 1 {
                        Text("×\(child.quantity)")
                            .font(.caption).padding(.horizontal, 8).padding(.vertical, 2)
                            .background(.fill, in: Capsule())
                    }
                }
                HStack(spacing: 8) {
                    if let w = child.weight {
                        Text("\(String(format: "%.1f", w)) lbs").font(.caption2).foregroundStyle(.secondary)
                    }
                    if child.isBreakable == true {
                        Label("Fragile", systemImage: "exclamationmark.triangle").font(.caption2).foregroundStyle(.red)
                    }
                    if child.isWrapped == true {
                        Label("Wrapped", systemImage: "checkmark.shield").font(.caption2).foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func startEditing() {
        editName = item.name
        editNumber = item.boxNumber ?? 0
        editWeight = item.weight.map { String(format: "%.1f", $0) } ?? ""
        editNotes = item.notes ?? ""
        editWidth = item.width.map { String(format: "%.0f", $0) } ?? ""
        editHeight = item.height.map { String(format: "%.0f", $0) } ?? ""
        editDepth = item.depth.map { String(format: "%.0f", $0) } ?? ""
        editStackable = item.stackable ?? false
        editLidColor = item.colorHex ?? "#FF6600"
        editBodyColor = item.bodyColorHex ?? ""
    }

    private func saveEdits() {
        item.name = editName
        item.boxNumber = editNumber
        item.weight = Float(editWeight)
        item.notes = editNotes.isEmpty ? nil : editNotes
        item.width = Float(editWidth)
        item.height = Float(editHeight)
        item.depth = Float(editDepth)
        item.stackable = editStackable
        item.colorHex = editLidColor
        item.bodyColorHex = editBodyColor.isEmpty ? nil : editBodyColor
        Task { await manager.updateItem(item) }
    }

    private func fullnessColor(_ percent: Int) -> Color {
        if percent < 50 { return .green }
        if percent < 80 { return .yellow }
        return .red
    }
}

// MARK: - Box Visual

struct BoxVisual: View {
    let item: Item
    let fullness: Double
    let totalWeight: Float

    private var bodyFill: Color {
        let raw = item.bodyColorHex ?? ""
        if raw.lowercased() == "clear" { return Color(.systemGray6).opacity(0.3) }
        return Color(hex: raw) ?? Color(.systemGray6)
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: item.colorHex ?? "#8B6914") ?? .brown)
                .frame(height: 24)
                .overlay {
                    HStack(spacing: 6) {
                        if let num = item.boxNumber { Text("#\(num)").font(.caption.bold()).foregroundStyle(.white) }
                        Text(item.name).font(.caption).foregroundStyle(.white.opacity(0.9)).lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(bodyFill)
                .frame(height: 80)
                .overlay {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().stroke(Color(.systemGray4), lineWidth: 5).frame(width: 44, height: 44)
                            Circle().trim(from: 0, to: fullness / 100)
                                .stroke(fullnessColor(Int(fullness)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .frame(width: 44, height: 44).rotationEffect(.degrees(-90))
                            Text("\(Int(fullness))%").font(.system(size: 11, weight: .bold))
                        }
                        if totalWeight > 0 {
                            Text("\(String(format: "%.0f", totalWeight)) lbs").font(.system(size: 10)).foregroundStyle(.secondary)
                        }
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
    let item: Item
    @State private var labelText = ""
    @State private var labelShape: LabelShape = .roundedSquare
    @State private var labelColor = "#FF6600"
    @State private var labelSize: LabelSize = .medium
    @State private var useNumber = true

    enum LabelShape: String, CaseIterable {
        case circle, square, roundedSquare = "rounded"
        var displayName: String {
            switch self { case .circle: return "Circle"; case .square: return "Square"; case .roundedSquare: return "Rounded" }
        }
    }
    enum LabelSize: String, CaseIterable {
        case small, medium, large
        var dimension: CGFloat { switch self { case .small: return 120; case .medium: return 180; case .large: return 260 } }
        var fontSize: CGFloat { switch self { case .small: return 32; case .medium: return 48; case .large: return 72 } }
    }

    private let colors = ["#FF6600","#E74C3C","#2ECC71","#3498DB","#9B59B6","#F39C12","#1ABC9C","#E91E63","#000000","#FFFFFF"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                labelPreview.shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                Spacer()
                VStack(spacing: 16) {
                    HStack {
                        Toggle("Use #", isOn: $useNumber).frame(width: 100)
                        TextField("Custom text", text: $labelText).textFieldStyle(.roundedBorder).disabled(useNumber)
                    }
                    Picker("Shape", selection: $labelShape) {
                        ForEach(LabelShape.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }.pickerStyle(.segmented)
                    Picker("Size", selection: $labelSize) {
                        ForEach(LabelSize.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }.pickerStyle(.segmented)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Circle().fill(Color(hex: hex) ?? .gray).frame(width: 36, height: 36)
                                .overlay(Circle().stroke(hex == "#FFFFFF" ? Color.gray : .clear, lineWidth: 1))
                                .overlay(Circle().stroke(Color.primary, lineWidth: labelColor == hex ? 3 : 0).padding(-2))
                                .onTapGesture { labelColor = hex }
                        }
                    }
                }.padding(.horizontal, 24)
                Spacer()
            }
            .navigationTitle("Label Creator").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear { labelText = item.name; labelColor = item.colorHex ?? "#FF6600" }
        }
    }

    @ViewBuilder
    private var labelPreview: some View {
        let displayText = useNumber ? "#\(item.boxNumber ?? 0)" : labelText
        let size = labelSize.dimension
        let bgColor = Color(hex: labelColor) ?? .orange
        let textColor: Color = (labelColor == "#FFFFFF" || labelColor == "#F39C12") ? .black : .white
        ZStack {
            switch labelShape {
            case .circle: Circle().fill(bgColor).frame(width: size, height: size)
            case .square: Rectangle().fill(bgColor).frame(width: size, height: size)
            case .roundedSquare: RoundedRectangle(cornerRadius: size * 0.15).fill(bgColor).frame(width: size, height: size)
            }
            Text(displayText).font(.system(size: labelSize.fontSize, weight: .black, design: .rounded))
                .foregroundStyle(textColor).minimumScaleFactor(0.5).padding(12)
        }
    }
}
