import SwiftUI
import CoreMotion
import UIKit

// MARK: - MotionView
/// An interactive motion sensor playground demonstrating CoreMotion capabilities.
///
/// Features:
/// - 3D barbell visualization responding to device tilt
/// - Live accelerometer, gyroscope, and magnetometer data
/// - Attitude visualization (pitch, roll, yaw)
/// - Step counter and pedometer data
/// - Spin gesture with momentum physics
/// - Calibration for baseline orientation
///
/// APIs Demonstrated:
/// - CMMotionManager for device motion updates
/// - CMPedometer for step counting
/// - DeviceMotion attitude, rotation rate, and acceleration
/// - Haptic feedback synchronized with motion
struct MotionView: View {
    @StateObject private var motionManager = MotionManager()
    @State private var spinAngle: Double = 0
    @State private var spinVelocity: Double = 0
    @State private var lastDragValue: CGFloat = 0
    @State private var lastTickAngle: Double = 0
    @State private var momentumTimer: Timer?
    @State private var showingData = false

    private let tickHaptic = UIImpactFeedbackGenerator(style: .light)
    private let tapHaptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            // 3D Barbell
            GeometryReader { geo in
                let barbellWidth = UIScreen.main.bounds.width + 200
                let barbellHeight: CGFloat = 280

                SpinningBarbell(
                    pitch: motionManager.relativePitch,
                    roll: motionManager.relativeRoll,
                    spinAngle: spinAngle,
                    size: CGSize(width: barbellWidth, height: barbellHeight)
                )
                .frame(width: barbellWidth, height: barbellHeight)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        let delta = value.translation.height - lastDragValue
                        spinAngle += Double(delta) * 0.5
                        lastDragValue = value.translation.height

                        let angleDelta = abs(spinAngle - lastTickAngle)
                        if angleDelta > 8 {
                            tickHaptic.impactOccurred(intensity: 0.4)
                            lastTickAngle = spinAngle
                        }
                    }
                    .onEnded { value in
                        spinVelocity = Double(value.velocity.height) * 0.003
                        startMomentum()
                        lastDragValue = 0
                    }
            )
            .onTapGesture {
                tapHaptic.impactOccurred()
                motionManager.calibrate()
            }

            // Data overlay
            VStack {
                // Top info bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tap to calibrate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Drag to spin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Data toggle button
                    Button(action: { withAnimation { showingData.toggle() } }) {
                        Image(systemName: showingData ? "chart.bar.fill" : "chart.bar")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding()

                Spacer()

                // Motion data panel
                if showingData {
                    MotionDataPanel(manager: motionManager)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Motion")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            motionManager.start()
            tickHaptic.prepare()
            tapHaptic.prepare()
        }
        .onDisappear {
            motionManager.stop()
            momentumTimer?.invalidate()
        }
    }

    /// Starts momentum animation after a spin gesture ends.
    private func startMomentum() {
        momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            if abs(spinVelocity) < 0.1 {
                timer.invalidate()
                return
            }
            spinAngle += spinVelocity

            let angleDelta = abs(spinAngle - lastTickAngle)
            if angleDelta > 8 {
                tickHaptic.impactOccurred(intensity: min(0.6, abs(spinVelocity) * 0.1))
                lastTickAngle = spinAngle
            }

            spinVelocity *= 0.98
        }
    }
}

// MARK: - MotionDataPanel
/// Displays live motion sensor data in a collapsible panel.
struct MotionDataPanel: View {
    @ObservedObject var manager: MotionManager

    var body: some View {
        VStack(spacing: 16) {
            // Attitude section
            VStack(spacing: 8) {
                Text("ATTITUDE")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 20) {
                    AttitudeGauge(label: "Pitch", value: manager.relativePitch, color: .red)
                    AttitudeGauge(label: "Roll", value: manager.relativeRoll, color: .green)
                    AttitudeGauge(label: "Yaw", value: manager.attitude.yaw * 180 / .pi, color: .blue)
                }
            }

            Divider()

            // Sensor data grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SensorCard(
                    title: "Accelerometer",
                    icon: "arrow.up.arrow.down",
                    values: [
                        ("X", manager.acceleration.x),
                        ("Y", manager.acceleration.y),
                        ("Z", manager.acceleration.z)
                    ],
                    color: .orange
                )

