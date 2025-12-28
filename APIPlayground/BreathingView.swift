import SwiftUI
import ActivityKit

/// Demonstrates Live Activity for guided breathing exercises
/// Key insight: The 5-15 second update rate is a FEATURE for breathing cycles
struct BreathingView: View {
    @StateObject private var manager = BreathingActivityManager()
    @State private var selectedPattern: BreathingPattern = .boxBreathing
    @State private var sessionMinutes: Int = 5
    @State private var totalCycles: Int = 10

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Card
                statusCard

                // Live Preview
                if manager.isActive {
                    livePreviewCard
                }

                // Pattern Selection
                patternSelectionCard

                // Session Configuration
                configurationCard

                // Controls
                controlsCard

                // Info
                infoCard
            }
            .padding()
        }
        .navigationTitle("Breath Pacer")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: manager.isActive ? "lungs.fill" : "lungs")
                        .foregroundStyle(manager.isActive ? .green : .secondary)
                        .font(.title2)
                    Text(manager.isActive ? "Session Active" : "Ready to Begin")
                        .font(.headline)
                    Spacer()
                    if manager.isActive {
                        Text("Cycle \(manager.currentCycle)/\(manager.totalCycles)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if manager.isActive {
                    // Current phase display
                    HStack(spacing: 16) {
                        Image(systemName: manager.currentPhase.icon)
                            .font(.largeTitle)
                            .foregroundStyle(phaseColor(manager.currentPhase))

                        VStack(alignment: .leading) {
                            Text(manager.currentPhase.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(manager.currentPhase.instruction)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(manager.secondsRemaining)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(phaseColor(manager.currentPhase))
                    }
                    .padding(.vertical, 8)
                }

                // ActivityKit status
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text(manager.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Status", systemImage: "waveform.path")
        }
    }

    // MARK: - Live Preview Card
    private var livePreviewCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Animated breathing circle
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(lineWidth: 8)
                        .opacity(0.2)
                        .foregroundStyle(phaseColor(manager.currentPhase))

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: manager.phaseProgress)
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .foregroundStyle(phaseColor(manager.currentPhase))
                        .rotationEffect(.degrees(-90))

                    // Inner breathing circle
                    Circle()
                        .fill(phaseColor(manager.currentPhase).opacity(0.3))
                        .frame(width: breathingCircleSize, height: breathingCircleSize)
                        .animation(.easeInOut(duration: 0.5), value: manager.phaseProgress)

                    // Phase icon
                    Image(systemName: manager.currentPhase.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(phaseColor(manager.currentPhase))
                }
                .frame(width: 160, height: 160)
                .animation(.easeInOut(duration: 0.3), value: manager.currentPhase)

                // Pattern info
                HStack {
                    Image(systemName: selectedPattern.icon)
                    Text(selectedPattern.rawValue)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } label: {
            Label("Breathing Guide", systemImage: "circle.circle")
        }
    }

    private var breathingCircleSize: CGFloat {
        let minSize: CGFloat = 40
        let maxSize: CGFloat = 120

        switch manager.currentPhase {
        case .inhale:
            return minSize + (maxSize - minSize) * manager.phaseProgress
        case .holdIn:
            return maxSize
        case .exhale:
            return maxSize - (maxSize - minSize) * manager.phaseProgress
        case .holdOut:
            return minSize
        }
    }

    // MARK: - Pattern Selection Card
    private var patternSelectionCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                ForEach(BreathingPattern.allCases, id: \.self) { pattern in
                    Button {
                        selectedPattern = pattern
                    } label: {
                        HStack {
                            Image(systemName: pattern.icon)
                                .font(.title2)
                                .frame(width: 40)
                                .foregroundStyle(pattern == selectedPattern ? .white : .blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(pattern.rawValue)
                                    .font(.headline)
                                Text(pattern.description)
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            .foregroundStyle(pattern == selectedPattern ? .white : .primary)

                            Spacer()

                            if pattern == selectedPattern {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(pattern == selectedPattern ? Color.blue : Color.secondary.opacity(0.1))
                        )
                    }
                    .disabled(manager.isActive)
                }
            }
        } label: {
            Label("Breathing Pattern", systemImage: "slider.horizontal.3")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Session duration
                HStack {
                    Text("Session Duration")
                    Spacer()
                    Picker("Minutes", selection: $sessionMinutes) {
                        ForEach([1, 2, 3, 5, 10, 15, 20], id: \.self) { mins in
                            Text("\(mins) min").tag(mins)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(manager.isActive)
                }

                // Total cycles
                HStack {
                    Text("Target Cycles")
                    Spacer()
                    Stepper("\(totalCycles)", value: $totalCycles, in: 3...50)
                        .disabled(manager.isActive)
                }

                // Timing preview
                let timing = selectedPattern.timing
                HStack(spacing: 8) {
                    TimingBadge(label: "In", seconds: timing.inhale, color: .blue)
                    if timing.holdIn > 0 {
                        TimingBadge(label: "Hold", seconds: timing.holdIn, color: .purple)
                    }
                    TimingBadge(label: "Out", seconds: timing.exhale, color: .green)
                    if timing.holdOut > 0 {
                        TimingBadge(label: "Rest", seconds: timing.holdOut, color: .gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        } label: {
            Label("Configuration", systemImage: "gearshape")
        }
    }

    // MARK: - Controls Card
    private var controlsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                if !manager.isActive {
                    Button {
                        manager.startSession(
                            pattern: selectedPattern,
                            totalCycles: totalCycles,
                            sessionMinutes: sessionMinutes
                        )
                    } label: {
                        Label("Start Breathing Session", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button {
                            manager.togglePause()
                        } label: {
                            Label(manager.isPaused ? "Resume" : "Pause",
                                  systemImage: manager.isPaused ? "play.fill" : "pause.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.orange, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }

                        Button {
                            manager.endSession()
                        } label: {
                            Label("End", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.red, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        } label: {
            Label("Controls", systemImage: "play.rectangle")
        }
    }

    // MARK: - Info Card
    private var infoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                BreathingInfoRow(title: "Framework", value: "ActivityKit")
                BreathingInfoRow(title: "Update Rate", value: "~1 second (local)")
                BreathingInfoRow(title: "Max Duration", value: "8 hours")

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Why Breathing + Live Activity?")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("Live Activities update every 5-15 seconds remotely, but locally can update faster. This constraint is actually perfect for breathing exercises where cycles are 4-8 seconds. The Dynamic Island's organic, 'living' design philosophy matches breathing visualization beautifully.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        } label: {
            Label("About This Demo", systemImage: "info.circle")
        }
    }

    private func phaseColor(_ phase: BreathingPhase) -> Color {
        switch phase {
        case .inhale: return .blue
        case .holdIn: return .purple
        case .exhale: return .green
        case .holdOut: return .gray
        }
    }
}

// MARK: - Supporting Views

struct TimingBadge: View {
    let label: String
    let seconds: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(seconds)s")
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(color)
    }
}

struct BreathingInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Breathing Activity Manager

@MainActor
class BreathingActivityManager: ObservableObject {
    @Published var isActive = false
    @Published var isPaused = false
    @Published var currentPhase: BreathingPhase = .inhale
    @Published var secondsRemaining: Int = 4
    @Published var currentCycle: Int = 1
    @Published var totalCycles: Int = 10
    @Published var phaseProgress: Double = 0
    @Published var statusMessage = "Ready to start breathing session"

    private var currentActivity: Activity<BreathingActivityAttributes>?
    private var timer: Timer?
    private var pattern: BreathingPattern = .boxBreathing
    private var phaseTotal: Int = 4
    private var sessionStartTime: Date = Date()

    init() {
        checkExistingActivities()
    }

    private func checkExistingActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<BreathingActivityAttributes>.activities {
                currentActivity = activity
                isActive = true
                pattern = activity.attributes.pattern
                updateFromState(activity.content.state)
                statusMessage = "Resumed existing session"
                startTimer()
                break
            }
        }
    }

    private func updateFromState(_ state: BreathingActivityAttributes.ContentState) {
        currentPhase = state.phase
        secondsRemaining = state.secondsRemaining
        phaseTotal = state.phaseTotal
        currentCycle = state.currentCycle
        totalCycles = state.totalCycles
        isPaused = state.isPaused
        phaseProgress = 1.0 - (Double(secondsRemaining) / Double(phaseTotal))
    }

    func startSession(pattern: BreathingPattern, totalCycles: Int, sessionMinutes: Int) {
        guard #available(iOS 16.1, *) else {
            statusMessage = "Requires iOS 16.1+"
            return
        }

        self.pattern = pattern
        self.totalCycles = totalCycles
        self.currentCycle = 1
        self.currentPhase = .inhale
        self.phaseTotal = pattern.duration(for: .inhale)
        self.secondsRemaining = phaseTotal
        self.sessionStartTime = Date()
        self.isPaused = false

        let attributes = BreathingActivityAttributes(
            pattern: pattern,
            sessionMinutes: sessionMinutes
        )

        let initialState = BreathingActivityAttributes.ContentState(
            phase: .inhale,
            secondsRemaining: phaseTotal,
            phaseTotal: phaseTotal,
            currentCycle: 1,
            totalCycles: totalCycles,
            sessionStartTime: sessionStartTime,
            isPaused: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isActive = true
            statusMessage = "Session started - \(pattern.rawValue)"

            startTimer()

            print("[Breathing] Started activity: \(activity.id)")
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
            print("[Breathing] Failed to start: \(error)")
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard !isPaused else { return }

        secondsRemaining -= 1
        phaseProgress = 1.0 - (Double(secondsRemaining) / Double(phaseTotal))

        if secondsRemaining <= 0 {
            advancePhase()
        }

        updateActivity()
    }

    private func advancePhase() {
        let nextPhase = pattern.nextPhase(after: currentPhase)

        // Check if we completed a cycle
        if pattern.isNewCycle(phase: nextPhase) && currentPhase != .inhale {
            currentCycle += 1
            if currentCycle > totalCycles {
                endSession()
                return
            }
        }

        currentPhase = nextPhase
        phaseTotal = pattern.duration(for: nextPhase)
        secondsRemaining = phaseTotal
        phaseProgress = 0
    }

    private func updateActivity() {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let updatedState = BreathingActivityAttributes.ContentState(
            phase: currentPhase,
            secondsRemaining: secondsRemaining,
            phaseTotal: phaseTotal,
            currentCycle: currentCycle,
            totalCycles: totalCycles,
            sessionStartTime: sessionStartTime,
            isPaused: isPaused
        )

        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }

    func togglePause() {
        isPaused.toggle()
        statusMessage = isPaused ? "Session paused" : "Session resumed"
        updateActivity()
    }

    func endSession() {
        timer?.invalidate()
        timer = nil

        guard #available(iOS 16.1, *),
              let activity = currentActivity else {
            isActive = false
            return
        }

        let finalState = BreathingActivityAttributes.ContentState(
            phase: currentPhase,
            secondsRemaining: 0,
            phaseTotal: phaseTotal,
            currentCycle: currentCycle,
            totalCycles: totalCycles,
            sessionStartTime: sessionStartTime,
            isPaused: false
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                isActive = false
                currentActivity = nil
                statusMessage = "Session complete - \(currentCycle - 1) cycles"
            }
        }
    }
}

#Preview {
    NavigationStack {
        BreathingView()
    }
}
