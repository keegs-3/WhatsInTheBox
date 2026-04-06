import SwiftUI
import SceneKit

struct StorageSceneView: UIViewRepresentable {
    let space: StorageSpace
    let boxes: [StorageBox]
    @Binding var selectedBox: StorageBox?

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
        context.coordinator.boxes = boxes
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
                position: SCNVector3(space.width / 2, space.height / 2, 0), rotation: SCNVector4(0, 0, 0, 0)) // back
        addWall(to: scene, width: CGFloat(space.depth), height: CGFloat(space.height),
                position: SCNVector3(0, space.height / 2, space.depth / 2), rotation: SCNVector4(0, 1, 0, Float.pi / 2)) // left
        addWall(to: scene, width: CGFloat(space.depth), height: CGFloat(space.height),
                position: SCNVector3(space.width, space.height / 2, space.depth / 2), rotation: SCNVector4(0, 1, 0, Float.pi / 2)) // right

        // Boxes
        for box in boxes {
            let boxGeo = SCNBox(width: CGFloat(box.width), height: CGFloat(box.height), length: CGFloat(box.depth), chamferRadius: 0.02)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(hex: box.colorHex) ?? UIColor.brown
            material.roughness.contents = 0.8
            boxGeo.materials = [material]

            let boxNode = SCNNode(geometry: boxGeo)
            boxNode.position = SCNVector3(
                box.posX + box.width / 2,
                box.posY + box.height / 2,
                box.posZ + box.depth / 2
            )
            boxNode.name = box.id.uuidString

            // Number label on top
            let textGeo = SCNText(string: "#\(box.boxNumber)", extrusionDepth: 0.01)
            textGeo.font = UIFont.boldSystemFont(ofSize: 0.3)
            textGeo.firstMaterial?.diffuse.contents = UIColor.white
            textGeo.flatness = 0.1
            let textNode = SCNNode(geometry: textGeo)
            let (min, max) = textNode.boundingBox
            let textWidth = max.x - min.x
            let textHeight = max.y - min.y
            textNode.position = SCNVector3(-textWidth / 2, box.height / 2 + 0.01, textHeight / 2)
            textNode.eulerAngles.x = -Float.pi / 2
            boxNode.addChildNode(textNode)

            scene.rootNode.addChildNode(boxNode)
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
        var boxes: [StorageBox] = []

        init(_ parent: StorageSceneView) {
            self.parent = parent
            self.boxes = parent.boxes
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])

            for result in hitResults {
                if let name = result.node.name,
                   let boxId = UUID(uuidString: name),
                   let box = boxes.first(where: { $0.id == boxId }) {
                    parent.selectedBox = box
                    return
                }
            }
            parent.selectedBox = nil
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
