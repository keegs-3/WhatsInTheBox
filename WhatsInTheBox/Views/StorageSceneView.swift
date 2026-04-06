import SwiftUI
import SceneKit

struct StorageSceneView: UIViewRepresentable {
    let space: StorageSpace
    let items: [Item]
    @Binding var selectedItem: Item?

    var onItemMoved: ((Item, Float, Float, Float) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = UIColor.systemGroupedBackground

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        scnView.addGestureRecognizer(panGesture)

        // Let pan take priority — camera orbit needs 2 fingers
        scnView.allowsCameraControl = true

        scnView.scene = buildScene()
        context.coordinator.scnView = scnView
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        scnView.scene = buildScene()
        context.coordinator.items = items
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func buildScene() -> SCNScene {
        let scene = SCNScene()

        // Floor
        let floorGeo = SCNBox(width: CGFloat(space.width), height: 0.05, length: CGFloat(space.depth), chamferRadius: 0)
        floorGeo.firstMaterial?.diffuse.contents = UIColor.systemGray5
        let floorNode = SCNNode(geometry: floorGeo)
        floorNode.position = SCNVector3(space.width / 2, -0.025, space.depth / 2)
        scene.rootNode.addChildNode(floorNode)

        // Walls
        addWall(to: scene, width: CGFloat(space.width), height: CGFloat(space.height),
                position: SCNVector3(space.width / 2, space.height / 2, 0), rotation: SCNVector4(0, 0, 0, 0))
        addWall(to: scene, width: CGFloat(space.depth), height: CGFloat(space.height),
                position: SCNVector3(0, space.height / 2, space.depth / 2), rotation: SCNVector4(0, 1, 0, Float.pi / 2))
        addWall(to: scene, width: CGFloat(space.depth), height: CGFloat(space.height),
                position: SCNVector3(space.width, space.height / 2, space.depth / 2), rotation: SCNVector4(0, 1, 0, Float.pi / 2))

        // Items
        for item in items {
            let node = buildItemNode(item)
            scene.rootNode.addChildNode(node)
        }

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 50
        cameraNode.position = SCNVector3(space.width / 2, space.height * 1.2, space.depth * 2)
        cameraNode.look(at: SCNVector3(space.width / 2, space.height / 3, space.depth / 2))
        scene.rootNode.addChildNode(cameraNode)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLight)

        return scene
    }

    private func buildItemNode(_ item: Item) -> SCNNode {
        let wFt = item.widthFeet
        let hFt = item.heightFeet
        let dFt = item.depthFeet
        let px = item.posX ?? 0
        let py = item.posY ?? 0
        let pz = item.posZ ?? 0

        let containerNode = SCNNode()
        containerNode.name = item.id.uuidString
        containerNode.position = SCNVector3(px + wFt / 2, py + hFt / 2, pz + dFt / 2)
        containerNode.eulerAngles.y = item.rotationY ?? 0

        let lidColor = UIColor(hex: item.colorHex ?? "#8B6914") ?? UIColor.brown
        let bodyRaw = item.bodyColorHex ?? ""
        let isClear = bodyRaw.lowercased() == "clear"
        let bodyColor = isClear ? UIColor.white.withAlphaComponent(0.15) : (UIColor(hex: bodyRaw) ?? lidColor)

        if item.shapeHint == "cylinder" {
            let geo = SCNCylinder(radius: CGFloat(max(wFt, dFt) / 2), height: CGFloat(hFt))
            let mat = SCNMaterial()
            mat.diffuse.contents = lidColor
            mat.roughness.contents = 0.8
            geo.materials = [mat]
            let node = SCNNode(geometry: geo)
            containerNode.addChildNode(node)
        } else {
            // Body (main box)
            let lidThickness: Float = 0.06
            let bodyH = hFt - lidThickness

            let bodyGeo = SCNBox(width: CGFloat(wFt), height: CGFloat(bodyH), length: CGFloat(dFt), chamferRadius: 0.01)
            let bodyMat = SCNMaterial()
            bodyMat.diffuse.contents = bodyColor
            bodyMat.roughness.contents = 0.8
            if isClear {
                bodyMat.transparency = 0.3
                bodyMat.transparencyMode = .dualLayer
            }
            bodyGeo.materials = [bodyMat]
            let bodyNode = SCNNode(geometry: bodyGeo)
            bodyNode.position = SCNVector3(0, -lidThickness / 2, 0)
            containerNode.addChildNode(bodyNode)

            // Lid (top)
            let lidGeo = SCNBox(width: CGFloat(wFt + 0.02), height: CGFloat(lidThickness), length: CGFloat(dFt + 0.02), chamferRadius: 0.02)
            let lidMat = SCNMaterial()
            lidMat.diffuse.contents = lidColor
            lidMat.roughness.contents = 0.6
            lidGeo.materials = [lidMat]
            let lidNode = SCNNode(geometry: lidGeo)
            lidNode.position = SCNVector3(0, bodyH / 2, 0)
            containerNode.addChildNode(lidNode)
        }

        // Label
        let labelText = (item.category == .box || item.category == .tote) ? "#\(item.boxNumber ?? 0)" : item.name
        let textGeo = SCNText(string: labelText, extrusionDepth: 0.01)
        textGeo.font = UIFont.boldSystemFont(ofSize: 0.3)
        textGeo.firstMaterial?.diffuse.contents = UIColor.white
        textGeo.flatness = 0.1
        let textNode = SCNNode(geometry: textGeo)
        let (mn, mx) = textNode.boundingBox
        textNode.position = SCNVector3(-(mx.x - mn.x) / 2, hFt / 2 + 0.01, (mx.y - mn.y) / 2)
        textNode.eulerAngles.x = -Float.pi / 2
        containerNode.addChildNode(textNode)

        if item.stackable == true {
            let ind = SCNBox(width: CGFloat(wFt * 0.1), height: 0.02, length: CGFloat(dFt * 0.1), chamferRadius: 0.01)
            ind.firstMaterial?.diffuse.contents = UIColor.systemGreen
            let indNode = SCNNode(geometry: ind)
            indNode.position = SCNVector3(wFt / 2 - wFt * 0.08, hFt / 2 + 0.02, dFt / 2 - dFt * 0.08)
            containerNode.addChildNode(indNode)
        }

        return containerNode
    }

