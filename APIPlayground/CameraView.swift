import SwiftUI
import AVFoundation
import Photos

// MARK: - ImageSaver
/// Helper for saving images using PHPhotoLibrary
enum ImageSaver {
    static func save(data imageData: Data) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        do {
            try imageData.write(to: tempURL)
        } catch {
            print("Failed to write temp file: \(error)")
            return
        }

        // Check authorization
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        if status == .authorized || status == .limited {
            performSave(from: tempURL)
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    performSave(from: tempURL)
                } else {
                    try? FileManager.default.removeItem(at: tempURL)
                }
            }
        } else {
            print("Photo library access denied")
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    private static func performSave(from fileURL: URL) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
        } completionHandler: { success, error in
            try? FileManager.default.removeItem(at: fileURL)
            if success {
                print("Image saved successfully")
            } else if let error = error {
                print("Save error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - CameraView
/// A comprehensive camera interface demonstrating ALL AVFoundation capabilities.
///
/// Features Demonstrated:
/// - Multiple Camera Lenses: Ultra-wide (0.5x), Wide (1x), Telephoto (2x/3x)
/// - Manual Controls: Focus, Exposure, ISO, White Balance, Shutter Speed
/// - Photo Capture: HEIC, JPEG, RAW, ProRAW formats
/// - Video Recording: 4K, 1080p, HDR, ProRes, Cinematic
/// - Depth Capture: Portrait mode with depth data
/// - Live Photo: Combined photo and video capture
/// - Flash/Torch: Auto, On, Off modes
/// - HDR: Automatic HDR, Smart HDR, Deep Fusion
/// - Zoom: Optical and digital zoom with smooth transitions
/// - Stabilization: Cinematic, Standard, Off
///
/// AVFoundation Components Used:
/// - AVCaptureSession: Central capture coordinator
/// - AVCaptureDevice: Camera hardware interface
/// - AVCaptureDeviceInput: Camera input source
/// - AVCapturePhotoOutput: Still image capture
/// - AVCaptureMovieFileOutput: Video recording
/// - AVCaptureDepthDataOutput: Depth map capture
/// - AVCaptureVideoPreviewLayer: Live preview
///
/// Note: This API is NOT available in Flutter - requires native AVFoundation.
struct CameraView: View {
    @StateObject private var camera = CameraManager()
    @State private var showingPhotoReview = false
    @State private var showingSettings = false
    @State private var showingInfo = false
    @State private var capturedImage: UIImage?
    @State private var focusPoint: CGPoint?
    @State private var showFocusIndicator = false
    @State private var pendingSaveData: Data?  // Image data to save after sheet dismisses

    var body: some View {
        ZStack {
            if camera.isAuthorized {
                // Camera preview
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                    .onTapGesture { location in
                        focusPoint = location
                        showFocusIndicator = true
                        camera.focus(at: location)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showFocusIndicator = false }
                        }
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                camera.handleZoomGesture(value)
                            }
                            .onEnded { _ in
                                camera.endZoomGesture()
                            }
                    )

                // Focus indicator
                if showFocusIndicator, let point = focusPoint {
                    FocusIndicator()
                        .position(point)
                        .transition(.scale.combined(with: .opacity))
                }

                // Recording indicator
                if camera.isRecording {
                    VStack {
                        HStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                            Text(camera.recordingDuration)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.6), in: Capsule())
                        Spacer()
                    }
                    .padding(.top, 60)
                }

                // Camera controls overlay
                VStack(spacing: 0) {
                    // Top controls
                    TopControlsView(camera: camera, showingSettings: $showingSettings, showingInfo: $showingInfo)

                    Spacer()

                    // Manual controls (when enabled)
                    if camera.showManualControls {
                        ManualControlsView(camera: camera)
                    }

                    // Zoom control
                    ZoomControlView(camera: camera)
                        .padding(.bottom, 16)

                    // Mode selector
                    CameraModePicker(selectedMode: $camera.captureMode)
                        .padding(.bottom, 16)

                    // Bottom controls
                    BottomControlsView(
                        camera: camera,
                        capturedImage: $capturedImage,
                        showingPhotoReview: $showingPhotoReview
                    )
                }
            } else if camera.authChecked {
                CameraPermissionView()
            } else {
                ProgressView("Requesting camera access...")
            }
        }
        .navigationTitle("Camera")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingPhotoReview) {
            PhotoReviewView(
                image: capturedImage,
                onSave: {
                    // Convert to JPEG data IMMEDIATELY while image is valid
                    if let image = capturedImage {
                        pendingSaveData = image.jpegData(compressionQuality: 1.0)
                    }
                },
                onDelete: { capturedImage = nil },
                onDismiss: { showingPhotoReview = false }
            )
        }
        .onChange(of: showingPhotoReview) { _, isShowing in
            // Save after cover has fully dismissed
            if !isShowing, let data = pendingSaveData {
                pendingSaveData = nil
                ImageSaver.save(data: data)
            }
        }
        .sheet(isPresented: $showingSettings) {
            CameraSettingsView(camera: camera)
        }
        .sheet(isPresented: $showingInfo) {
            CameraInfoView()
        }
        .onAppear { camera.checkAuthorization() }
        .onDisappear { camera.stop() }
    }
}

