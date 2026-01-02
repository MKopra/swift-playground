import SwiftUI
import CoreMotion

struct WatchMotionView: View {
    @StateObject private var motionManager = WatchMotionManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Status
                statusSection

                // Accelerometer
                accelerometerSection

                // Gyroscope
                gyroscopeSection

                // Device Motion
                deviceMotionSection

                // Controls
                controlsSection
            }
            .padding(.horizontal)
        }
        .navigationTitle("Motion")
        .onDisappear {
            motionManager.stopUpdates()
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack {
            Image(systemName: motionManager.isRunning ? "gyroscope" : "gyroscope")
                .foregroundStyle(motionManager.isRunning ? .green : .secondary)
                .symbolEffect(.pulse, isActive: motionManager.isRunning)

            Text(motionManager.isRunning ? "Active" : "Stopped")
                .font(.caption2)
                .fontWeight(.medium)

            Spacer()

            if motionManager.isRunning {
                Text("60 Hz")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Accelerometer

    private var accelerometerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "move.3d")
                    .foregroundStyle(.blue)
                Text("Accelerometer")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            HStack(spacing: 12) {
                axisView(label: "X", value: motionManager.accelerometerData.x, color: .red)
                axisView(label: "Y", value: motionManager.accelerometerData.y, color: .green)
                axisView(label: "Z", value: motionManager.accelerometerData.z, color: .blue)
            }
        }
        .padding(8)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Gyroscope

    private var gyroscopeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "rotate.3d")
                    .foregroundStyle(.orange)
                Text("Gyroscope")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            HStack(spacing: 12) {
                axisView(label: "X", value: motionManager.gyroData.x, color: .red)
                axisView(label: "Y", value: motionManager.gyroData.y, color: .green)
                axisView(label: "Z", value: motionManager.gyroData.z, color: .blue)
            }
        }
        .padding(8)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Device Motion

    private var deviceMotionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "iphone.gen3")
                    .foregroundStyle(.purple)
                Text("Attitude")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("Roll")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f°", motionManager.attitude.roll * 180 / .pi))
                        .font(.caption)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("Pitch")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f°", motionManager.attitude.pitch * 180 / .pi))
                        .font(.caption)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("Yaw")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f°", motionManager.attitude.yaw * 180 / .pi))
                        .font(.caption)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(8)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Controls

    private var controlsSection: some View {
        Button {
            if motionManager.isRunning {
                motionManager.stopUpdates()
            } else {
                motionManager.startUpdates()
            }
        } label: {
            HStack {
                Image(systemName: motionManager.isRunning ? "stop.fill" : "play.fill")
                Text(motionManager.isRunning ? "Stop" : "Start")
            }
            .font(.caption)
        }
        .buttonStyle(.borderedProminent)
        .tint(motionManager.isRunning ? .red : .green)
    }

    // MARK: - Helper Views

    private func axisView(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(color)
            Text(String(format: "%.2f", value))
                .font(.caption)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Watch Motion Manager

class WatchMotionManager: ObservableObject {
    @Published var isRunning = false
    @Published var accelerometerData: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @Published var gyroData: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @Published var attitude: (roll: Double, pitch: Double, yaw: Double) = (0, 0, 0)

    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1.0 / 60.0

    func startUpdates() {
        guard !isRunning else { return }
        isRunning = true

        // Accelerometer
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = updateInterval
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.accelerometerData = (data.acceleration.x, data.acceleration.y, data.acceleration.z)
            }
        }

        // Gyroscope
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = updateInterval
            motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.gyroData = (data.rotationRate.x, data.rotationRate.y, data.rotationRate.z)
            }
        }

        // Device Motion
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = updateInterval
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.attitude = (data.attitude.roll, data.attitude.pitch, data.attitude.yaw)
            }
        }
    }

    func stopUpdates() {
        isRunning = false
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
    }
}

#Preview {
    NavigationStack {
        WatchMotionView()
    }
}
