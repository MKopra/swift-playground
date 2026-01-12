import SwiftUI
import SceneKit

// MARK: - SceneKit Demo View
/// 3D rendering with physics, lighting, and PBR materials
///
/// How it works:
/// 1. Create SCNScene as the 3D world container
/// 2. Add SCNCamera for viewpoint
/// 3. Create SCNGeometry (torus) with PBR materials
/// 4. Add SCNLight for realistic lighting
/// 5. Use SCNAction for continuous rotation
/// 6. SCNPhysicsBody enables realistic physics
/// 7. Tap gesture adds new physics-enabled spheres

struct SceneKitView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            SceneKitDemoView()
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(.top, 50)
            .padding(.leading, 16)
        }
        .navigationBarHidden(true)
    }
}

struct SceneKitDemoView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = context.coordinator.createScene()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = .black
        scnView.antialiasingMode = .multisampling4X

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)
        context.coordinator.scnView = scnView

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        weak var scnView: SCNView?

        func createScene() -> SCNScene {
            let scene = SCNScene()

            // Camera
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.zFar = 1000
            cameraNode.position = SCNVector3(x: 0, y: 2, z: 8)
            cameraNode.look(at: SCNVector3Zero)
            scene.rootNode.addChildNode(cameraNode)

            // Torus
            let torus = SCNTorus(ringRadius: 1.5, pipeRadius: 0.4)
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor.systemBlue
            material.metalness.contents = 0.8
            material.roughness.contents = 0.2
            material.emission.contents = UIColor.blue.withAlphaComponent(0.1)
            torus.materials = [material]

            let torusNode = SCNNode(geometry: torus)
            let rotate = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0.5, y: 1, z: 0.3, duration: 2)
            )
            torusNode.runAction(rotate)
            scene.rootNode.addChildNode(torusNode)

            // Floor
            let floor = SCNFloor()
            floor.reflectivity = 0.3
            let floorMaterial = SCNMaterial()
            floorMaterial.diffuse.contents = UIColor.darkGray
            floor.materials = [floorMaterial]

            let floorNode = SCNNode(geometry: floor)
            floorNode.position = SCNVector3(0, -3, 0)
            floorNode.physicsBody = SCNPhysicsBody.static()
            scene.rootNode.addChildNode(floorNode)

            // Key light
            let keyLight = SCNLight()
            keyLight.type = .spot
            keyLight.intensity = 1000
            keyLight.spotInnerAngle = 30
            keyLight.spotOuterAngle = 80
            keyLight.castsShadow = true
            keyLight.shadowMode = .deferred

            let keyLightNode = SCNNode()
            keyLightNode.light = keyLight
            keyLightNode.position = SCNVector3(5, 8, 5)
            keyLightNode.look(at: SCNVector3Zero)
            scene.rootNode.addChildNode(keyLightNode)

            // Fill light
            let fillLight = SCNLight()
            fillLight.type = .omni
            fillLight.intensity = 300
            fillLight.color = UIColor.cyan

            let fillLightNode = SCNNode()
            fillLightNode.light = fillLight
            fillLightNode.position = SCNVector3(-5, 3, -3)
            scene.rootNode.addChildNode(fillLightNode)

            // Ambient light
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.intensity = 200
            ambientLight.color = UIColor.white

            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            scene.rootNode.addChildNode(ambientNode)

            return scene
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView, let scene = scnView.scene else { return }

            let sphere = SCNSphere(radius: 0.3)
            let material = SCNMaterial()
            material.diffuse.contents = [UIColor.systemRed, .systemGreen, .systemOrange, .systemPurple].randomElement()
            material.metalness.contents = 0.5
            material.roughness.contents = 0.3
            sphere.materials = [material]

            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(
                Float.random(in: -2...2),
                Float.random(in: 4...6),
                Float.random(in: -2...2)
            )

            sphereNode.physicsBody = SCNPhysicsBody.dynamic()
            sphereNode.physicsBody?.restitution = 0.7
            sphereNode.physicsBody?.friction = 0.5

            scene.rootNode.addChildNode(sphereNode)

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                sphereNode.removeFromParentNode()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SceneKitView()
    }
}