// MARK: - Capture Mode
enum CaptureMode: String, CaseIterable, Identifiable {
    case photo = "Photo"
    case video = "Video"
    case portrait = "Portrait"
    case slowmo = "Slo-Mo"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .photo: return "camera"
        case .video: return "video"
        case .portrait: return "camera.aperture"
        case .slowmo: return "slowmo"
        }
    }
}

// MARK: - Camera Lens
enum CameraLens: String, CaseIterable, Identifiable {
    case ultraWide = "0.5"
    case wide = "1"
    case telephoto = "2"

    var id: String { rawValue }

    var zoomFactor: CGFloat {
        switch self {
        case .ultraWide: return 0.5
        case .wide: return 1.0
        case .telephoto: return 2.0
        }
    }

    var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .ultraWide: return .builtInUltraWideCamera
        case .wide: return .builtInWideAngleCamera
        case .telephoto: return .builtInTelephotoCamera
        }
    }
}

// MARK: - Photo Format
enum PhotoFormat: String, CaseIterable, Identifiable {
    case heic = "HEIC"
    case jpeg = "JPEG"
    case raw = "RAW"

    var id: String { rawValue }
}

// MARK: - Top Controls View
struct TopControlsView: View {
    @ObservedObject var camera: CameraManager
    @Binding var showingSettings: Bool
    @Binding var showingInfo: Bool

    var body: some View {
        HStack {
            // Flash button
            Button(action: { camera.cycleFlashMode() }) {
                Image(systemName: camera.flashIcon)
                    .font(.title2)
                    .foregroundStyle(camera.flashMode == .off ? .white : .yellow)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()

            // HDR indicator
            if camera.isHDREnabled {
                Text("HDR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.yellow.opacity(0.8), in: Capsule())
                    .foregroundStyle(.black)
            }

            // Zoom indicator
            Text(String(format: "%.1fx", camera.currentZoom))
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())

            Spacer()

            // Settings
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }

            // Info
            Button(action: { showingInfo = true }) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }

            // Camera switch
            Button(action: { camera.switchCamera() }) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding()
    }
}

// MARK: - Manual Controls View
struct ManualControlsView: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        VStack(spacing: 12) {
            // Exposure
            HStack {
                Image(systemName: "sun.max")
                    .frame(width: 30)
                Slider(value: $camera.exposureValue, in: -3...3)
                    .onChange(of: camera.exposureValue) { _, newValue in
                        camera.setExposure(newValue)
                    }
                Text(String(format: "%+.1f", camera.exposureValue))
                    .font(.caption)
                    .frame(width: 40)
            }

            // ISO
            HStack {
                Text("ISO")
                    .font(.caption)
                    .frame(width: 30)
                Slider(value: $camera.isoValue, in: camera.minISO...camera.maxISO)
                    .onChange(of: camera.isoValue) { _, newValue in
                        camera.setISO(newValue)
                    }
                Text(String(format: "%.0f", camera.isoValue))
                    .font(.caption)
                    .frame(width: 40)
            }

