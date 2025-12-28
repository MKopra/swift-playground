import SwiftUI
import CoreHaptics

// MARK: - HapticsView
/// An interactive haptics playground demonstrating Core Haptics capabilities.
///
/// Features:
/// - All UIKit feedback generator types (impact, notification, selection)
/// - Core Haptics custom pattern builder
/// - Visual haptic pattern timeline
/// - Intensity and sharpness controls
/// - Preset haptic patterns (heartbeat, drums, notification sequences)
/// - Real-time haptic preview
///
/// APIs Demonstrated:
/// - UIImpactFeedbackGenerator for impact haptics
/// - UINotificationFeedbackGenerator for notification haptics
/// - UISelectionFeedbackGenerator for selection haptics
/// - CHHapticEngine for custom haptic patterns
/// - CHHapticPattern for complex haptic sequences
struct HapticsView: View {
    @StateObject private var haptics = HapticsManager()
    @State private var selectedTab = 0
    @State private var customIntensity: Float = 0.8
    @State private var customSharpness: Float = 0.5
    @State private var customDuration: Float = 0.3

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Tab selector
                Picker("Category", selection: $selectedTab) {
                    Text("Standard").tag(0)
                    Text("Custom").tag(1)
                    Text("Presets").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedTab {
                case 0:
                    standardHapticsSection
                case 1:
                    customHapticsSection
                case 2:
                    presetsSection
                default:
                    EmptyView()
                }

                // Engine status
                HStack {
                    Circle()
                        .fill(haptics.isEngineReady ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(haptics.isEngineReady ? "Haptic Engine Ready" : "Haptic Engine Unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Haptics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { haptics.prepareEngine() }
        .onDisappear { haptics.stopEngine() }
    }

    // MARK: - Standard Haptics Section
    private var standardHapticsSection: some View {
        VStack(spacing: 20) {
            // Impact feedback
            GroupBox {
                VStack(spacing: 12) {
                    Label("Impact Feedback", systemImage: "hand.tap.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Simulates physical impacts with varying intensity.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ImpactButton(style: .light, label: "Light", icon: "1.circle")
                        ImpactButton(style: .medium, label: "Medium", icon: "2.circle")
                        ImpactButton(style: .heavy, label: "Heavy", icon: "3.circle")
                        ImpactButton(style: .soft, label: "Soft", icon: "cloud")
                        ImpactButton(style: .rigid, label: "Rigid", icon: "square.fill")
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal)

            // Notification feedback
            GroupBox {
                VStack(spacing: 12) {
                    Label("Notification Feedback", systemImage: "bell.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Communicates success, warning, or error states.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        NotificationButton(type: .success, label: "Success", color: .green)
                        NotificationButton(type: .warning, label: "Warning", color: .orange)
                        NotificationButton(type: .error, label: "Error", color: .red)
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal)

            // Selection feedback
            GroupBox {
                VStack(spacing: 12) {
                    Label("Selection Feedback", systemImage: "hand.point.up.left.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Subtle feedback for UI selection changes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        UISelectionFeedbackGenerator().selectionChanged()
                    }) {
                        Label("Selection Changed", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Custom Haptics Section
    private var customHapticsSection: some View {
        VStack(spacing: 20) {
            GroupBox {
                VStack(spacing: 16) {
                    Label("Custom Haptic Event", systemImage: "waveform.path")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Intensity slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Intensity")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.0f%%", customIntensity * 100))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $customIntensity, in: 0.1...1.0)
                            .tint(.blue)

                        // Visual representation
                        HapticVisualizer(intensity: customIntensity, sharpness: customSharpness)
                            .frame(height: 60)
                    }

                    // Sharpness slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Sharpness")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.0f%%", customSharpness * 100))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $customSharpness, in: 0...1.0)
                            .tint(.orange)

                        HStack {
                            Text("Dull")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Sharp")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Duration slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.2fs", customDuration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $customDuration, in: 0.05...1.0)
                            .tint(.green)
                    }

                    // Play button
                    Button(action: {
                        haptics.playCustomHaptic(
                            intensity: customIntensity,
                            sharpness: customSharpness,
                            duration: TimeInterval(customDuration)
                        )
                    }) {
                        Label("Play Custom Haptic", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    .disabled(!haptics.isEngineReady)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Presets Section
    private var presetsSection: some View {
        VStack(spacing: 16) {
            ForEach(HapticPreset.allCases) { preset in
                PresetButton(preset: preset, haptics: haptics)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - ImpactButton
/// Button that triggers impact haptic feedback.
struct ImpactButton: View {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let label: String
    let icon: String

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }) {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NotificationButton
/// Button that triggers notification haptic feedback.
struct NotificationButton: View {
    let type: UINotificationFeedbackGenerator.FeedbackType
    let label: String
    let color: Color

    var body: some View {
        Button(action: {
            UINotificationFeedbackGenerator().notificationOccurred(type)
        }) {
            VStack(spacing: 8) {
                Image(systemName: iconForType)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    private var iconForType: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        @unknown default: return "circle"
        }
    }
}

// MARK: - HapticVisualizer
/// Visual representation of haptic intensity and sharpness.
struct HapticVisualizer: View {
    let intensity: Float
    let sharpness: Float

    var body: some View {
        GeometryReader { geo in
            let barCount = 20
            let spacing: CGFloat = 2

            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { i in
                    let normalizedPosition = Float(i) / Float(barCount - 1)
                    let envelope = sin(Float.pi * normalizedPosition) * intensity

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(Double(sharpness)),
                                    Color.cyan
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: max(4, CGFloat(envelope) * geo.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: - PresetButton
/// Button for playing preset haptic patterns.
struct PresetButton: View {
    let preset: HapticPreset
    let haptics: HapticsManager

    var body: some View {
        Button(action: { haptics.playPreset(preset) }) {
            HStack {
                Image(systemName: preset.icon)
                    .font(.title2)
                    .frame(width: 40)
                    .foregroundStyle(preset.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.headline)
                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!haptics.isEngineReady)
    }
}

// MARK: - HapticPreset
/// Predefined haptic patterns.
enum HapticPreset: String, CaseIterable, Identifiable {
    case heartbeat
    case drums
    case notification
    case engine
    case countdown
    case celebration

    var id: String { rawValue }

    var name: String {
        switch self {
        case .heartbeat: return "Heartbeat"
        case .drums: return "Drum Roll"
        case .notification: return "Notification"
        case .engine: return "Engine Rev"
        case .countdown: return "Countdown"
        case .celebration: return "Celebration"
        }
    }

    var description: String {
        switch self {
        case .heartbeat: return "Pulsing heartbeat rhythm"
        case .drums: return "Rapid drum pattern"
        case .notification: return "Alert sequence"
        case .engine: return "Revving motor feel"
        case .countdown: return "3-2-1 countdown"
        case .celebration: return "Victory pattern"
        }
    }

    var icon: String {
        switch self {
        case .heartbeat: return "heart.fill"
        case .drums: return "music.note.list"
        case .notification: return "bell.badge.fill"
        case .engine: return "car.fill"
        case .countdown: return "timer"
        case .celebration: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .heartbeat: return .red
        case .drums: return .orange
        case .notification: return .blue
        case .engine: return .gray
        case .countdown: return .purple
        case .celebration: return .yellow
        }
    }
}

// MARK: - HapticsManager
/// Manages Core Haptics engine and pattern playback.
///
/// This class provides:
/// - Core Haptics engine lifecycle management
/// - Custom haptic event creation
/// - Preset pattern playback
/// - Engine state monitoring
@MainActor
class HapticsManager: ObservableObject {
    @Published var isEngineReady = false

    private var engine: CHHapticEngine?

    /// Prepares the haptic engine for playback.
    func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }

        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    try? self?.engine?.start()
                }
            }
            engine?.stoppedHandler = { [weak self] _ in
                Task { @MainActor in
                    self?.isEngineReady = false
                }
            }

            try engine?.start()
            isEngineReady = true
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    /// Stops the haptic engine.
    func stopEngine() {
        engine?.stop()
        isEngineReady = false
    }

    /// Plays a custom haptic event with specified parameters.
    /// - Parameters:
    ///   - intensity: Haptic strength (0.0-1.0)
    ///   - sharpness: Haptic texture (0.0=dull, 1.0=sharp)
    ///   - duration: Event duration in seconds
    func playCustomHaptic(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard let engine = engine, isEngineReady else { return }

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0,
            duration: duration
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }

    /// Plays a preset haptic pattern.
    func playPreset(_ preset: HapticPreset) {
        guard let engine = engine, isEngineReady else { return }

        let events: [CHHapticEvent]

        switch preset {
        case .heartbeat:
            events = createHeartbeatPattern()
        case .drums:
            events = createDrumPattern()
        case .notification:
            events = createNotificationPattern()
        case .engine:
            events = createEnginePattern()
        case .countdown:
            events = createCountdownPattern()
        case .celebration:
            events = createCelebrationPattern()
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play preset: \(error)")
        }
    }

    // MARK: - Pattern Generators

    private func createHeartbeatPattern() -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        for i in 0..<4 {
            let baseTime = Double(i) * 0.8
            // First beat
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: baseTime
            ))
            // Second beat
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: baseTime + 0.15
            ))
        }
        return events
    }

    private func createDrumPattern() -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        for i in 0..<16 {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: i % 4 == 0 ? 1.0 : 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: Double(i) * 0.1
            ))
        }
        return events
    }

    private func createNotificationPattern() -> [CHHapticEvent] {
        return [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ], relativeTime: 0.15),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ], relativeTime: 0.3)
        ]
    }

    private func createEnginePattern() -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        for i in 0..<20 {
            let intensity = Float(i) / 20.0
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3 + intensity * 0.4)
                ],
                relativeTime: Double(i) * 0.1,
                duration: 0.1
            ))
        }
        return events
    }

    private func createCountdownPattern() -> [CHHapticEvent] {
        return [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0.5),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 1.0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ], relativeTime: 1.5, duration: 0.5)
        ]
    }

    private func createCelebrationPattern() -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        for i in 0..<10 {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float.random(in: 0.5...1.0)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: Float.random(in: 0.3...0.9))
                ],
                relativeTime: Double(i) * 0.1 + Double.random(in: 0...0.05)
            ))
        }
        return events
    }
}

#Preview {
    NavigationStack {
        HapticsView()
    }
}
