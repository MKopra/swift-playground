import SwiftUI
import UIKit

// MARK: - ProximityView
/// A comprehensive proximity sensor interface with screen dimming and event logging.
///
/// Features:
/// - Real-time proximity detection visualization
/// - Screen brightness dimming when object detected
/// - Event logging with timestamps
/// - Detection statistics (count, duration, average)
/// - Sonar-style animated visualization
/// - Haptic feedback on state changes
/// - Configurable auto-dim behavior
///
/// APIs Demonstrated:
/// - UIDevice.proximityStateDidChangeNotification
/// - UIScreen.main.brightness for screen dimming
/// - NotificationCenter for proximity events
/// - Timer for duration tracking
struct ProximityView: View {
    @StateObject private var proximity = ProximityManager()
    @State private var pulseScale: CGFloat = 1.0
    @State private var showingHistory = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            // Background changes based on proximity and auto-dim
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: proximity.isNear)

            // Sonar waves
            if proximity.isMonitoring {
                SonarWaves(isNear: proximity.isNear)
            }

            VStack(spacing: 24) {
                // Top toolbar
                HStack {
                    // Settings button
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Spacer()

                    // Auto-dim indicator
                    if proximity.autoDimEnabled {
                        Label("Auto-Dim", systemImage: "moon.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    Spacer()

                    // History button
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Proximity sensor visualization
                ZStack {
                    // Outer detection rings
                    ForEach(0..<4, id: \.self) { ring in
                        Circle()
                            .stroke(
                                proximity.isNear
                                    ? Color.red.opacity(0.3 - Double(ring) * 0.07)
                                    : Color.green.opacity(0.3 - Double(ring) * 0.07),
                                lineWidth: 3
                            )
                            .frame(
                                width: 180 + CGFloat(ring) * 40,
                                height: 180 + CGFloat(ring) * 40
                            )
                    }

                    // Main sensor circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: proximity.isNear
                                    ? [.red, Color(red: 0.5, green: 0, blue: 0)]
                                    : [.green, Color(red: 0, green: 0.3, blue: 0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .shadow(
                            color: (proximity.isNear ? Color.red : Color.green).opacity(0.5),
                            radius: 30
                        )
                        .scaleEffect(pulseScale)

                    // IR emitter visualization
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(proximity.isMonitoring ? 0.8 : 0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .offset(y: -30)

                    // Sensor icon
                    Image(systemName: proximity.isNear ? "hand.raised.fill" : "sensor.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                        .offset(y: 20)

                    // Current duration indicator
                    if proximity.isNear {
                        Text(formatDuration(proximity.currentDetectionDuration))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.3), in: Capsule())
                            .offset(y: 70)
                    }
                }

                // Status text
                VStack(spacing: 8) {
                    Text(proximity.isNear ? "OBJECT DETECTED" : "CLEAR")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(proximity.isNear ? .red : .green)

                    Text(proximity.isNear
                         ? "Something is near the sensor"
                         : proximity.isMonitoring ? "No objects detected nearby" : "Start monitoring to detect objects")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Statistics panel
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ProximityStatBox(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Status",
                            value: proximity.isMonitoring ? "Active" : "Inactive",
                            color: proximity.isMonitoring ? .green : .gray
                        )

                        ProximityStatBox(
                            icon: "number",
                            title: "Detections",
                            value: "\(proximity.stateChangeCount)",
                            color: .blue
                        )

                        ProximityStatBox(
                            icon: "timer",
                            title: "Total Time",
                            value: formatDuration(proximity.totalDetectionTime),
                            color: .orange
                        )
                    }

                    // Recent event
                    if let lastEvent = proximity.events.last {
                        HStack {
                            Image(systemName: lastEvent.isNear ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundStyle(lastEvent.isNear ? .red : .green)

                            Text("Last: \(lastEvent.isNear ? "Detected" : "Cleared")")
                                .font(.caption)

                            Spacer()

                            Text(lastEvent.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                // Control button
                Button(action: {
                    if proximity.isMonitoring {
                        proximity.stopMonitoring()
                    } else {
                        proximity.startMonitoring()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: proximity.isMonitoring ? "stop.fill" : "play.fill")
                        Text(proximity.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(proximity.isMonitoring ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Proximity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            startPulseAnimation()
        }
        .onDisappear {
            proximity.stopMonitoring()
        }
        .onChange(of: proximity.isNear) { _, newValue in
            // Haptic feedback on state change
            if proximity.hapticEnabled {
                let generator = UIImpactFeedbackGenerator(style: newValue ? .heavy : .light)
                generator.impactOccurred()
            }
        }
        .sheet(isPresented: $showingHistory) {
            ProximityHistoryView(events: proximity.events)
        }
        .sheet(isPresented: $showingSettings) {
            ProximitySettingsView(manager: proximity)
        }
    }

    private var backgroundColor: Color {
        if proximity.isNear && proximity.autoDimEnabled {
            return .black
        } else if proximity.isNear {
            return Color(white: 0.05)
        } else {
            return Color(white: 0.1)
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else if seconds < 3600 {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return String(format: "%dm %ds", mins, secs)
        } else {
            let hours = Int(seconds) / 3600
            let mins = (Int(seconds) % 3600) / 60
            return String(format: "%dh %dm", hours, mins)
        }
    }
}

// MARK: - SonarWaves
/// Animated sonar wave visualization.
struct SonarWaves: View {
    let isNear: Bool
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        isNear ? Color.red.opacity(0.3) : Color.green.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(animate ? 2.5 : 1.0)
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 2)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.6),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - ProximityStatBox
/// Statistics display box for proximity view.
struct ProximityStatBox: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ProximityHistoryView
/// Displays proximity event history.
struct ProximityHistoryView: View {
    let events: [ProximityEvent]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No Events",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Proximity events will appear here")
                    )
                } else {
                    List {
                        ForEach(events.reversed()) { event in
                            HStack(spacing: 12) {
                                // Event type indicator
                                Circle()
                                    .fill(event.isNear ? Color.red : Color.green)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.isNear ? "Object Detected" : "Object Removed")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    if let duration = event.duration, !event.isNear {
                                        Text("Duration: \(formatDuration(duration))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Event History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.1f seconds", seconds)
        } else {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return String(format: "%d min %d sec", mins, secs)
        }
    }
}

// MARK: - ProximitySettingsView
/// Settings for proximity monitoring.
struct ProximitySettingsView: View {
    @ObservedObject var manager: ProximityManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Behavior") {
                    Toggle(isOn: $manager.autoDimEnabled) {
                        Label("Auto-Dim Screen", systemImage: "moon.fill")
                    }

                    Toggle(isOn: $manager.hapticEnabled) {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Auto-Dim simulates phone call behavior where the screen dims when the device is near your face.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Note: Actual screen brightness is managed by the system on iOS. This demo simulates the effect with a dark overlay.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Statistics") {
                    LabeledContent("Total Detections", value: "\(manager.stateChangeCount)")
                    LabeledContent("Total Detection Time", value: formatDuration(manager.totalDetectionTime))
                    if manager.stateChangeCount > 0 {
                        LabeledContent("Avg Detection Duration", value: formatDuration(manager.averageDetectionDuration))
                    }
                    LabeledContent("Events Logged", value: "\(manager.events.count)")
                }

                Section {
                    Button(role: .destructive, action: {
                        manager.clearHistory()
                    }) {
                        Label("Clear History", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.1f sec", seconds)
        } else if seconds < 3600 {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return String(format: "%d min %d sec", mins, secs)
        } else {
            let hours = Int(seconds) / 3600
            let mins = (Int(seconds) % 3600) / 60
            return String(format: "%d hr %d min", hours, mins)
        }
    }
}

// MARK: - ProximityEvent
/// Represents a proximity state change event.
struct ProximityEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let isNear: Bool
    var duration: TimeInterval?
}

// MARK: - ProximityManager
/// Manages proximity sensor monitoring and event logging.
///
/// This class provides:
/// - Real-time proximity state monitoring
/// - Event history with timestamps and durations
/// - Statistics tracking (count, total time, averages)
/// - Configurable auto-dim and haptic feedback
/// - Detection duration tracking
@MainActor
class ProximityManager: ObservableObject {
    // MARK: Published Properties
    @Published var isNear = false
    @Published var isMonitoring = false
    @Published var stateChangeCount = 0
    @Published var events: [ProximityEvent] = []
    @Published var totalDetectionTime: TimeInterval = 0
    @Published var currentDetectionDuration: TimeInterval = 0
    @Published var autoDimEnabled = true
    @Published var hapticEnabled = true

    // MARK: Private Properties
    private var detectionStartTime: Date?
    private var durationTimer: Timer?
    private var observer: NSObjectProtocol?
    private let originalBrightness: CGFloat

    // MARK: Computed Properties

    /// Average duration of proximity detections.
    var averageDetectionDuration: TimeInterval {
        let detectionEvents = events.filter { !$0.isNear && $0.duration != nil }
        guard !detectionEvents.isEmpty else { return 0 }
        let totalDuration = detectionEvents.compactMap { $0.duration }.reduce(0, +)
        return totalDuration / Double(detectionEvents.count)
    }

    // MARK: Initialization

    init() {
        originalBrightness = UIScreen.main.brightness
    }

    // MARK: Public Methods

    /// Starts proximity monitoring.
    func startMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = true
        isMonitoring = true

        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleProximityChange()
        }
    }

    /// Stops proximity monitoring.
    func stopMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = false
        isMonitoring = false

        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }

        // End any current detection
        if isNear {
            endDetection()
        }

        isNear = false
        stopDurationTimer()
    }

    /// Clears all event history and statistics.
    func clearHistory() {
        events.removeAll()
        stateChangeCount = 0
        totalDetectionTime = 0
    }

    // MARK: Private Methods

    private func handleProximityChange() {
        let newState = UIDevice.current.proximityState
        isNear = newState
        stateChangeCount += 1

        if newState {
            startDetection()
        } else {
            endDetection()
        }
    }

    private func startDetection() {
        detectionStartTime = Date()
        currentDetectionDuration = 0
        events.append(ProximityEvent(timestamp: Date(), isNear: true))
        startDurationTimer()
    }

    private func endDetection() {
        stopDurationTimer()

        guard let startTime = detectionStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        totalDetectionTime += duration

        var endEvent = ProximityEvent(timestamp: Date(), isNear: false)
        endEvent.duration = duration
        events.append(endEvent)

        detectionStartTime = nil
        currentDetectionDuration = 0
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.detectionStartTime else { return }
                self.currentDetectionDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
}

#Preview {
    NavigationStack {
        ProximityView()
    }
}
