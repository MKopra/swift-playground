import SwiftUI
import SpriteKit

// MARK: - SpriteKit Demo View
/// 2D graphics, particle systems, and game physics
///
/// How it works:
/// 1. SKScene is the 2D world container
/// 2. SKPhysicsWorld provides gravity and collision detection
/// 3. SKEmitterNode creates particle effects (fire, sparks)
/// 4. SKShapeNode draws circles/shapes
/// 5. SKPhysicsBody makes objects respond to physics
/// 6. SKAction animates properties over time
/// 7. Touch spawns new physics balls

struct SpriteKitView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteKitDemoViewWrapper()
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

struct SpriteKitDemoViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
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
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        physicsWorld.contactDelegate = self
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        guard !hasSetup, size.width > 100, size.height > 100 else { return }
        hasSetup = true

        let boundary = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        boundary.friction = 0.2
        boundary.restitution = 0.8
        self.physicsBody = boundary

        addFireEmitter()
        addPlatforms()

        for _ in 0..<5 {
            spawnBall(at: CGPoint(
                x: CGFloat.random(in: 50...(size.width - 50)),
                y: CGFloat.random(in: size.height * 0.5...size.height - 50)
            ))
        }
    }

    func addFireEmitter() {
        let fire = SKEmitterNode()
        fire.particleSize = CGSize(width: 20, height: 20)
        fire.particleColor = .orange
        fire.particleColorBlendFactor = 1.0

        fire.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [UIColor.yellow, UIColor.orange, UIColor.red, UIColor.red.withAlphaComponent(0)],
            times: [0, 0.3, 0.7, 1.0]
        )

        fire.particleBirthRate = 400
        fire.particleLifetime = 1.5
        fire.particleLifetimeRange = 0.5
        fire.emissionAngle = .pi / 2
        fire.emissionAngleRange = .pi / 4
        fire.particleSpeed = 100
        fire.particleSpeedRange = 50
        fire.particleAlphaSpeed = -0.5
        fire.particleScaleSpeed = -0.3
        fire.particlePositionRange = CGVector(dx: 60, dy: 0)
        fire.particleBlendMode = .add
        fire.position = CGPoint(x: size.width / 2, y: 30)
        addChild(fire)

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

            platform.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 10))
            platform.physicsBody?.isDynamic = false
            platform.physicsBody?.restitution = 0.9
            platform.physicsBody?.friction = 0.1

            let moveUp = SKAction.moveBy(x: 0, y: 15, duration: 1.5)
            let moveDown = moveUp.reversed()
            platform.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))

            addChild(platform)
        }
    }

    func spawnBall(at position: CGPoint) {
        let radius: CGFloat = CGFloat.random(in: 10...20)
        let ball = SKShapeNode(circleOfRadius: radius)

        let colors: [UIColor] = [.systemRed, .systemGreen, .systemBlue, .systemYellow, .systemPurple, .systemOrange]
        ball.fillColor = colors.randomElement()!
        ball.strokeColor = .white
        ball.lineWidth = 2
        ball.position = position
        ball.glowWidth = 3

        ball.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        ball.physicsBody?.restitution = 0.8
        ball.physicsBody?.friction = 0.2
        ball.physicsBody?.linearDamping = 0.1
        ball.physicsBody?.angularDamping = 0.1
        ball.physicsBody?.velocity = CGVector(
            dx: CGFloat.random(in: -100...100),
            dy: CGFloat.random(in: -50...50)
        )

        addChild(ball)

        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
        ball.run(SKAction.sequence([scaleUp, scaleDown]))

        let wait = SKAction.wait(forDuration: 10)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        ball.run(SKAction.sequence([wait, fadeOut, remove]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        spawnBall(at: location)

        if let sparkEmitter = createSparkBurst() {
            sparkEmitter.position = location
            addChild(sparkEmitter)
        }
    }

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

        sparks.run(SKAction.sequence([
            SKAction.wait(forDuration: 1),
            SKAction.removeFromParent()
        ]))

        return sparks
    }
}

#Preview {
    NavigationStack {
        SpriteKitView()
    }
}
