import SwiftUI
import ARKit
import RealityKit

// MARK: - ARKitView
/// A comprehensive augmented reality interface demonstrating ALL ARKit capabilities.
///
/// Features Demonstrated:
/// - World Tracking: 6DOF tracking with plane detection
/// - Face Tracking: Real-time face mesh with 52 blend shapes
/// - Body Tracking: Full skeleton motion capture (3m range)
/// - Image Detection: Detect and track 2D images
/// - Object Detection: Detect 3D objects
/// - Scene Reconstruction: LiDAR mesh generation
/// - People Occlusion: Hide virtual content behind people
/// - Raycasting: Hit testing against real world
/// - Environment Texturing: HDR environment maps
/// - Geo Anchors: Location-based AR (ARGeoTrackingConfiguration)
///
/// ARKit Configuration Options:
/// - ARWorldTrackingConfiguration: World tracking
/// - ARFaceTrackingConfiguration: Face tracking (TrueDepth camera)
/// - ARBodyTrackingConfiguration: Body/skeleton tracking
/// - ARImageTrackingConfiguration: Image-only tracking
/// - ARObjectScanningConfiguration: 3D object scanning
/// - ARGeoTrackingConfiguration: Location-based AR
/// - ARPositionalTrackingConfiguration: Simple positional tracking
///
/// Note: This API is NOT available in Flutter - requires native ARKit implementation.
struct ARKitView: View {
    @StateObject private var arManager = ARManager()
    @State private var showingInfo = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(arManager: arManager)
                .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Top controls
                HStack {
                    // Mode selector
                    Menu {
                        ForEach(ARMode.allCases) { mode in
                            Button(action: {
                                arManager.setMode(mode)
                            }) {
                                Label(mode.title, systemImage: mode.icon)
                            }
                            .disabled(!mode.isSupported)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: arManager.currentMode.icon)
                            Text(arManager.currentMode.title)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    }

                    Spacer()

                    // Settings
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    // Info
                    Button(action: { showingInfo = true }) {
                        Image(systemName: "info.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding()

                Spacer()

                // Mode-specific status display
                VStack(spacing: 12) {
                    // Tracking status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(arManager.trackingQuality.color)
                            .frame(width: 10, height: 10)

                        Text(arManager.trackingStateMessage)
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())

                    // Face tracking stats
                    if arManager.currentMode == .faceTracking && arManager.isFaceDetected {
                        FaceStatsView(blendShapes: arManager.faceBlendShapes)
                    }

                    // Body tracking stats
                    if arManager.currentMode == .bodyTracking && arManager.isBodyDetected {
                        BodyStatsView(jointCount: arManager.detectedJoints)
                    }

                    // Measurement display
                    if arManager.currentMode == .measure && arManager.measurementDistance > 0 {
                        Text(String(format: "%.2f m (%.1f ft)", arManager.measurementDistance, arManager.measurementDistance * 3.28084))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    // Scene reconstruction stats
                    if arManager.currentMode == .sceneReconstruction {
                        HStack(spacing: 16) {
                            StatBadge(label: "Vertices", value: "\(arManager.meshVertexCount)")
                            StatBadge(label: "Faces", value: "\(arManager.meshFaceCount)")
                        }
                    }

                    // Placed objects counter
                    if arManager.currentMode == .placeObjects && arManager.placedObjectsCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "cube.fill")
                                .foregroundStyle(.blue)
                            Text("\(arManager.placedObjectsCount) object\(arManager.placedObjectsCount == 1 ? "" : "s") placed")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.2), in: Capsule())
                        .foregroundStyle(.white)
                    }