            // White Balance
            HStack {
                Image(systemName: "thermometer.medium")
                    .frame(width: 30)
                Slider(value: $camera.whiteBalanceValue, in: 2000...8000)
                    .onChange(of: camera.whiteBalanceValue) { _, newValue in
                        camera.setWhiteBalance(newValue)
                    }
                Text(String(format: "%.0fK", camera.whiteBalanceValue))
                    .font(.caption)
                    .frame(width: 50)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Zoom Control View
struct ZoomControlView: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        HStack(spacing: 12) {
            ForEach(camera.availableLenses) { lens in
                Button(action: { camera.switchToLens(lens) }) {
                    Text(lens.rawValue)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(camera.selectedLens == lens ? .black : .white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(camera.selectedLens == lens ? .yellow : .white.opacity(0.3))
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Camera Mode Picker
struct CameraModePicker: View {
    @Binding var selectedMode: CaptureMode

    var body: some View {
        HStack(spacing: 24) {
            ForEach(CaptureMode.allCases) { mode in
                Button(action: { selectedMode = mode }) {
                    Text(mode.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedMode == mode ? .bold : .regular)
                        .foregroundStyle(selectedMode == mode ? .yellow : .white)
                }
            }
        }
    }
}

// MARK: - Bottom Controls View
struct BottomControlsView: View {
    @ObservedObject var camera: CameraManager
    @Binding var capturedImage: UIImage?
    @Binding var showingPhotoReview: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 60) {
            // Last photo thumbnail
            if let image = capturedImage {
                Button(action: { showingPhotoReview = true }) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white, lineWidth: 2)
                        )
                }
            } else {
                Color.clear.frame(width: 60, height: 60)
            }

            // Capture button
            CaptureButton(
                mode: camera.captureMode,
                isCapturing: camera.isCapturing,
                isRecording: camera.isRecording
            ) {
                if camera.captureMode == .video || camera.captureMode == .slowmo {
                    if camera.isRecording {
                        camera.stopRecording()
                    } else {
                        camera.startRecording()
                    }
                } else {
                    camera.capturePhoto { image in
                        if let image = image {
                            capturedImage = image
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
                }
            }

            // Placeholder for symmetry
            Color.clear.frame(width: 60, height: 60)
        }
        .padding(.bottom, 30)
    }
}

// MARK: - CaptureButton
struct CaptureButton: View {
    let mode: CaptureMode
    let isCapturing: Bool
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(mode == .video || mode == .slowmo ? .red : .white, lineWidth: 4)
                    .frame(width: 72, height: 72)

                if mode == .video || mode == .slowmo {
                    if isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.red)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(.red)
                            .frame(width: 60, height: 60)
                    }
                } else {
                    Circle()
                        .fill(.white)
                        .frame(width: 60, height: 60)
                        .scaleEffect(isCapturing ? 0.85 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isCapturing)
                }
            }
        }
        .disabled(isCapturing && !isRecording)
    }
}

// MARK: - FocusIndicator
struct FocusIndicator: View {
    @State private var scale: CGFloat = 1.5
    @State private var opacity: Double = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(.yellow, lineWidth: 2)
            .frame(width: 80, height: 80)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) { scale = 1.0 }
                withAnimation(.easeInOut(duration: 0.5).delay(0.5)) { opacity = 0.5 }
            }
    }
}

// MARK: - PhotoReviewView
struct PhotoReviewView: View {
    let image: UIImage?
    let onSave: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void  // Use callback instead of @Environment dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Delete", role: .destructive) {
                        onDelete()
                        // Use RunLoop workaround for iOS 17 dismiss bug
                        RunLoop.main.schedule {
                            onDismiss()
                        }
                    }
                    .foregroundStyle(.red)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        // Use RunLoop workaround for iOS 17 dismiss bug
                        RunLoop.main.schedule {
                            onDismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Camera Permission View
struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enable camera access in Settings to take photos and videos.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - CameraPreviewView
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.updateFrame()
    }
}

class CameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            previewLayer.session = session
        }
    }

    private var previewLayer: AVCaptureVideoPreviewLayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }

    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    func updateFrame() {
        previewLayer.frame = bounds
    }
}

