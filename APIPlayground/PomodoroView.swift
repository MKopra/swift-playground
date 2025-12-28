import SwiftUI
import ActivityKit

/// Pomodoro Focus Timer - 25/5 work-break cycles
/// Uses Live Activity to keep focus visible on Lock Screen
struct PomodoroView: View {
    @StateObject private var manager = PomodoroActivityManager()
    @State private var workMinutes: Int = 25
    @State private var breakMinutes: Int = 5
    @State private var totalSessions: Int = 4
    @State private var taskName: String = "Deep Work"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusCard
                if manager.isActive {
                    timerCard
                }
                configurationCard
                controlsCard
                infoCard
            }
            .padding()
        }
        .navigationTitle("Pomodoro Focus")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: manager.isActive ? "timer" : "timer.circle")
                        .foregroundStyle(manager.isActive ? (manager.isWorkPhase ? .red : .green) : .secondary)
                        .font(.title2)
                    Text(manager.isActive ? (manager.isWorkPhase ? "Work Time" : "Break Time") : "Ready to Focus")
                        .font(.headline)
                    Spacer()
                    if manager.isActive {
                        Text("Session \(manager.currentSession)/\(manager.totalSessions)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if manager.isActive {
                    HStack {
                        Image(systemName: manager.isWorkPhase ? "brain.head.profile" : "cup.and.saucer.fill")
                            .font(.largeTitle)
                            .foregroundStyle(manager.isWorkPhase ? .red : .green)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(formatTime(manager.secondsRemaining))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text(manager.taskName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text(manager.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Status", systemImage: "gauge.with.needle")
        }
    }

    // MARK: - Timer Card
    private var timerCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(lineWidth: 12)
                        .opacity(0.2)
                        .foregroundStyle(manager.isWorkPhase ? .red : .green)

                    Circle()
                        .trim(from: 0, to: manager.progress)
                        .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .foregroundStyle(manager.isWorkPhase ? .red : .green)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: manager.progress)

                    VStack {
                        Image(systemName: manager.isWorkPhase ? "flame.fill" : "leaf.fill")
                            .font(.largeTitle)
                            .foregroundStyle(manager.isWorkPhase ? .orange : .green)
                        Text(manager.isWorkPhase ? "FOCUS" : "REST")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
                .frame(width: 140, height: 140)

                // Session indicators
                HStack(spacing: 8) {
                    ForEach(1...manager.totalSessions, id: \.self) { session in
                        Circle()
                            .fill(session < manager.currentSession ? .green :
                                    session == manager.currentSession ? (manager.isWorkPhase ? .red : .green) : .gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } label: {
            Label("Progress", systemImage: "chart.pie")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                TextField("Task Name", text: $taskName)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isActive)

                HStack {
                    Text("Work Duration")
                    Spacer()
                    Picker("Work", selection: $workMinutes) {
                        ForEach([15, 20, 25, 30, 45, 50], id: \.self) { mins in
                            Text("\(mins) min").tag(mins)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(manager.isActive)
                }

                HStack {
                    Text("Break Duration")
                    Spacer()
                    Picker("Break", selection: $breakMinutes) {
                        ForEach([3, 5, 10, 15], id: \.self) { mins in
                            Text("\(mins) min").tag(mins)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(manager.isActive)
                }

                HStack {
                    Text("Total Sessions")
                    Spacer()
                    Stepper("\(totalSessions)", value: $totalSessions, in: 1...8)
                        .disabled(manager.isActive)
                }
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
                            taskName: taskName,
                            workMinutes: workMinutes,
                            breakMinutes: breakMinutes,
                            totalSessions: totalSessions
                        )
                    } label: {
                        Label("Start Focus Session", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red, in: RoundedRectangle(cornerRadius: 12))
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
                            manager.skipPhase()
                        } label: {
                            Label("Skip", systemImage: "forward.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                    }

                    Button {
                        manager.endSession()
                    } label: {
                        Label("End Session", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
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
                PomodoroInfoRow(title: "Technique", value: "Pomodoro Method")
                PomodoroInfoRow(title: "Default Cycle", value: "25 min work / 5 min break")
                PomodoroInfoRow(title: "Goal", value: "4 sessions = 2 hours focused")

                Divider()

                Text("The Pomodoro Technique uses focused work intervals with short breaks to maintain concentration. Live Activity keeps your timer visible without unlocking your phone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("About", systemImage: "info.circle")
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct PomodoroInfoRow: View {
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

// MARK: - Pomodoro Activity Manager

@MainActor
class PomodoroActivityManager: ObservableObject {
    @Published var isActive = false
    @Published var isPaused = false
    @Published var isWorkPhase = true
    @Published var secondsRemaining: Int = 25 * 60
    @Published var totalSeconds: Int = 25 * 60
    @Published var currentSession: Int = 1
    @Published var totalSessions: Int = 4
    @Published var taskName: String = "Deep Work"
    @Published var progress: Double = 1.0
    @Published var statusMessage = "Ready to start focus session"

    private var currentActivity: Activity<PomodoroActivityAttributes>?
    private var timer: Timer?
    private var workSeconds: Int = 25 * 60
    private var breakSeconds: Int = 5 * 60

    init() {
        checkExistingActivities()
    }

    private func checkExistingActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<PomodoroActivityAttributes>.activities {
                currentActivity = activity
                isActive = true
                taskName = activity.attributes.taskName
                updateFromState(activity.content.state)
                statusMessage = "Resumed existing session"
                startTimer()
                break
            }
        }
    }

    private func updateFromState(_ state: PomodoroActivityAttributes.ContentState) {
        isWorkPhase = state.isWorkPhase
        secondsRemaining = state.secondsRemaining
        totalSeconds = state.totalSeconds
        currentSession = state.currentSession
        totalSessions = state.totalSessions
        isPaused = state.isPaused
        progress = Double(secondsRemaining) / Double(totalSeconds)
    }

    func startSession(taskName: String, workMinutes: Int, breakMinutes: Int, totalSessions: Int) {
        guard #available(iOS 16.1, *) else {
            statusMessage = "Requires iOS 16.1+"
            return
        }

        self.taskName = taskName
        self.workSeconds = workMinutes * 60
        self.breakSeconds = breakMinutes * 60
        self.totalSessions = totalSessions
        self.currentSession = 1
        self.isWorkPhase = true
        self.totalSeconds = workSeconds
        self.secondsRemaining = workSeconds
        self.isPaused = false

        let attributes = PomodoroActivityAttributes(taskName: taskName)
        let initialState = PomodoroActivityAttributes.ContentState(
            isWorkPhase: true,
            secondsRemaining: workSeconds,
            totalSeconds: workSeconds,
            currentSession: 1,
            totalSessions: totalSessions,
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
            statusMessage = "Focus session started"
            startTimer()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
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
        progress = Double(secondsRemaining) / Double(totalSeconds)

        if secondsRemaining <= 0 {
            advancePhase()
        }

        updateActivity()
    }

    private func advancePhase() {
        if isWorkPhase {
            // Work phase complete, start break
            isWorkPhase = false
            totalSeconds = breakSeconds
            secondsRemaining = breakSeconds
        } else {
            // Break complete, start next work session
            currentSession += 1
            if currentSession > totalSessions {
                endSession()
                return
            }
            isWorkPhase = true
            totalSeconds = workSeconds
            secondsRemaining = workSeconds
        }
        progress = 1.0
    }

    func skipPhase() {
        advancePhase()
        updateActivity()
    }

    private func updateActivity() {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let updatedState = PomodoroActivityAttributes.ContentState(
            isWorkPhase: isWorkPhase,
            secondsRemaining: secondsRemaining,
            totalSeconds: totalSeconds,
            currentSession: currentSession,
            totalSessions: totalSessions,
            isPaused: isPaused
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
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

        let finalState = PomodoroActivityAttributes.ContentState(
            isWorkPhase: isWorkPhase,
            secondsRemaining: 0,
            totalSeconds: totalSeconds,
            currentSession: currentSession,
            totalSessions: totalSessions,
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
                statusMessage = "Session complete - \(currentSession - 1) sessions finished"
            }
        }
    }
}

#Preview {
    NavigationStack {
        PomodoroView()
    }
}