                    // Placement failure message
                    if arManager.lastPlacementFailed {
                        Text("Point at a flat surface to place objects")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange.opacity(0.2), in: Capsule())
                    }

                    // Planes detected
                    if arManager.detectedPlanes > 0 {
                        Text("\(arManager.detectedPlanes) surface\(arManager.detectedPlanes == 1 ? "" : "s") detected")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    // Images detected
                    if arManager.detectedImages > 0 {
                        Text("\(arManager.detectedImages) image\(arManager.detectedImages == 1 ? "" : "s") detected")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.bottom, 8)

                // Bottom controls
                HStack(spacing: 20) {
                    // Clear button
                    Button(action: { arManager.clearScene() }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.title2)
                            Text("Clear")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Main action button
                    Button(action: { arManager.performAction() }) {
                        Image(systemName: arManager.currentMode.actionIcon)
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(arManager.currentMode.color)
                                    .shadow(color: arManager.currentMode.color.opacity(0.5), radius: 10)
                            )
                    }

                    // Screenshot button
                    Button(action: { arManager.takeSnapshot() }) {
                        VStack(spacing: 4) {
                            Image(systemName: "camera")
                                .font(.title2)
                            Text("Capture")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.bottom, 40)
            }

            // Crosshair for placement modes
            if arManager.currentMode == .placeObjects || arManager.currentMode == .measure {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .navigationTitle("AR Experience")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            arManager.startSession()
        }
        .onDisappear {
            arManager.pauseSession()
        }
        .sheet(isPresented: $showingInfo) {
            ARInfoView()
        }
        .sheet(isPresented: $showingSettings) {
            ARSettingsView(arManager: arManager)
        }
        .alert("AR Snapshot Saved", isPresented: $arManager.showSnapshotAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

// MARK: - ARMode
/// All available AR interaction modes demonstrating different ARKit features.
enum ARMode: String, CaseIterable, Identifiable {
    case placeObjects = "Place Objects"
    case measure = "Measure"
    case faceTracking = "Face Tracking"
    case bodyTracking = "Body Tracking"
    case sceneReconstruction = "Scene Mesh"
    case imageDetection = "Image Detection"
    case explore = "Explore"

    var id: String { rawValue }
    var title: String { rawValue }

    var icon: String {
        switch self {
        case .placeObjects: return "cube"
        case .measure: return "ruler"
        case .faceTracking: return "face.smiling"
        case .bodyTracking: return "figure.walk"
        case .sceneReconstruction: return "square.3.layers.3d"
        case .imageDetection: return "photo"
        case .explore: return "eye"
        }
    }

    var actionIcon: String {
        switch self {
        case .placeObjects: return "plus.circle.fill"
        case .measure: return "point.topleft.down.to.point.bottomright.curvepath"
        case .faceTracking: return "face.dashed"
        case .bodyTracking: return "figure.arms.open"
        case .sceneReconstruction: return "cube.transparent"
        case .imageDetection: return "viewfinder"
        case .explore: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .placeObjects: return .blue
        case .measure: return .orange
        case .faceTracking: return .pink
        case .bodyTracking: return .green
        case .sceneReconstruction: return .cyan
        case .imageDetection: return .yellow
        case .explore: return .purple
        }
    }

    var isSupported: Bool {
        switch self {
        case .placeObjects, .measure, .explore, .imageDetection:
            return ARWorldTrackingConfiguration.isSupported
        case .faceTracking:
            return ARFaceTrackingConfiguration.isSupported
        case .bodyTracking:
            return ARBodyTrackingConfiguration.isSupported
        case .sceneReconstruction:
            return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        }
    }

    var description: String {
        switch self {
        case .placeObjects:
            return "Place 3D objects on detected surfaces using raycasting"
        case .measure:
            return "Measure distances in the real world using ARKit"
        case .faceTracking:
            return "Track face with 52 blend shapes for expressions"
        case .bodyTracking:
            return "Full skeleton tracking with motion capture"
        case .sceneReconstruction:
            return "LiDAR-based 3D mesh of the environment"
        case .imageDetection:
            return "Detect and track 2D reference images"
        case .explore:
            return "Add visual effects at tap locations"
        }
    }
}

// MARK: - ARViewContainer
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arManager: ARManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arManager.setupARView(arView)

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(arManager: arManager)
    }

    class Coordinator: NSObject {
        let arManager: ARManager

        init(arManager: ARManager) {
            self.arManager = arManager
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            let location = gesture.location(in: arView)
            Task { @MainActor in
                arManager.handleTap(at: location, in: arView)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct FaceStatsView: View {
    let blendShapes: [ARFaceAnchor.BlendShapeLocation: Float]

    var body: some View {
        HStack(spacing: 12) {
            ExpressionBadge(name: "Smile", value: blendShapes[.mouthSmileLeft] ?? 0)
            ExpressionBadge(name: "Brow", value: blendShapes[.browInnerUp] ?? 0)
            ExpressionBadge(name: "Eye", value: 1 - (blendShapes[.eyeBlinkLeft] ?? 0))
            ExpressionBadge(name: "Jaw", value: blendShapes[.jawOpen] ?? 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ExpressionBadge: View {
    let name: String
    let value: Float

    var body: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(value))
                .progressViewStyle(.linear)
                .frame(width: 50)
                .tint(.pink)
            Text(name)
                .font(.caption2)
        }
    }
}

struct BodyStatsView: View {
    let jointCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "figure.walk")
                .foregroundStyle(.green)
            Text("Tracking \(jointCount) joints")
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - ARInfoView
struct ARInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Available Modes") {
                    ForEach(ARMode.allCases) { mode in
                        HStack(spacing: 16) {
                            Image(systemName: mode.icon)
                                .font(.title2)
                                .foregroundStyle(mode.isSupported ? mode.color : .gray)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(mode.title)
                                        .font(.headline)
                                    if !mode.isSupported {
                                        Text("Not Supported")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.red.opacity(0.2), in: Capsule())
                                            .foregroundStyle(.red)
                                    }
                                }

                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Device Capabilities") {
                    ARCapabilityRow(name: "World Tracking", supported: ARWorldTrackingConfiguration.isSupported)
                    ARCapabilityRow(name: "Face Tracking", supported: ARFaceTrackingConfiguration.isSupported)
                    ARCapabilityRow(name: "Body Tracking", supported: ARBodyTrackingConfiguration.isSupported)
                    ARCapabilityRow(name: "LiDAR Scanner", supported: ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh))
                    ARCapabilityRow(name: "People Occlusion", supported: ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth))
                    ARCapabilityRow(name: "Geo Tracking", supported: ARGeoTrackingConfiguration.isSupported)
                    ARCapabilityRow(name: "Ray Tracing", supported: ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification))
                }

                Section("Plane Detection") {
                    Text("• Horizontal planes (floors, tables)")
                    Text("• Vertical planes (walls)")
                    Text("• Automatic plane merging")
                    Text("• Classification (floor, seat, table, etc.)")
                }

                Section("Environment Features") {
                    Text("• Automatic environment texturing")
                    Text("• Manual probe placement")
                    Text("• HDR environment maps")
                    Text("• Light estimation")
                    Text("• Realistic reflections")
                }

                Section("Frame Semantics") {
                    Text("• Person segmentation")
                    Text("• Person segmentation with depth")
                    Text("• Body detection")
                }

                Section("Tips") {
                    TipRow(icon: "lightbulb", text: "Good lighting improves tracking quality")
                    TipRow(icon: "arrow.left.and.right", text: "Move slowly to help ARKit understand your space")
                    TipRow(icon: "square.dashed", text: "Look for flat surfaces for object placement")
                    TipRow(icon: "person.fill", text: "Face tracking requires front camera")
                }
            }
            .navigationTitle("ARKit Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ARCapabilityRow: View {
    let name: String
    let supported: Bool

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(supported ? .green : .red)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - ARSettingsView
struct ARSettingsView: View {
    @ObservedObject var arManager: ARManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Plane Detection") {
                    Toggle("Horizontal", isOn: $arManager.detectHorizontalPlanes)
                    Toggle("Vertical", isOn: $arManager.detectVerticalPlanes)
                }

                Section("Environment") {
                    Toggle("Environment Texturing", isOn: $arManager.environmentTexturing)
                    Toggle("People Occlusion", isOn: $arManager.peopleOcclusion)
                        .disabled(!ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth))
                }

                Section("Debug Visualization") {
                    Toggle("Show Feature Points", isOn: $arManager.showFeaturePoints)
                    Toggle("Show World Origin", isOn: $arManager.showWorldOrigin)
                    Toggle("Show Anchors", isOn: $arManager.showAnchors)
                    Toggle("Show Mesh", isOn: $arManager.showMesh)
                }

                Section("Object Shapes") {
                    Picker("Shape", selection: $arManager.objectShape) {
                        Text("Cube").tag(ObjectShape.cube)
                        Text("Sphere").tag(ObjectShape.sphere)
                        Text("Cylinder").tag(ObjectShape.cylinder)
                        Text("Cone").tag(ObjectShape.cone)
                    }

                    Slider(value: $arManager.objectSize, in: 0.02...0.2) {
                        Text("Size")
                    }
                    Text(String(format: "Size: %.0f cm", arManager.objectSize * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("AR Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        arManager.applySettings()
                        dismiss()
                    }
                }
            }
        }
    }
}