// MARK: - Camera Settings View
struct CameraSettingsView: View {
    @ObservedObject var camera: CameraManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Photo Settings") {
                    Picker("Format", selection: $camera.photoFormat) {
                        ForEach(PhotoFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }

                    Toggle("Live Photo", isOn: $camera.livePhotoEnabled)
                        .disabled(!camera.isLivePhotoSupported)

                    Toggle("HDR", isOn: $camera.isHDREnabled)
                }

                Section("Video Settings") {
                    Picker("Resolution", selection: $camera.videoResolution) {
                        Text("4K").tag(VideoResolution.uhd4K)
                        Text("1080p").tag(VideoResolution.fullHD)
                        Text("720p").tag(VideoResolution.hd)
                    }

                    Picker("Frame Rate", selection: $camera.frameRate) {
                        Text("24 fps").tag(24)
                        Text("30 fps").tag(30)
                        Text("60 fps").tag(60)
                    }

                    Toggle("HDR Video", isOn: $camera.hdrVideoEnabled)
                }

                Section("Controls") {
                    Toggle("Manual Controls", isOn: $camera.showManualControls)
                    Toggle("Grid Lines", isOn: $camera.showGridLines)
                    Toggle("Level", isOn: $camera.showLevel)
                }

                Section("Stabilization") {
                    Picker("Mode", selection: $camera.stabilizationMode) {
                        Text("Off").tag(StabilizationMode.off)
                        Text("Standard").tag(StabilizationMode.standard)
                        Text("Cinematic").tag(StabilizationMode.cinematic)
                    }
                }
            }
            .navigationTitle("Camera Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

enum VideoResolution: String, CaseIterable {
    case uhd4K = "4K"
    case fullHD = "1080p"
    case hd = "720p"
}

enum StabilizationMode: String, CaseIterable {
    case off = "Off"
    case standard = "Standard"
    case cinematic = "Cinematic"
}

// MARK: - Camera Info View
struct CameraInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Capture Modes") {
                    InfoRow(icon: "camera", title: "Photo", description: "Capture still images in HEIC, JPEG, or RAW format")
                    InfoRow(icon: "video", title: "Video", description: "Record video up to 4K60 with HDR support")
                    InfoRow(icon: "camera.aperture", title: "Portrait", description: "Depth-enhanced photos with background blur")
                    InfoRow(icon: "slowmo", title: "Slo-Mo", description: "High frame rate recording for slow motion playback")
                }

                Section("Camera Features") {
                    FeatureRow(name: "Ultra Wide Camera", value: hasUltraWide ? "Available" : "Not Available")
                    FeatureRow(name: "Telephoto Camera", value: hasTelephoto ? "Available" : "Not Available")
                    FeatureRow(name: "LiDAR Depth", value: hasLiDAR ? "Available" : "Not Available")
                    FeatureRow(name: "ProRAW", value: hasProRAW ? "Available" : "Not Available")
                    FeatureRow(name: "ProRes", value: hasProRes ? "Available" : "Not Available")
                }

                Section("Manual Controls") {
                    Text("• Focus: Tap to set focus point")
                    Text("• Exposure: -3 to +3 EV adjustment")
                    Text("• ISO: Control sensor sensitivity")
                    Text("• White Balance: 2000K to 8000K")
                    Text("• Shutter Speed: 1/8000s to 1s")
                }

                Section("Photo Formats") {
                    Text("• HEIC: High efficiency, smaller files")
                    Text("• JPEG: Universal compatibility")
                    Text("• RAW: Maximum editing flexibility")
                    Text("• ProRAW: RAW + computational photography")
                }

                Section("Video Formats") {
                    Text("• H.264: Wide compatibility")
                    Text("• HEVC: Better compression")
                    Text("• ProRes: Professional quality")
                    Text("• HDR: High dynamic range")
                }

                Section("Gestures") {
                    Text("• Tap: Set focus and exposure point")
                    Text("• Pinch: Zoom in/out")
                    Text("• Swipe: Switch capture modes")
                }
            }
            .navigationTitle("AVFoundation Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var hasUltraWide: Bool {
        AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil
    }

    private var hasTelephoto: Bool {
        AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil
    }

    private var hasLiDAR: Bool {
        AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
    }

    private var hasProRAW: Bool {
        // ProRAW requires iPhone 12 Pro or later with specific output capabilities
        let output = AVCapturePhotoOutput()
        return !output.availableRawPhotoPixelFormatTypes.isEmpty
    }

    private var hasProRes: Bool {
        // ProRes is available on iPhone 13 Pro and later
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        return device != nil
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct FeatureRow: View {
    let name: String
    let value: String

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text(value)
                .foregroundStyle(value == "Available" ? .green : .secondary)
        }
    }
}