                SensorCard(
                    title: "Gyroscope",
                    icon: "gyroscope",
                    values: [
                        ("X", manager.rotation.x),
                        ("Y", manager.rotation.y),
                        ("Z", manager.rotation.z)
                    ],
                    color: .purple
                )
            }

            // Pedometer data
            if manager.isPedometerAvailable {
                Divider()

                HStack(spacing: 20) {
                    PedometerStat(icon: "figure.walk", value: "\(manager.stepCount)", label: "Steps")
                    PedometerStat(icon: "point.topleft.down.to.point.bottomright.curvepath", value: String(format: "%.0fm", manager.distance), label: "Distance")
                    PedometerStat(icon: "flame.fill", value: String(format: "%.0f", manager.floorsAscended), label: "Floors")
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}

// MARK: - AttitudeGauge
/// Circular gauge displaying attitude angles.
struct AttitudeGauge: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: min(abs(value) / 90, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f°", value))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - SensorCard
/// Card displaying 3-axis sensor values.
struct SensorCard: View {
    let title: String
    let icon: String
    let values: [(String, Double)]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            ForEach(values, id: \.0) { axis, value in
                HStack {
                    Text(axis)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 15)
                    Text(String(format: "%+.3f", value))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - PedometerStat
/// Single pedometer statistic display.
struct PedometerStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.cyan)
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - SpinningBarbell
/// 3D barbell visualization with Metal shader and motion-based transforms.
struct SpinningBarbell: View {
    let pitch: Double
    let roll: Double
    let spinAngle: Double
    let size: CGSize

    private let maxTilt: Double = 20

    private var clampedPitch: Double {
        min(max(pitch, -maxTilt), maxTilt)
    }

    private var clampedRoll: Double {
        min(max(roll, -maxTilt), maxTilt)
    }

    private var barbellShader: Shader {
        ShaderLibrary.barbell(
            .float2(size.width, size.height),
            .float(pitch),
            .float(roll),
            .float(spinAngle)
        )
    }

    var body: some View {
        let pitchFactor = clampedPitch / maxTilt
        let depthScale = 1.0 + (pitchFactor * 0.08)

        Rectangle()
            .fill(.white)
            .colorEffect(barbellShader)
            .rotation3DEffect(
                .degrees(clampedPitch * 1.2),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.8
            )
            .rotation3DEffect(
                .degrees(-clampedRoll * 0.8),
                axis: (x: 0, y: 0, z: 1),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(clampedRoll * 0.6),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 50,
                perspective: 0.6
            )
            .scaleEffect(depthScale)
            .offset(y: CGFloat(-pitchFactor * 8))
            .shadow(color: .black.opacity(0.6), radius: 6 + CGFloat(pitchFactor * 4), x: CGFloat(clampedRoll * 0.3), y: 4 + CGFloat(-pitchFactor * 6))
            .shadow(color: .black.opacity(0.4), radius: 20 + CGFloat(pitchFactor * 10), x: CGFloat(clampedRoll * 0.8), y: 12 + CGFloat(-pitchFactor * 12))
            .shadow(color: .black.opacity(0.25), radius: 40 + CGFloat(pitchFactor * 15), x: CGFloat(clampedRoll * 1.5), y: 25 + CGFloat(-pitchFactor * 20))
            .animation(.interactiveSpring(response: 0.08, dampingFraction: 0.75), value: pitch)
            .animation(.interactiveSpring(response: 0.08, dampingFraction: 0.75), value: roll)
    }
}

// MARK: - MotionManager
/// Manages device motion, accelerometer, gyroscope, and pedometer data.
///
/// This class provides:
/// - Real-time motion updates at 60Hz
/// - Calibration for baseline orientation
/// - Pedometer data (steps, distance, floors)
/// - All sensor data (accelerometer, gyroscope, attitude)
@MainActor
class MotionManager: ObservableObject {
    // MARK: Published Properties
    @Published var acceleration: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @Published var rotation: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @Published var attitude: (pitch: Double, roll: Double, yaw: Double) = (0, 0, 0)
    @Published var isActive = true
    @Published var stepCount: Int = 0
    @Published var distance: Double = 0
    @Published var floorsAscended: Double = 0
    @Published var isPedometerAvailable = false

    // MARK: Private Properties
    private let manager = CMMotionManager()
    private let pedometer = CMPedometer()
    private var baselinePitch: Double?
    private var baselineRoll: Double?

    /// Pitch relative to calibrated baseline, in degrees.
    var relativePitch: Double {
        guard let baseline = baselinePitch else { return 0 }
        return (attitude.pitch - baseline) * 180 / .pi
    }

    /// Roll relative to calibrated baseline, in degrees.
    var relativeRoll: Double {
        guard let baseline = baselineRoll else { return 0 }
        return (attitude.roll - baseline) * 180 / .pi
    }

    // MARK: Public Methods

    /// Calibrates the current orientation as the baseline.
    func calibrate() {
        baselinePitch = attitude.pitch
        baselineRoll = attitude.roll
    }

    /// Starts all motion updates.
    func start() {
        startDeviceMotion()
        startPedometer()
    }

    /// Stops all motion updates.
    func stop() {
        manager.stopDeviceMotionUpdates()
        pedometer.stopUpdates()
    }

    // MARK: Private Methods

    private func startDeviceMotion() {
        guard manager.isDeviceMotionAvailable else { return }

        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion = motion else { return }
            Task { @MainActor in
                self?.acceleration = (
                    motion.userAcceleration.x,
                    motion.userAcceleration.y,
                    motion.userAcceleration.z
                )
                self?.rotation = (
                    motion.rotationRate.x,
                    motion.rotationRate.y,
                    motion.rotationRate.z
                )
                self?.attitude = (
                    motion.attitude.pitch,
                    motion.attitude.roll,
                    motion.attitude.yaw
                )

                if self?.baselinePitch == nil {
                    self?.calibrate()
                }
            }
        }
    }

    private func startPedometer() {
        isPedometerAvailable = CMPedometer.isStepCountingAvailable()

        guard isPedometerAvailable else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())

        pedometer.startUpdates(from: startOfDay) { [weak self] data, _ in
            guard let data = data else { return }
            Task { @MainActor in
                self?.stepCount = data.numberOfSteps.intValue
                self?.distance = data.distance?.doubleValue ?? 0
                self?.floorsAscended = data.floorsAscended?.doubleValue ?? 0
            }
        }
    }
}

// MARK: - Legacy Support Views
struct DataSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct DataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        MotionView()
    }
}