enum ObjectShape: String, CaseIterable {
    case cube, sphere, cylinder, cone
}

// MARK: - Tracking Quality
enum TrackingQuality {
    case notAvailable
    case limited
    case normal

    var color: Color {
        switch self {
        case .notAvailable: return .red
        case .limited: return .orange
        case .normal: return .green
        }
    }
}

// MARK: - ARManager
@MainActor
class ARManager: NSObject, ObservableObject {
    // MARK: Published Properties
    @Published var currentMode: ARMode = .placeObjects
    @Published var trackingQuality: TrackingQuality = .notAvailable
    @Published var trackingStateMessage = "Initializing..."
    @Published var detectedPlanes = 0
    @Published var detectedImages = 0
    @Published var measurementDistance: Float = 0
    @Published var showSnapshotAlert = false
    @Published var placedObjectsCount = 0
    @Published var lastPlacementFailed = false

    // Face tracking
    @Published var isFaceDetected = false
    @Published var faceBlendShapes: [ARFaceAnchor.BlendShapeLocation: Float] = [:]

    // Body tracking
    @Published var isBodyDetected = false
    @Published var detectedJoints = 0

    // Scene reconstruction
    @Published var meshVertexCount = 0
    @Published var meshFaceCount = 0

    // Settings
    @Published var detectHorizontalPlanes = true
    @Published var detectVerticalPlanes = true
    @Published var environmentTexturing = true
    @Published var peopleOcclusion = false
    @Published var showFeaturePoints = false
    @Published var showWorldOrigin = false
    @Published var showAnchors = false
    @Published var showMesh = false
    @Published var objectShape: ObjectShape = .cube
    @Published var objectSize: Float = 0.05