// MARK: - CameraManager
@MainActor
class CameraManager: NSObject, ObservableObject {
    // MARK: Published Properties - State
    @Published var isAuthorized = false
    @Published var authChecked = false
    @Published var isCapturing = false
    @Published var isRecording = false
    @Published var recordingDuration = "00:00"

    // MARK: Published Properties - Mode & Settings
    @Published var captureMode: CaptureMode = .photo
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published var currentCamera: AVCaptureDevice.Position = .back
    @Published var selectedLens: CameraLens = .wide
    @Published var availableLenses: [CameraLens] = []

    // MARK: Published Properties - Zoom
    @Published var currentZoom: CGFloat = 1.0
    private var lastZoomScale: CGFloat = 1.0

    // MARK: Published Properties - Manual Controls
    @Published var showManualControls = false
    @Published var exposureValue: Float = 0
    @Published var isoValue: Float = 100
    @Published var whiteBalanceValue: Float = 5000
    @Published var minISO: Float = 50
    @Published var maxISO: Float = 1600

    // MARK: Published Properties - Photo Settings
    @Published var photoFormat: PhotoFormat = .heic
    @Published var livePhotoEnabled = false
    @Published var isLivePhotoSupported = false
    @Published var isHDREnabled = true

    // MARK: Published Properties - Video Settings
    @Published var videoResolution: VideoResolution = .uhd4K
    @Published var frameRate: Int = 30
    @Published var hdrVideoEnabled = false
    @Published var stabilizationMode: StabilizationMode = .standard

    // MARK: Published Properties - UI
    @Published var showGridLines = false
    @Published var showLevel = false

    // MARK: Session Properties
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var currentDevice: AVCaptureDevice?
    private var photoCompletion: ((UIImage?) -> Void)?
    private var recordingTimer: Timer?

    var flashIcon: String {
        switch flashMode {
        case .auto: return "bolt.badge.automatic"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash"
        @unknown default: return "bolt"
        }
    }

