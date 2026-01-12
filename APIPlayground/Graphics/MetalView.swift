import SwiftUI
import MetalKit

// MARK: - Metal Demo View
/// Advanced GPU raymarching shader creating a 3D scene
///
/// Features:
/// - Raymarched 3D geometry (spheres, torus, plane)
/// - Real-time soft shadows
/// - Ambient occlusion
/// - Reflections
/// - Animated camera orbit
/// - Touch interaction to control rotation

struct MetalView: View {
    @Environment(\.dismiss) private var dismiss
    var showGrid: Bool = false

    // Grid configuration - 4 columns x 6 rows (same as reference)
    let gridColumns = 4
    let gridRows = 6

    var body: some View {
        ZStack(alignment: .topLeading) {
            Metal3DView()
                .ignoresSafeArea()

            // Grid overlay (when enabled)
            if showGrid {
                GridOverlay(columns: gridColumns, rows: gridRows)
                    .ignoresSafeArea()
            }

            // Custom back button
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

struct Metal3DView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return createErrorView(message: "Metal device not available")
        }

        let (success, errorMsg) = context.coordinator.setupMetal(device: device)
        guard success else {
            return createErrorView(message: errorMsg ?? "Shader compilation failed")
        }

        let mtkView = MTKView()
        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        context.coordinator.device = device

        // Add pan gesture for camera control
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Metal3DRenderer.handlePan(_:)))
        mtkView.addGestureRecognizer(pan)

        return mtkView
    }

    private func createErrorView(message: String) -> UIView {
        let fallbackView = UIView()
        fallbackView.backgroundColor = .black
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        fallbackView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: fallbackView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: fallbackView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: fallbackView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: fallbackView.trailingAnchor, constant: -20)
        ])
        return fallbackView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Metal3DRenderer {
        Metal3DRenderer()
    }
}

// MARK: - Uniforms
struct RaymarchUniforms {
    var time: Float
    var resolution: SIMD2<Float>
    var cameraRotation: SIMD2<Float>
}

// MARK: - Metal 3D Renderer
class Metal3DRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var computePipeline: MTLComputePipelineState?
    var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    var cameraRotation: SIMD2<Float> = SIMD2<Float>(0, 0)
    var autoRotate: Bool = true
    var lastPanTime: CFAbsoluteTime = 0

    func setupMetal(device: MTLDevice) -> (Bool, String?) {
        self.device = device
        guard let queue = device.makeCommandQueue() else {
            return (false, "Failed to create command queue")
        }
        self.commandQueue = queue

        do {
            // Load precompiled shader from .metal file
            guard let library = device.makeDefaultLibrary() else {
                return (false, "Failed to load default Metal library")
            }
            guard let function = library.makeFunction(name: "darkFantasyShader") else {
                return (false, "Function 'darkFantasyShader' not found")
            }
            computePipeline = try device.makeComputePipelineState(function: function)
            return (true, nil)
        } catch {
            return (false, "Shader error: \(error.localizedDescription)")
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        // Reduced sensitivity - more movement needed for less screen shift
        cameraRotation.x += Float(translation.y) * 0.0015
        cameraRotation.y -= Float(translation.x) * 0.0015

        // Tight clamp to prevent looking past edges
        cameraRotation.x = max(-0.3, min(0.3, cameraRotation.x))
        cameraRotation.y = max(-0.3, min(0.3, cameraRotation.y))

        gesture.setTranslation(.zero, in: gesture.view)
        lastPanTime = CFAbsoluteTimeGetCurrent()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pipeline = computePipeline,
              let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }

        let texture = drawable.texture
        let time = Float(CFAbsoluteTimeGetCurrent() - startTime)

        var uniforms = RaymarchUniforms(
            time: time,
            resolution: SIMD2<Float>(Float(texture.width), Float(texture.height)),
            cameraRotation: cameraRotation
        )

        computeEncoder.setComputePipelineState(pipeline)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBytes(&uniforms, length: MemoryLayout<RaymarchUniforms>.size, index: 0)

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

#Preview {
    NavigationStack {
        MetalView()
    }
}
