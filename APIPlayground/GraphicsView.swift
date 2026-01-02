import SwiftUI
import MetalKit
import SceneKit
import SpriteKit
import QuartzCore

// MARK: - Main Graphics Demo View
/// A comprehensive demonstration of iOS graphics frameworks:
/// - Metal: Low-level GPU programming for custom shaders
/// - SceneKit: 3D rendering with physics and lighting
/// - SpriteKit: 2D graphics and particle systems
/// - Core Animation: Hardware-accelerated layer animations

struct GraphicsView: View {
    @State private var showMetal = false
    @State private var showSceneKit = false
    @State private var showSpriteKit = false
    @State private var showCoreAnimation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: Core Animation Demo Section
                GraphicsDemoSection(
                    title: "Core Animation",
                    subtitle: "Layered Keyframe Animations",
                    description: """
                    Core Animation powers all iOS animations at the lowest level. \
                    This demo uses CAShapeLayer with CAKeyframeAnimation for path morphing, \
                    CAReplicatorLayer for the circular pattern, and CAGradientLayer \
                    with animated colors. All animations run on the render server thread.
                    """
                ) {
                    if showCoreAnimation {
                        CoreAnimationDemoView()
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Button("Load Core Animation Demo") {
                            showCoreAnimation = true
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // MARK: Metal Demo Section
                GraphicsDemoSection(
                    title: "Metal",
                    subtitle: "GPU Compute Shader - Plasma Effect",
                    description: """
                    Metal is Apple's low-level GPU API for maximum performance. \
                    This demo uses a compute shader written in Metal Shading Language (MSL) \
                    to generate a real-time plasma effect. The shader runs entirely on the GPU, \
                    calculating color values for each pixel based on sine waves and time.
                    """
                ) {
                    if showMetal {
                        MetalPlasmaView()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Button("Load Metal Demo") {
                            showMetal = true
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // MARK: SceneKit Demo Section
                GraphicsDemoSection(
                    title: "SceneKit",
                    subtitle: "3D Scene with Physics & Lighting",
                    description: """
                    SceneKit provides high-level 3D graphics with built-in physics, \
                    lighting, and animations. This demo shows a rotating torus knot \
                    with physically-based rendering (PBR), environment reflections, \
                    and dynamic lighting. Touch to add falling spheres with physics.
                    """
                ) {
                    if showSceneKit {
                        SceneKitDemoView()
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Button("Load SceneKit Demo") {
                            showSceneKit = true
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // MARK: SpriteKit Demo Section
                GraphicsDemoSection(
                    title: "SpriteKit",
                    subtitle: "2D Particles & Physics Simulation",
                    description: """
                    SpriteKit excels at 2D graphics, particle systems, and game physics. \
                    This demo combines SKEmitterNode particles with SKPhysicsBody for \
                    realistic ball physics. Tap anywhere to spawn balls that bounce \
                    and collide. The fire particle effect uses 500+ particles.
                    """
                ) {
                    if showSpriteKit {
                        SpriteKitDemoView()
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Button("Load SpriteKit Demo") {
                            showSpriteKit = true
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Graphics")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Demo Section Container
struct GraphicsDemoSection<Content: View>: View {
    let title: String
    let subtitle: String
    let description: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            content()

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - ============================================================
// MARK: - METAL DEMO
// MARK: - ============================================================
/// Metal Plasma Effect Implementation
///
/// How it works:
/// 1. Create a MTLDevice (GPU interface) and MTLCommandQueue
/// 2. Compile a compute shader written in Metal Shading Language
/// 3. Each frame, dispatch the shader to calculate pixel colors
/// 4. The shader uses sin/cos waves with time offset for plasma effect
/// 5. MTKView displays the rendered texture at 60fps

struct MetalPlasmaView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        guard let device = MTLCreateSystemDefaultDevice(),
              context.coordinator.setupMetal(device: device) else {
            // Fallback if Metal isn't available
            let fallbackView = UIView()
            fallbackView.backgroundColor = .systemPurple
            let label = UILabel()
            label.text = "Metal not available"
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            fallbackView.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: fallbackView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: fallbackView.centerYAnchor)
            ])
            return fallbackView
        }

        let mtkView = MTKView()
        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        context.coordinator.device = device
        return mtkView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> MetalPlasmaRenderer {
        MetalPlasmaRenderer()
    }
}

/// Metal Renderer Coordinator
/// Implements MTKViewDelegate to render each frame
class MetalPlasmaRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var computePipeline: MTLComputePipelineState?
    var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    /// Initialize Metal pipeline
    /// 1. Get default GPU device
    /// 2. Create command queue for submitting work
    /// 3. Compile the plasma shader into a compute pipeline
    /// Returns false if setup fails
    func setupMetal(device: MTLDevice) -> Bool {
        self.device = device
        guard let queue = device.makeCommandQueue() else { return false }
        self.commandQueue = queue

        // Metal Shading Language source code for plasma effect
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        // Compute kernel that runs for each pixel
        // - tid: thread position (pixel coordinate)
        // - outTexture: output texture to write colors
        // - time: elapsed time for animation
        kernel void plasmaShader(
            texture2d<float, access::write> outTexture [[texture(0)]],
            uint2 tid [[thread_position_in_grid]],
            constant float &time [[buffer(0)]]
        ) {
            float width = outTexture.get_width();
            float height = outTexture.get_height();

            // Normalize coordinates to 0-1 range
            float2 uv = float2(tid) / float2(width, height);

            // Scale for plasma pattern density
            float2 p = uv * 8.0;

            // Plasma algorithm: sum of sine waves at different frequencies
            // Each sin() creates a wave pattern, combining them creates plasma
            float v = sin(p.x + time);
            v += sin(p.y + time);
            v += sin(p.x + p.y + time);
            v += sin(sqrt(p.x * p.x + p.y * p.y) + time);

            // Normalize to 0-1 range (v ranges from -4 to 4)
            v = (v + 4.0) / 8.0;

            // Create RGB colors using offset sine waves for variety
            float r = sin(v * 3.14159 * 2.0);
            float g = sin(v * 3.14159 * 2.0 + 2.094); // +120 degrees
            float b = sin(v * 3.14159 * 2.0 + 4.188); // +240 degrees

            // Normalize from -1,1 to 0,1
            float3 color = float3(r, g, b) * 0.5 + 0.5;

            outTexture.write(float4(color, 1.0), tid);
        }
        """

        // Compile shader at runtime
        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            guard let function = library.makeFunction(name: "plasmaShader") else { return false }
            computePipeline = try device.makeComputePipelineState(function: function)
            return true
        } catch {
            print("Metal shader compilation failed: \(error)")
            return false
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    /// Called every frame (60fps)
    /// 1. Get current drawable texture from MTKView
    /// 2. Create command buffer and compute encoder
    /// 3. Set pipeline, texture, and time uniform
    /// 4. Dispatch threads to GPU (one per pixel)
    /// 5. Present the drawable
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pipeline = computePipeline,
              let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }

        let texture = drawable.texture

        // Calculate elapsed time for animation
        var time = Float(CFAbsoluteTimeGetCurrent() - startTime)

        computeEncoder.setComputePipelineState(pipeline)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Calculate thread groups for GPU dispatch
        // threadExecutionWidth: optimal threads per group for this GPU
        let w = pipeline.threadExecutionWidth
        let h = pipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSize(width: texture.width, height: texture.height, depth: 1)

        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - ============================================================
// MARK: - SCENEKIT DEMO
// MARK: - ============================================================
/// SceneKit 3D Demo Implementation
///
/// How it works:
/// 1. Create SCNScene as the 3D world container
/// 2. Add SCNCamera for viewpoint
/// 3. Create SCNGeometry (torus) with PBR materials
/// 4. Add SCNLight for realistic lighting
/// 5. Use SCNAction for continuous rotation
/// 6. SCNPhysicsBody enables realistic physics
/// 7. Tap gesture adds new physics-enabled spheres

struct SceneKitDemoView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = context.coordinator.createScene()
        scnView.allowsCameraControl = true // Enable pan/zoom
        scnView.autoenablesDefaultLighting = false // We add custom lights
        scnView.backgroundColor = .black
        scnView.antialiasingMode = .multisampling4X

        // Add tap gesture for spawning spheres
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

        /// Build the 3D scene with all elements
        func createScene() -> SCNScene {
            let scene = SCNScene()

            // MARK: Camera Setup
            // Position camera to view the scene
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.zFar = 1000
            cameraNode.position = SCNVector3(x: 0, y: 2, z: 8)
            cameraNode.look(at: SCNVector3Zero)
            scene.rootNode.addChildNode(cameraNode)

            // MARK: Torus Knot Geometry
            // Create a torus (donut shape) as main object
            let torus = SCNTorus(ringRadius: 1.5, pipeRadius: 0.4)

            // Physically Based Rendering material
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor.systemBlue
            material.metalness.contents = 0.8 // Metallic look
            material.roughness.contents = 0.2 // Smooth/shiny
            material.emission.contents = UIColor.blue.withAlphaComponent(0.1)
            torus.materials = [material]

            let torusNode = SCNNode(geometry: torus)
            torusNode.name = "mainTorus"

            // Continuous rotation animation
            let rotate = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0.5, y: 1, z: 0.3, duration: 2)
            )
            torusNode.runAction(rotate)
            scene.rootNode.addChildNode(torusNode)

            // MARK: Floor with Physics
            // Create floor for spheres to land on
            let floor = SCNFloor()
            floor.reflectivity = 0.3
            let floorMaterial = SCNMaterial()
            floorMaterial.diffuse.contents = UIColor.darkGray
            floor.materials = [floorMaterial]

            let floorNode = SCNNode(geometry: floor)
            floorNode.position = SCNVector3(0, -3, 0)
            floorNode.physicsBody = SCNPhysicsBody.static()
            scene.rootNode.addChildNode(floorNode)

            // MARK: Lighting Setup
            // Key light - main illumination
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

            // Fill light - soften shadows
            let fillLight = SCNLight()
            fillLight.type = .omni
            fillLight.intensity = 300
            fillLight.color = UIColor.cyan

            let fillLightNode = SCNNode()
            fillLightNode.light = fillLight
            fillLightNode.position = SCNVector3(-5, 3, -3)
            scene.rootNode.addChildNode(fillLightNode)

            // Ambient light - base illumination
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.intensity = 200
            ambientLight.color = UIColor.white

            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            scene.rootNode.addChildNode(ambientNode)

            return scene
        }

        /// Tap handler: spawn a physics-enabled sphere
        /// The sphere falls due to gravity and bounces off the floor
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView, let scene = scnView.scene else { return }

            // Create sphere geometry
            let sphere = SCNSphere(radius: 0.3)
            let material = SCNMaterial()
            material.diffuse.contents = [UIColor.systemRed, .systemGreen, .systemOrange, .systemPurple].randomElement()
            material.metalness.contents = 0.5
            material.roughness.contents = 0.3
            sphere.materials = [material]

            let sphereNode = SCNNode(geometry: sphere)

            // Random position above scene
            sphereNode.position = SCNVector3(
                Float.random(in: -2...2),
                Float.random(in: 4...6),
                Float.random(in: -2...2)
            )

            // Add physics body for realistic falling/bouncing
            sphereNode.physicsBody = SCNPhysicsBody.dynamic()
            sphereNode.physicsBody?.restitution = 0.7 // Bounciness
            sphereNode.physicsBody?.friction = 0.5

            scene.rootNode.addChildNode(sphereNode)

            // Remove after 5 seconds to prevent memory buildup
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                sphereNode.removeFromParentNode()
            }
        }
    }
}

// MARK: - ============================================================
// MARK: - SPRITEKIT DEMO
// MARK: - ============================================================
/// SpriteKit 2D Demo Implementation
///
/// How it works:
/// 1. SKScene is the 2D world container
/// 2. SKPhysicsWorld provides gravity and collision detection
/// 3. SKEmitterNode creates particle effects (fire, sparks)
/// 4. SKShapeNode draws circles/shapes
/// 5. SKPhysicsBody makes objects respond to physics
/// 6. SKAction animates properties over time
/// 7. Touch spawns new physics balls

struct SpriteKitDemoView: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        // Use a reasonable default size, scene will resize with scaleMode
        let defaultSize = CGSize(width: 400, height: 300)
        skView.presentScene(context.coordinator.createScene(size: defaultSize))
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if let scene = uiView.scene as? SpriteKitDemoScene {
            context.coordinator.scene = scene
            // Update scene size when view size changes
            scene.size = uiView.bounds.size
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var scene: SpriteKitDemoScene?

        func createScene(size: CGSize) -> SpriteKitDemoScene {
            let scene = SpriteKitDemoScene(size: size)
            scene.scaleMode = .resizeFill
            self.scene = scene
            return scene
        }
    }
}

/// Custom SpriteKit Scene
class SpriteKitDemoScene: SKScene, SKPhysicsContactDelegate {

    private var hasSetup = false

    override func didMove(to view: SKView) {
        backgroundColor = .black

        // MARK: Physics World Setup
        // Configure gravity (default is -9.8 on Y axis)
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        physicsWorld.contactDelegate = self
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        // Only setup once we have a valid size
        guard !hasSetup, size.width > 100, size.height > 100 else { return }
        hasSetup = true

        // MARK: Boundary Walls
        // Create invisible walls so balls stay in view
        let boundary = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        boundary.friction = 0.2
        boundary.restitution = 0.8
        self.physicsBody = boundary

        // MARK: Fire Particle Emitter
        // Create realistic fire effect at bottom center
        addFireEmitter()

        // MARK: Floating Platforms
        // Add some platforms for balls to bounce on
        addPlatforms()

        // MARK: Initial Balls
        // Spawn some balls to start
        for _ in 0..<5 {
            spawnBall(at: CGPoint(
                x: CGFloat.random(in: 50...(size.width - 50)),
                y: CGFloat.random(in: size.height * 0.5...size.height - 50)
            ))
        }
    }

    /// Create fire particle effect
    /// SKEmitterNode properties:
    /// - particleBirthRate: particles per second
    /// - particleLifetime: how long each particle lives
    /// - particleSpeed: initial velocity
    /// - emissionAngle/Range: direction of emission
    /// - particleScale/Alpha speed: fade and shrink over time
    func addFireEmitter() {
        let fire = SKEmitterNode()

        // Particle appearance (no texture = uses default circle)
        fire.particleSize = CGSize(width: 20, height: 20)
        fire.particleColor = .orange
        fire.particleColorBlendFactor = 1.0

        // Color sequence: yellow -> orange -> red
        fire.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [UIColor.yellow, UIColor.orange, UIColor.red, UIColor.red.withAlphaComponent(0)],
            times: [0, 0.3, 0.7, 1.0]
        )

        // Emission properties
        fire.particleBirthRate = 400
        fire.particleLifetime = 1.5
        fire.particleLifetimeRange = 0.5

        // Movement
        fire.emissionAngle = .pi / 2 // Upward
        fire.emissionAngleRange = .pi / 4 // Spread
        fire.particleSpeed = 100
        fire.particleSpeedRange = 50

        // Fade and shrink
        fire.particleAlphaSpeed = -0.5
        fire.particleScaleSpeed = -0.3

        // Position spread
        fire.particlePositionRange = CGVector(dx: 60, dy: 0)

        // Add glow effect
        fire.particleBlendMode = .add

        fire.position = CGPoint(x: size.width / 2, y: 30)
        addChild(fire)

        // Add smoke above fire
        let smoke = SKEmitterNode()
        smoke.particleSize = CGSize(width: 30, height: 30)
        smoke.particleColor = .gray
        smoke.particleColorBlendFactor = 1.0
        smoke.particleBirthRate = 50
        smoke.particleLifetime = 3
        smoke.emissionAngle = .pi / 2
        smoke.emissionAngleRange = .pi / 8
        smoke.particleSpeed = 40
        smoke.particleAlpha = 0.3
        smoke.particleAlphaSpeed = -0.1
        smoke.particleScaleSpeed = 0.2
        smoke.particlePositionRange = CGVector(dx: 30, dy: 0)
        smoke.position = CGPoint(x: size.width / 2, y: 80)
        addChild(smoke)
    }

    /// Add floating platforms for balls to interact with
    func addPlatforms() {
        let platformPositions = [
            CGPoint(x: size.width * 0.25, y: size.height * 0.4),
            CGPoint(x: size.width * 0.75, y: size.height * 0.5),
            CGPoint(x: size.width * 0.5, y: size.height * 0.65)
        ]

        for pos in platformPositions {
            let platform = SKShapeNode(rectOf: CGSize(width: 80, height: 10), cornerRadius: 5)
            platform.fillColor = .systemBlue
            platform.strokeColor = .white
            platform.lineWidth = 2
            platform.position = pos

            // Static physics body - doesn't move but collides
            platform.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 10))
            platform.physicsBody?.isDynamic = false
            platform.physicsBody?.restitution = 0.9
            platform.physicsBody?.friction = 0.1

            // Gentle floating animation
            let moveUp = SKAction.moveBy(x: 0, y: 15, duration: 1.5)
            let moveDown = moveUp.reversed()
            let sequence = SKAction.sequence([moveUp, moveDown])
            platform.run(SKAction.repeatForever(sequence))

            addChild(platform)
        }
    }

    /// Spawn a physics-enabled ball at position
    func spawnBall(at position: CGPoint) {
        let radius: CGFloat = CGFloat.random(in: 10...20)
        let ball = SKShapeNode(circleOfRadius: radius)

        // Random vibrant color
        let colors: [UIColor] = [.systemRed, .systemGreen, .systemBlue, .systemYellow, .systemPurple, .systemOrange]
        ball.fillColor = colors.randomElement()!
        ball.strokeColor = .white
        ball.lineWidth = 2
        ball.position = position

        // Add glow effect
        ball.glowWidth = 3

        // Physics body for realistic movement
        ball.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        ball.physicsBody?.restitution = 0.8 // Bounciness
        ball.physicsBody?.friction = 0.2
        ball.physicsBody?.linearDamping = 0.1
        ball.physicsBody?.angularDamping = 0.1

        // Random initial velocity
        ball.physicsBody?.velocity = CGVector(
            dx: CGFloat.random(in: -100...100),
            dy: CGFloat.random(in: -50...50)
        )

        addChild(ball)

        // Pulse animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
        ball.run(SKAction.sequence([scaleUp, scaleDown]))

        // Remove after 10 seconds
        let wait = SKAction.wait(forDuration: 10)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        ball.run(SKAction.sequence([wait, fadeOut, remove]))
    }

    // Touch handling - spawn ball where user taps
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        spawnBall(at: location)

        // Spawn burst of small particles at touch
        if let sparkEmitter = createSparkBurst() {
            sparkEmitter.position = location
            addChild(sparkEmitter)
        }
    }

    /// Create a short burst of sparks
    func createSparkBurst() -> SKEmitterNode? {
        let sparks = SKEmitterNode()
        sparks.particleSize = CGSize(width: 8, height: 8)
        sparks.particleColor = .white
        sparks.particleColorBlendFactor = 1.0
        sparks.particleBirthRate = 200
        sparks.numParticlesToEmit = 30
        sparks.particleLifetime = 0.5
        sparks.emissionAngleRange = .pi * 2
        sparks.particleSpeed = 150
        sparks.particleSpeedRange = 50
        sparks.particleAlphaSpeed = -2
        sparks.particleScaleSpeed = -1
        sparks.particleBlendMode = .add

        // Remove emitter after burst
        let wait = SKAction.wait(forDuration: 1)
        let remove = SKAction.removeFromParent()
        sparks.run(SKAction.sequence([wait, remove]))

        return sparks
    }
}

// MARK: - ============================================================
// MARK: - CORE ANIMATION DEMO
// MARK: - ============================================================
/// Core Animation Demo Implementation
///
/// How it works:
/// 1. CALayer is the fundamental unit - every UIView has a backing layer
/// 2. CAShapeLayer draws vector paths with stroke/fill
/// 3. CAGradientLayer creates smooth color gradients
/// 4. CAReplicatorLayer duplicates sublayers with transforms
/// 5. CAKeyframeAnimation animates along arbitrary paths/values
/// 6. CABasicAnimation animates between two values
/// 7. Animations run on render server thread (60fps, non-blocking)

struct CoreAnimationDemoView: UIViewRepresentable {
    func makeUIView(context: Context) -> CoreAnimationHostView {
        let view = CoreAnimationHostView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: CoreAnimationHostView, context: Context) {}
}

/// Host view containing all Core Animation layers
class CoreAnimationHostView: UIView {

    private var gradientLayer: CAGradientLayer?
    private var hasSetupLayers = false

    override func layoutSubviews() {
        super.layoutSubviews()
        // Only setup once and only if we have valid bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        // Update gradient frame on every layout
        gradientLayer?.frame = bounds

        guard !hasSetupLayers else { return }
        hasSetupLayers = true
        setupLayers()
    }

    func setupLayers() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        // MARK: Gradient Background
        setupGradientBackground()

        // MARK: Replicator Layer with Rotating Bars
        setupReplicatorLayer(center: center)

        // MARK: Central Morphing Shape
        setupMorphingShape(center: center)

        // MARK: Pulsing Circles
        setupPulsingCircles(center: center)

        // MARK: Orbiting Dots
        setupOrbitingDots(center: center)
    }

    /// CAGradientLayer: Creates smooth color transitions
    /// - colors: Array of CGColor for gradient stops
    /// - locations: Position of each color (0-1)
    /// - startPoint/endPoint: Direction of gradient
    func setupGradientBackground() {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [
            UIColor.systemIndigo.cgColor,
            UIColor.black.cgColor,
            UIColor.systemPurple.cgColor
        ]
        gradient.locations = [0, 0.5, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)
        gradientLayer = gradient

        // Animate gradient colors
        let colorAnimation = CABasicAnimation(keyPath: "colors")
        colorAnimation.toValue = [
            UIColor.systemPurple.cgColor,
            UIColor.black.cgColor,
            UIColor.systemBlue.cgColor
        ]
        colorAnimation.duration = 3
        colorAnimation.autoreverses = true
        colorAnimation.repeatCount = .infinity
        gradient.add(colorAnimation, forKey: "colorShift")
    }

    /// CAReplicatorLayer: Duplicates sublayers with transforms
    /// - instanceCount: Number of copies
    /// - instanceTransform: Transform applied to each successive copy
    /// - instanceDelay: Animation delay between copies
    func setupReplicatorLayer(center: CGPoint) {
        let replicator = CAReplicatorLayer()
        replicator.frame = bounds
        replicator.position = center

        let barCount = 12
        replicator.instanceCount = barCount

        // Each instance rotates by 360/12 = 30 degrees
        let angle = CGFloat.pi * 2 / CGFloat(barCount)
        replicator.instanceTransform = CATransform3DMakeRotation(angle, 0, 0, 1)

        // Delay creates wave effect
        replicator.instanceDelay = 0.1

        // Create single bar that will be replicated
        let bar = CAShapeLayer()
        let barPath = UIBezierPath(roundedRect: CGRect(x: -4, y: -60, width: 8, height: 30), cornerRadius: 4)
        bar.path = barPath.cgPath
        bar.fillColor = UIColor.white.cgColor

        // Scale animation on the bar
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale.y")
        scaleAnimation.fromValue = 0.5
        scaleAnimation.toValue = 1.0
        scaleAnimation.duration = 0.6
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = .infinity
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bar.add(scaleAnimation, forKey: "scale")

        // Opacity animation
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.3
        opacityAnimation.toValue = 1.0
        opacityAnimation.duration = 0.6
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity
        bar.add(opacityAnimation, forKey: "opacity")

        replicator.addSublayer(bar)
        layer.addSublayer(replicator)
    }

    /// CAShapeLayer with path morphing animation
    /// CAKeyframeAnimation: Animates through multiple values
    /// - values: Array of values to animate through
    /// - keyTimes: When each value should be reached (0-1)
    func setupMorphingShape(center: CGPoint) {
        let shape = CAShapeLayer()
        shape.frame = CGRect(x: center.x - 40, y: center.y - 40, width: 80, height: 80)
        shape.fillColor = UIColor.systemCyan.withAlphaComponent(0.8).cgColor
        shape.strokeColor = UIColor.white.cgColor
        shape.lineWidth = 2

        // Define multiple shapes to morph between
        let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 80, height: 80))
        let squarePath = UIBezierPath(roundedRect: CGRect(x: 10, y: 10, width: 60, height: 60), cornerRadius: 8)
        let starPath = createStarPath(in: CGRect(x: 0, y: 0, width: 80, height: 80), points: 5)
        let trianglePath = createPolygonPath(in: CGRect(x: 0, y: 0, width: 80, height: 80), sides: 3)

        shape.path = circlePath.cgPath

        // Keyframe animation morphs through shapes
        let morphAnimation = CAKeyframeAnimation(keyPath: "path")
        morphAnimation.values = [
            circlePath.cgPath,
            squarePath.cgPath,
            starPath.cgPath,
            trianglePath.cgPath,
            circlePath.cgPath
        ]
        morphAnimation.keyTimes = [0, 0.25, 0.5, 0.75, 1]
        morphAnimation.duration = 4
        morphAnimation.repeatCount = .infinity
        morphAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shape.add(morphAnimation, forKey: "morph")

        // Rotation animation
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = CGFloat.pi * 2
        rotateAnimation.duration = 8
        rotateAnimation.repeatCount = .infinity
        shape.add(rotateAnimation, forKey: "rotate")

        layer.addSublayer(shape)
    }

    /// Create pulsing circle rings expanding outward
    func setupPulsingCircles(center: CGPoint) {
        for i in 0..<3 {
            let pulseLayer = CAShapeLayer()
            let radius: CGFloat = 30
            pulseLayer.path = UIBezierPath(ovalIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)).cgPath
            pulseLayer.position = center
            pulseLayer.fillColor = UIColor.clear.cgColor
            pulseLayer.strokeColor = UIColor.systemPink.cgColor
            pulseLayer.lineWidth = 2
            pulseLayer.opacity = 0

            // Scale up animation
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 1
            scaleAnimation.toValue = 4

            // Fade out animation
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 0.8
            opacityAnimation.toValue = 0

            // Group animations
            let group = CAAnimationGroup()
            group.animations = [scaleAnimation, opacityAnimation]
            group.duration = 2
            group.repeatCount = .infinity
            group.beginTime = CACurrentMediaTime() + Double(i) * 0.6 // Stagger start
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)

            pulseLayer.add(group, forKey: "pulse")
            layer.addSublayer(pulseLayer)
        }
    }

    /// Create orbiting dots using CAKeyframeAnimation with path
    /// The animation follows an elliptical path around center
    func setupOrbitingDots(center: CGPoint) {
        let orbitRadiusX: CGFloat = 90
        let orbitRadiusY: CGFloat = 50
        let dotCount = 5

        for i in 0..<dotCount {
            let dot = CAShapeLayer()
            dot.path = UIBezierPath(ovalIn: CGRect(x: -6, y: -6, width: 12, height: 12)).cgPath
            dot.fillColor = [UIColor.systemYellow, .systemGreen, .systemOrange, .systemRed, .systemTeal][i].cgColor
            dot.shadowColor = dot.fillColor
            dot.shadowRadius = 8
            dot.shadowOpacity = 0.8
            dot.shadowOffset = .zero

            // Create elliptical orbit path
            let orbitPath = UIBezierPath(ovalIn: CGRect(
                x: center.x - orbitRadiusX,
                y: center.y - orbitRadiusY,
                width: orbitRadiusX * 2,
                height: orbitRadiusY * 2
            ))

            // Animate position along path
            let orbitAnimation = CAKeyframeAnimation(keyPath: "position")
            orbitAnimation.path = orbitPath.cgPath
            orbitAnimation.duration = 3
            orbitAnimation.repeatCount = .infinity
            orbitAnimation.calculationMode = .paced // Constant speed
            orbitAnimation.rotationMode = .rotateAuto
            orbitAnimation.timeOffset = Double(i) * 0.6 // Stagger positions

            dot.add(orbitAnimation, forKey: "orbit")
            layer.addSublayer(dot)
        }
    }

    // MARK: Helper Methods

    /// Create a star path with given number of points
    func createStarPath(in rect: CGRect, points: Int) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4

        var angle: CGFloat = -.pi / 2 // Start at top

        for i in 0..<points * 2 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            angle += .pi / CGFloat(points)
        }
        path.close()
        return path
    }

    /// Create a regular polygon path
    func createPolygonPath(in rect: CGRect, sides: Int) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var angle: CGFloat = -.pi / 2

        for i in 0..<sides {
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            angle += .pi * 2 / CGFloat(sides)
        }
        path.close()
        return path
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        GraphicsView()
    }
}