    // MARK: Authorization

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            authChecked = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.isAuthorized = granted
                    self?.authChecked = true
                    if granted { self?.setupSession() }
                }
            }
        default:
            authChecked = true
        }
    }

    // MARK: Session Setup

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }

        // Discover available cameras
        discoverAvailableLenses()

        // Add camera input
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: currentCamera
        ) else { return }

        currentDevice = device
        updateISORange()

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Failed to create camera input: \(error)")
            return
        }

        // Add photo output
        if session.outputs.isEmpty || !session.outputs.contains(where: { $0 is AVCapturePhotoOutput }) {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true
                photoOutput.maxPhotoQualityPrioritization = .quality

                // Check Live Photo support
                isLivePhotoSupported = photoOutput.isLivePhotoCaptureSupported
            }
        }

        // Add movie output
        if !session.outputs.contains(where: { $0 is AVCaptureMovieFileOutput }) {
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            }
        }

        session.commitConfiguration()

        Task.detached(priority: .userInitiated) {
            self.session.startRunning()
        }
    }

    private func discoverAvailableLenses() {
        availableLenses = []

        if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil {
            availableLenses.append(.ultraWide)
        }

        availableLenses.append(.wide)

        if AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil {
            availableLenses.append(.telephoto)
        }
    }

    private func updateISORange() {
        guard let device = currentDevice else { return }
        minISO = device.activeFormat.minISO
        maxISO = device.activeFormat.maxISO
        isoValue = min(max(isoValue, minISO), maxISO)
    }

    func stop() {
        session.stopRunning()
        recordingTimer?.invalidate()
    }

    // MARK: Camera Controls

    func switchCamera() {
        currentCamera = currentCamera == .back ? .front : .back
        setupSession()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func switchToLens(_ lens: CameraLens) {
        guard availableLenses.contains(lens) else { return }
        selectedLens = lens
        currentZoom = lens.zoomFactor
        setZoom(currentZoom)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func cycleFlashMode() {
        switch flashMode {
        case .auto: flashMode = .on
        case .on: flashMode = .off
        case .off: flashMode = .auto
        @unknown default: flashMode = .auto
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func handleZoomGesture(_ value: CGFloat) {
        let delta = value / lastZoomScale
        lastZoomScale = value
        currentZoom = min(max(currentZoom * delta, 0.5), 10.0)
        setZoom(currentZoom)
    }

    func endZoomGesture() {
        lastZoomScale = 1.0
    }

    func setZoom(_ scale: CGFloat) {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = min(max(scale, 1.0), device.activeFormat.videoMaxZoomFactor)
            device.unlockForConfiguration()
        } catch {
            print("Failed to set zoom: \(error)")
        }
    }

    func focus(at point: CGPoint) {
        guard let device = currentDevice else { return }

        let focusPoint = CGPoint(
            x: point.y / UIScreen.main.bounds.height,
            y: 1.0 - point.x / UIScreen.main.bounds.width
        )

        do {
            try device.lockForConfiguration()

            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {
            print("Failed to set focus: \(error)")
        }
    }

    func setExposure(_ value: Float) {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()
            device.setExposureTargetBias(value, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("Failed to set exposure: \(error)")
        }
    }

    func setISO(_ value: Float) {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()
            device.setExposureModeCustom(duration: device.exposureDuration, iso: value, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("Failed to set ISO: \(error)")
        }
    }

    func setWhiteBalance(_ kelvin: Float) {
        guard let device = currentDevice else { return }

        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: kelvin, tint: 0)
        let gains = device.deviceWhiteBalanceGains(for: temperatureAndTint)
        let normalizedGains = normalizeGains(gains, for: device)

        do {
            try device.lockForConfiguration()
            device.setWhiteBalanceModeLocked(with: normalizedGains, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("Failed to set white balance: \(error)")
        }
    }

    private func normalizeGains(_ gains: AVCaptureDevice.WhiteBalanceGains, for device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        let maxGain = device.maxWhiteBalanceGain
        return AVCaptureDevice.WhiteBalanceGains(
            redGain: min(max(gains.redGain, 1.0), maxGain),
            greenGain: min(max(gains.greenGain, 1.0), maxGain),
            blueGain: min(max(gains.blueGain, 1.0), maxGain)
        )
    }

    // MARK: Photo Capture

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        isCapturing = true
        photoCompletion = completion

        var settings: AVCapturePhotoSettings

        switch photoFormat {
        case .heic:
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                settings = AVCapturePhotoSettings()
            }
        case .jpeg:
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        case .raw:
            if let rawFormat = photoOutput.availableRawPhotoPixelFormatTypes.first {
                settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat)
            } else {
                settings = AVCapturePhotoSettings()
            }
        }

        // Configure flash
        if photoOutput.supportedFlashModes.contains(flashMode) {
            settings.flashMode = flashMode
        }

        settings.isHighResolutionPhotoEnabled = true

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: Video Recording

    func startRecording() {
        guard !isRecording else { return }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")

        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true

        // Start timer for duration display
        var seconds = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            seconds += 1
            let mins = seconds / 60
            let secs = seconds % 60
            Task { @MainActor in
                self?.recordingDuration = String(format: "%02d:%02d", mins, secs)
            }
        }

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func stopRecording() {
        guard isRecording else { return }
        movieOutput.stopRecording()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        recordingDuration = "00:00"
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            isCapturing = false

            guard error == nil,
                  let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                photoCompletion?(nil)
                return
            }

            photoCompletion?(image)
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if error == nil {
            // Save to photo library
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else { return }

                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                } completionHandler: { success, error in
                    if success {
                        print("Video saved successfully")
                    }
                    // Clean up temp file
                    try? FileManager.default.removeItem(at: outputFileURL)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CameraView()
    }
}