    private func addWall(to scene: SCNScene, width: CGFloat, height: CGFloat, position: SCNVector3, rotation: SCNVector4) {
        let wallGeo = SCNBox(width: width, height: height, length: 0.05, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemGray4.withAlphaComponent(0.4)
        material.isDoubleSided = true
        wallGeo.materials = [material]
        let wallNode = SCNNode(geometry: wallGeo)
        wallNode.position = position
        wallNode.rotation = rotation
        scene.rootNode.addChildNode(wallNode)
    }

    class Coordinator: NSObject {
        var parent: StorageSceneView
        var scnView: SCNView?
        var items: [Item] = []
        var draggedNode: SCNNode?
        var draggedItem: Item?
        var dragStartPos: SCNVector3?

        init(_ parent: StorageSceneView) {
            self.parent = parent
            self.items = parent.items
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            for result in hitResults {
                var node: SCNNode? = result.node
                while let current = node {
                    if let name = current.name, let itemId = UUID(uuidString: name),
                       let item = items.first(where: { $0.id == itemId }) {
                        parent.selectedItem = item
                        return
                    }
                    node = current.parent
                }
            }
            parent.selectedItem = nil
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scnView = scnView else { return }

            switch gesture.state {
            case .began:
                let location = gesture.location(in: scnView)
                let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
                for result in hitResults {
                    var node: SCNNode? = result.node
                    while let current = node {
                        if let name = current.name, let _ = UUID(uuidString: name) {
                            draggedNode = current
                            dragStartPos = current.position
                            draggedItem = items.first { $0.id.uuidString == name }
                            // Disable camera control while dragging
                            scnView.allowsCameraControl = false
                            return
                        }
                        node = current.parent
                    }
                }

            case .changed:
                guard let node = draggedNode, let startPos = dragStartPos else { return }
                let translation = gesture.translation(in: scnView)
                // Scale screen points to scene units (rough approximation)
                let scale: Float = 0.01
                let newX = startPos.x + Float(translation.x) * scale
                let newZ = startPos.z + Float(translation.y) * scale
                // Clamp to space bounds
                let spaceW = parent.space.width
                let spaceD = parent.space.depth
                node.position = SCNVector3(
                    max(0.5, min(spaceW - 0.5, newX)),
                    startPos.y,
                    max(0.5, min(spaceD - 0.5, newZ))
                )

            case .ended, .cancelled:
                if let node = draggedNode, let item = draggedItem {
                    let wFt = item.widthFeet
                    let dFt = item.depthFeet
                    let finalX = node.position.x - wFt / 2
                    let finalZ = node.position.z - dFt / 2
                    parent.onItemMoved?(item, finalX, node.position.y, finalZ)
                    parent.selectedItem = item
                }
                draggedNode = nil
                draggedItem = nil
                dragStartPos = nil
                scnView.allowsCameraControl = true

            default:
                break
            }
        }
    }
}

extension UIColor {
    convenience init?(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6 else { return nil }
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        self.init(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgb & 0x0000FF) / 255.0, alpha: 1.0)
    }
}