    // MARK: Private Properties
    private var arView: ARView?
    private var measurementPoints: [simd_float3] = []
    private var measurementAnchors: [AnchorEntity] = []
    private var placedObjects: [AnchorEntity] = []
    private var bodySkeletonAnchor: AnchorEntity?

    // MARK: Public Methods

    func setupARView(_ arView: ARView) {
        self.arView = arView
        arView.session.delegate = self
    }

    func startSession() {
        configureSession(for: currentMode)
    }

    func pauseSession() {
        arView?.session.pause()
    }

    func setMode(_ mode: ARMode) {
        guard mode.isSupported else { return }
        currentMode = mode
        clearMeasurement()
        isFaceDetected = false
        isBodyDetected = false
        configureSession(for: mode)
    }

    func handleTap(at location: CGPoint, in arView: ARView) {
        switch currentMode {
        case .placeObjects:
            placeObject(at: location, in: arView)
        case .measure:
            addMeasurementPoint(at: location, in: arView)
        case .explore:
            addEffect(at: location, in: arView)
        default:
            break
        }
    }

    func performAction() {
        guard let arView = arView else { return }
        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)

        switch currentMode {
        case .placeObjects:
            placeObject(at: center, in: arView)
        case .measure:
            clearMeasurement()
        case .explore:
            addEffect(at: center, in: arView)
        case .faceTracking:
            toggleFaceMesh()
        case .bodyTracking:
            toggleSkeletonVisualization()
        case .sceneReconstruction:
            toggleMeshVisualization()
        case .imageDetection:
            break
        }
    }

    func clearScene() {
        for anchor in placedObjects {
            anchor.removeFromParent()
        }
        placedObjects.removeAll()
        placedObjectsCount = 0
        clearMeasurement()
        bodySkeletonAnchor?.removeFromParent()
        bodySkeletonAnchor = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func takeSnapshot() {
        arView?.snapshot(saveToHDR: false) { image in
            guard let image = image else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            Task { @MainActor in
                self.showSnapshotAlert = true
            }
        }
    }

    func applySettings() {
        updateDebugOptions()
        configureSession(for: currentMode)
    }

    // MARK: Private Methods

    private func configureSession(for mode: ARMode) {
        guard let arView = arView else { return }

        switch mode {
        case .faceTracking:
            configureFaceTracking(arView)
        case .bodyTracking:
            configureBodyTracking(arView)
        case .sceneReconstruction:
            configureSceneReconstruction(arView)
        case .imageDetection:
            configureImageDetection(arView)
        default:
            configureWorldTracking(arView)
        }

        updateDebugOptions()
    }

    private func configureWorldTracking(_ arView: ARView) {
        guard ARWorldTrackingConfiguration.isSupported else {
            trackingStateMessage = "World tracking not supported"
            return
        }

        let config = ARWorldTrackingConfiguration()

        // Plane detection
        var planeDetection: ARWorldTrackingConfiguration.PlaneDetection = []
        if detectHorizontalPlanes { planeDetection.insert(.horizontal) }
        if detectVerticalPlanes { planeDetection.insert(.vertical) }
        config.planeDetection = planeDetection

        // Environment texturing
        if environmentTexturing {
            config.environmentTexturing = .automatic
        }

        // Scene reconstruction (LiDAR)
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        // People occlusion
        if peopleOcclusion && ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    private func configureFaceTracking(_ arView: ARView) {
        guard ARFaceTrackingConfiguration.isSupported else {
            trackingStateMessage = "Face tracking not supported"
            return
        }

        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true

        if ARFaceTrackingConfiguration.supportsWorldTracking {
            config.isWorldTrackingEnabled = true
        }

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    private func configureBodyTracking(_ arView: ARView) {
        guard ARBodyTrackingConfiguration.isSupported else {
            trackingStateMessage = "Body tracking not supported"
            return
        }

        let config = ARBodyTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    private func configureSceneReconstruction(_ arView: ARView) {
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            trackingStateMessage = "Scene reconstruction not supported (requires LiDAR)"
            return
        }

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.sceneReconstruction = .meshWithClassification
        config.environmentTexturing = .automatic

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        // Enable mesh visualization
        arView.debugOptions.insert(.showSceneUnderstanding)
    }

    private func configureImageDetection(_ arView: ARView) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]

        // Create reference images from bundle if available
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) {
            config.detectionImages = referenceImages
            config.maximumNumberOfTrackedImages = 4
        }

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    private func updateDebugOptions() {
        guard let arView = arView else { return }

        var options: ARView.DebugOptions = []
        if showFeaturePoints { options.insert(.showFeaturePoints) }
        if showWorldOrigin { options.insert(.showWorldOrigin) }
        if showAnchors { options.insert(.showAnchorOrigins) }
        if showMesh || currentMode == .sceneReconstruction { options.insert(.showSceneUnderstanding) }

        arView.debugOptions = options
    }

    private func placeObject(at location: CGPoint, in arView: ARView) {
        // Try multiple raycast options for better detection
        var result: ARRaycastResult?

        // First try existing planes
        if let planeResult = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal).first {
            result = planeResult
        }
        // Then try estimated planes
        else if let estimatedResult = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first {
            result = estimatedResult
        }
        // Finally try any alignment
        else if let anyResult = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first {
            result = anyResult
        }

        guard let hitResult = result else {
            lastPlacementFailed = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            // Clear failure message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.lastPlacementFailed = false
            }
            return
        }

        lastPlacementFailed = false

        let colors: [SimpleMaterial.Color] = [.red, .blue, .green, .yellow, .purple, .cyan, .orange, .magenta]
        let color = colors.randomElement() ?? .blue

        // Use larger default size for visibility (10cm default)
        let size = max(objectSize, 0.1)

        let mesh: MeshResource
        switch objectShape {
        case .cube:
            mesh = MeshResource.generateBox(size: size, cornerRadius: size * 0.1)
        case .sphere:
            mesh = MeshResource.generateSphere(radius: size / 2)
        case .cylinder:
            // Use box as fallback since generateCylinder requires iOS 18+
            mesh = MeshResource.generateBox(size: [size / 2, size, size / 2], cornerRadius: size * 0.1)
        case .cone:
            // Use sphere as fallback since generateCone requires iOS 18+
            mesh = MeshResource.generateSphere(radius: size / 2)
        }

        let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: true)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        modelEntity.generateCollisionShapes(recursive: true)

        // Position the object slightly above the surface
        var transform = hitResult.worldTransform
        transform.columns.3.y += size / 2  // Lift object so it sits on surface

        let anchor = AnchorEntity(world: transform)
        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)
        placedObjects.append(anchor)
        placedObjectsCount = placedObjects.count

        // Animate with a bounce effect
        modelEntity.scale = [0.01, 0.01, 0.01]
        var targetTransform = modelEntity.transform
        targetTransform.scale = [1, 1, 1]
        modelEntity.move(to: targetTransform, relativeTo: modelEntity.parent, duration: 0.3, timingFunction: .easeOut)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func addMeasurementPoint(at location: CGPoint, in arView: ARView) {
        guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first else {
            return
        }

        let position = simd_make_float3(result.worldTransform.columns.3)

        let mesh = MeshResource.generateSphere(radius: 0.01)
        let material = SimpleMaterial(color: .orange, roughness: 0.5, isMetallic: false)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])

        let anchor = AnchorEntity(world: result.worldTransform)
        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)
        measurementAnchors.append(anchor)
        measurementPoints.append(position)

        if measurementPoints.count == 2 {
            measurementDistance = simd_distance(measurementPoints[0], measurementPoints[1])
            drawLine(from: measurementPoints[0], to: measurementPoints[1], in: arView)
        } else if measurementPoints.count > 2 {
            clearMeasurement()
            addMeasurementPoint(at: location, in: arView)
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func drawLine(from start: simd_float3, to end: simd_float3, in arView: ARView) {
        let distance = simd_distance(start, end)
        let midpoint = (start + end) / 2

        let mesh = MeshResource.generateBox(size: [0.002, 0.002, distance], cornerRadius: 0.001)
        let material = SimpleMaterial(color: .orange, roughness: 0.5, isMetallic: false)
        let lineEntity = ModelEntity(mesh: mesh, materials: [material])

        let direction = normalize(end - start)
        let up = simd_float3(0, 0, 1)
        let rotation = simd_quatf(from: up, to: direction)

        var transform = Transform.identity
        transform.translation = midpoint
        transform.rotation = rotation

        let anchor = AnchorEntity(world: transform.matrix)
        anchor.addChild(lineEntity)
        arView.scene.addAnchor(anchor)
        measurementAnchors.append(anchor)
    }

    private func clearMeasurement() {
        for anchor in measurementAnchors {
            anchor.removeFromParent()
        }
        measurementAnchors.removeAll()
        measurementPoints.removeAll()
        measurementDistance = 0
    }

    private func addEffect(at location: CGPoint, in arView: ARView) {
        guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first else {
            return
        }

        let mesh = MeshResource.generateSphere(radius: 0.03)
        var material = SimpleMaterial()
        material.color = .init(tint: .purple.withAlphaComponent(0.8))
        material.roughness = 0
        material.metallic = 1

        let modelEntity = ModelEntity(mesh: mesh, materials: [material])

        let anchor = AnchorEntity(world: result.worldTransform)
        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)
        placedObjects.append(anchor)

        var bigTransform = modelEntity.transform
        bigTransform.scale = [2, 2, 2]
        modelEntity.move(to: bigTransform, relativeTo: modelEntity.parent, duration: 0.5, timingFunction: .easeOut)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            anchor.removeFromParent()
            if let index = self.placedObjects.firstIndex(where: { $0 === anchor }) {
                self.placedObjects.remove(at: index)
            }
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func toggleFaceMesh() {
        // Toggle face mesh visualization
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func toggleSkeletonVisualization() {
        if bodySkeletonAnchor != nil {
            bodySkeletonAnchor?.removeFromParent()
            bodySkeletonAnchor = nil
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func toggleMeshVisualization() {
        guard let arView = arView else { return }
        if arView.debugOptions.contains(.showSceneUnderstanding) {
            arView.debugOptions.remove(.showSceneUnderstanding)
        } else {
            arView.debugOptions.insert(.showSceneUnderstanding)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - ARSessionDelegate
extension ARManager: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor in
            switch frame.camera.trackingState {
            case .notAvailable:
                self.trackingQuality = .notAvailable
                self.trackingStateMessage = "Tracking not available"
            case .limited(let reason):
                self.trackingQuality = .limited
                switch reason {
                case .initializing:
                    self.trackingStateMessage = "Initializing..."
                case .excessiveMotion:
                    self.trackingStateMessage = "Move slower"
                case .insufficientFeatures:
                    self.trackingStateMessage = "Need more features"
                case .relocalizing:
                    self.trackingStateMessage = "Relocalizing..."
                @unknown default:
                    self.trackingStateMessage = "Limited tracking"
                }
            case .normal:
                self.trackingQuality = .normal
                self.trackingStateMessage = "Tracking active"
            }

            // Update mesh stats for scene reconstruction
            if self.currentMode == .sceneReconstruction {
                var vertexCount = 0
                var faceCount = 0
                for anchor in frame.anchors {
                    if let meshAnchor = anchor as? ARMeshAnchor {
                        vertexCount += meshAnchor.geometry.vertices.count
                        faceCount += meshAnchor.geometry.faces.count
                    }
                }
                self.meshVertexCount = vertexCount
                self.meshFaceCount = faceCount
            }
        }
    }

    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if anchor is ARPlaneAnchor {
                    self.detectedPlanes += 1
                } else if anchor is ARImageAnchor {
                    self.detectedImages += 1
                    self.highlightDetectedImage(anchor as! ARImageAnchor)
                } else if let faceAnchor = anchor as? ARFaceAnchor {
                    self.isFaceDetected = true
                    self.faceBlendShapes = faceAnchor.blendShapes as! [ARFaceAnchor.BlendShapeLocation: Float]
                } else if anchor is ARBodyAnchor {
                    self.isBodyDetected = true
                }
            }
        }
    }

    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if let faceAnchor = anchor as? ARFaceAnchor {
                    self.faceBlendShapes = faceAnchor.blendShapes as! [ARFaceAnchor.BlendShapeLocation: Float]
                } else if let bodyAnchor = anchor as? ARBodyAnchor {
                    self.detectedJoints = bodyAnchor.skeleton.definition.jointCount
                }
            }
        }
    }

    nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if anchor is ARPlaneAnchor {
                    self.detectedPlanes = max(0, self.detectedPlanes - 1)
                } else if anchor is ARImageAnchor {
                    self.detectedImages = max(0, self.detectedImages - 1)
                } else if anchor is ARFaceAnchor {
                    self.isFaceDetected = false
                } else if anchor is ARBodyAnchor {
                    self.isBodyDetected = false
                }
            }
        }
    }

    @MainActor
    private func highlightDetectedImage(_ imageAnchor: ARImageAnchor) {
        #if !targetEnvironment(simulator)
        guard let arView = arView else { return }

        let size = imageAnchor.referenceImage.physicalSize
        let mesh = MeshResource.generatePlane(width: Float(size.width), depth: Float(size.height))
        var material = SimpleMaterial()
        material.color = .init(tint: .green.withAlphaComponent(0.5))

        let modelEntity = ModelEntity(mesh: mesh, materials: [material])

        let anchor = AnchorEntity(anchor: imageAnchor)
        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)
        placedObjects.append(anchor)
        #endif
    }
}

#Preview {
    NavigationStack {
        ARKitView()
    }
}
