import SwiftUI
import SceneKit

struct StorageSceneView: UIViewRepresentable {
    let space: StorageSpace
    let items: [StorageItem]
    @Binding var selectedItem: StorageItem?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = UIColor.systemGroupedBackground

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        let scene = buildScene()
        scnView.scene = scene
        context.coordinator.scnView = scnView

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        let scene = buildScene()
        scnView.scene = scene
        context.coordinator.items = items
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

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

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        return scene
    }

    private func buildItemNode(_ item: StorageItem) -> SCNNode {
        let wFt = item.widthFeet
        let hFt = item.heightFeet
        let dFt = item.depthFeet

        let containerNode = SCNNode()
        containerNode.name = item.id.uuidString
        containerNode.position = SCNVector3(
            item.posX + wFt / 2,
            item.posY + hFt / 2,
            item.posZ + dFt / 2
        )
        containerNode.eulerAngles.y = item.rotationY

        // Build shape based on hint
        let geometry: SCNGeometry
        switch item.shapeHint {
        case "cylinder":
            geometry = SCNCylinder(radius: CGFloat(max(wFt, dFt) / 2), height: CGFloat(hFt))
        default:
            geometry = SCNBox(width: CGFloat(wFt), height: CGFloat(hFt), length: CGFloat(dFt), chamferRadius: 0.02)
        }

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(hex: item.colorHex) ?? UIColor.brown
        material.roughness.contents = 0.8
        // Slightly different look for non-box items
        if item.category == .furniture {
            material.roughness.contents = 0.4
            material.metalness.contents = 0.1
        }
        geometry.materials = [material]

        let shapeNode = SCNNode(geometry: geometry)
        containerNode.addChildNode(shapeNode)

        // Label on top
        let labelText = item.category == .box ? "#\(item.boxNumber)" : item.label
        let textGeo = SCNText(string: labelText, extrusionDepth: 0.01)
        textGeo.font = UIFont.boldSystemFont(ofSize: 0.3)
        textGeo.firstMaterial?.diffuse.contents = UIColor.white
        textGeo.flatness = 0.1
        let textNode = SCNNode(geometry: textGeo)
        let (min, max) = textNode.boundingBox
        let textWidth = max.x - min.x
        let textHeight = max.y - min.y
        textNode.position = SCNVector3(-textWidth / 2, hFt / 2 + 0.01, textHeight / 2)
        textNode.eulerAngles.x = -Float.pi / 2
        containerNode.addChildNode(textNode)

        // Stack indicator
        if item.stackable {
            let indicatorGeo = SCNBox(width: CGFloat(wFt * 0.1), height: 0.02, length: CGFloat(dFt * 0.1), chamferRadius: 0.01)
            indicatorGeo.firstMaterial?.diffuse.contents = UIColor.systemGreen
            let indicatorNode = SCNNode(geometry: indicatorGeo)
            indicatorNode.position = SCNVector3(wFt / 2 - wFt * 0.08, hFt / 2 + 0.02, dFt / 2 - dFt * 0.08)
            containerNode.addChildNode(indicatorNode)
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
        var items: [StorageItem] = []

        init(_ parent: StorageSceneView) {
            self.parent = parent
            self.items = parent.items
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])

            for result in hitResults {
                // Walk up to find the named container node
                var node: SCNNode? = result.node
                while let current = node {
                    if let name = current.name,
                       let itemId = UUID(uuidString: name),
                       let item = items.first(where: { $0.id == itemId }) {
                        parent.selectedItem = item
                        return
                    }
                    node = current.parent
                }
            }
            parent.selectedItem = nil
        }
    }
}

// MARK: - UIColor hex helper

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6 else { return nil }
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
