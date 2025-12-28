import SwiftUI
import ActivityKit

/// Rocket Launch Countdown - T-minus to liftoff
/// Perfect Live Activity: high anticipation, real-time phase updates
struct RocketLaunchView: View {
    @StateObject private var manager = RocketActivityManager()
    @State private var missionName: String = "Artemis III"
    @State private var rocketName: String = "SLS"
    @State private var countdownMinutes: Int = 2

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusCard
                if manager.isActive {
                    launchCard
                    telemetryCard
                }
                configurationCard
                controlsCard
                infoCard
            }
            .padding()
        }
        .navigationTitle("Rocket Launch")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: manager.isActive ? "airplane.departure" : "airplane")
                        .foregroundStyle(phaseColor)
                        .font(.title2)
                    Text(manager.isActive ? manager.missionName : "No Active Launch")
                        .font(.headline)
                    Spacer()
                    if manager.isActive {
                        Text(manager.phase.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(phaseColor.opacity(0.2), in: Capsule())
                            .foregroundStyle(phaseColor)
                    }
                }

                if manager.isActive {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.rocketName)
                                .font(.subheadline)
                            Text(manager.missionStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            if manager.phase == .countdown {
                                Text("T-\(manager.secondsToLaunch)")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(phaseColor)
                            } else {
                                Text(manager.phase == .holding ? "HOLD" : "+\(abs(manager.secondsToLaunch))")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(phaseColor)
                            }
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
            Label("Mission Status", systemImage: "scope")
        }
    }

    // MARK: - Launch Card
    private var launchCard: some View {
        GroupBox {
            VStack(spacing: 20) {
                // Rocket visualization
                ZStack {
                    // Sky gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: rocketGradient,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 200)

                    // Rocket
                    VStack(spacing: 0) {
                        Image(systemName: "airplane")
                            .font(.system(size: 60))
                            .rotationEffect(.degrees(-45))
                            .foregroundStyle(.white)
                            .offset(y: rocketOffset)
                            .animation(.easeOut(duration: 0.3), value: manager.phase)

                        // Flame effect for liftoff
                        if manager.phase == .liftoff || manager.phase == .maxQ {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.orange)
                                .offset(y: rocketOffset + 20)
                        }
                    }

                    // Phase overlay
                    VStack {
                        Spacer()
                        HStack {
                            Text(manager.phase.rawValue)
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }

                // Phase timeline
                HStack(spacing: 4) {
                    ForEach(LaunchPhase.allCases, id: \.self) { phase in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(phase == manager.phase ? phaseColorFor(phase) :
                                        (phaseOrder(phase) < phaseOrder(manager.phase) ? .green : .gray.opacity(0.3)))
                                .frame(width: 12, height: 12)

                            Text(phase.shortName)
                                .font(.system(size: 8))
                                .foregroundStyle(phase == manager.phase ? phaseColorFor(phase) : .secondary)
                        }
                        .frame(maxWidth: .infinity)

                        if phase != .success {
                            Rectangle()
                                .fill(phaseOrder(phase) < phaseOrder(manager.phase) ? .green : .gray.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
            }
        } label: {
            Label("Launch Visualization", systemImage: "sparkles")
        }
    }

    // MARK: - Telemetry Card
    private var telemetryCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                TelemetryRow(label: "Mission", value: manager.missionName, icon: "flag.fill")
                TelemetryRow(label: "Vehicle", value: manager.rocketName, icon: "airplane.departure")
                TelemetryRow(label: "Phase", value: manager.phase.rawValue, icon: "gauge.with.needle.fill")
                TelemetryRow(label: "Status", value: manager.missionStatus, icon: "waveform.path.ecg")

                if manager.phase != .holding && manager.phase != .countdown {
                    Divider()
                    Text("All systems nominal")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                }
            }
        } label: {
            Label("Telemetry", systemImage: "chart.bar.xaxis")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                TextField("Mission Name", text: $missionName)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isActive)

                TextField("Rocket Name", text: $rocketName)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isActive)

                HStack {
                    Text("Countdown")
                    Spacer()
                    Picker("Countdown", selection: $countdownMinutes) {
                        Text("30 sec").tag(0)
                        Text("1 min").tag(1)
                        Text("2 min").tag(2)
                        Text("5 min").tag(5)
                    }
                    .pickerStyle(.menu)
                    .disabled(manager.isActive)
                }
            }
        } label: {
            Label("Mission Configuration", systemImage: "gearshape")
        }
    }

    // MARK: - Controls Card
    private var controlsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                if !manager.isActive {
                    Button {
                        manager.startCountdown(
                            missionName: missionName,
                            rocketName: rocketName,
                            countdownSeconds: countdownMinutes == 0 ? 30 : countdownMinutes * 60
                        )
                    } label: {
                        Label("Start Countdown", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.indigo, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    if manager.phase == .holding {
                        Button {
                            manager.resumeCountdown()
                        } label: {
                            Label("Resume Countdown", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                    } else if manager.phase == .countdown {
                        Button {
                            manager.holdCountdown()
                        } label: {
                            Label("HOLD", systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.yellow, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.black)
                        }
                    }

                    Button {
                        manager.endMission()
                    } label: {
                        Label("Abort Mission", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
            }
        } label: {
            Label("Mission Control", systemImage: "play.rectangle")
        }
    }

    // MARK: - Info Card
    private var infoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                LaunchInfoRow(title: "Max-Q", value: "Maximum dynamic pressure")
                LaunchInfoRow(title: "MECO", value: "Main Engine Cutoff")

                Divider()

                Text("Experience the excitement of a rocket launch countdown. Watch the phases progress from T-minus through liftoff, Max-Q, MECO, and mission success - all tracked live on your Dynamic Island.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("About", systemImage: "info.circle")
        }
    }

    private var phaseColor: Color {
        phaseColorFor(manager.phase)
    }

    private func phaseColorFor(_ phase: LaunchPhase) -> Color {
        switch phase {
        case .holding: return .yellow
        case .countdown: return .blue
        case .liftoff: return .orange
        case .maxQ: return .red
        case .meco: return .purple
        case .success: return .green
        }
    }

    private func phaseOrder(_ phase: LaunchPhase) -> Int {
        switch phase {
        case .holding: return 0
        case .countdown: return 1
        case .liftoff: return 2
        case .maxQ: return 3
        case .meco: return 4
        case .success: return 5
        }
    }

    private var rocketGradient: [Color] {
        switch manager.phase {
        case .holding, .countdown:
            return [.blue.opacity(0.8), .cyan.opacity(0.6), .blue.opacity(0.4)]
        case .liftoff:
            return [.orange.opacity(0.8), .red.opacity(0.6), .gray.opacity(0.8)]
        case .maxQ:
            return [.red.opacity(0.8), .orange.opacity(0.6), .black]
        case .meco:
            return [.purple.opacity(0.8), .indigo.opacity(0.6), .black]
        case .success:
            return [.black, .indigo.opacity(0.4), .purple.opacity(0.2)]
        }
    }

    private var rocketOffset: CGFloat {
        switch manager.phase {
        case .holding, .countdown: return 0
        case .liftoff: return -30
        case .maxQ: return -60
        case .meco: return -90
        case .success: return -120
        }
    }
}

extension LaunchPhase: CaseIterable {
    static var allCases: [LaunchPhase] {
        [.holding, .countdown, .liftoff, .maxQ, .meco, .success]
    }

    var shortName: String {
        switch self {
        case .holding: return "HOLD"
        case .countdown: return "T-"
        case .liftoff: return "GO"
        case .maxQ: return "Q"
        case .meco: return "MECO"
        case .success: return "OK"
        }
    }
}

struct TelemetryRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct LaunchInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.bold)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

// MARK: - Rocket Activity Manager

@MainActor
class RocketActivityManager: ObservableObject {
    @Published var isActive = false
    @Published var secondsToLaunch: Int = 120
    @Published var phase: LaunchPhase = .countdown
    @Published var missionName: String = ""
    @Published var rocketName: String = ""
    @Published var missionStatus: String = "Standing by"
    @Published var statusMessage = "Ready for launch"

    private var currentActivity: Activity<RocketActivityAttributes>?
    private var timer: Timer?
    private var missionElapsed: Int = 0

    init() {
        checkExistingActivities()
    }

    private func checkExistingActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<RocketActivityAttributes>.activities {
                currentActivity = activity
                isActive = true
                missionName = activity.attributes.missionName
                rocketName = activity.attributes.rocketName
                updateFromState(activity.content.state)
                if phase == .countdown {
                    statusMessage = "Resumed countdown"
                    startTimer()
                }
                break
            }
        }
    }

    private func updateFromState(_ state: RocketActivityAttributes.ContentState) {
        secondsToLaunch = state.secondsToLaunch
        phase = state.phase
        missionStatus = state.missionStatus
    }

    func startCountdown(missionName: String, rocketName: String, countdownSeconds: Int) {
        guard #available(iOS 16.1, *) else {
            statusMessage = "Requires iOS 16.1+"
            return
        }

        self.missionName = missionName
        self.rocketName = rocketName
        self.secondsToLaunch = countdownSeconds
        self.phase = .countdown
        self.missionStatus = "All systems go"
        self.missionElapsed = 0

        let attributes = RocketActivityAttributes(
            missionName: missionName,
            rocketName: rocketName
        )

        let initialState = RocketActivityAttributes.ContentState(
            secondsToLaunch: countdownSeconds,
            phase: .countdown,
            missionStatus: "All systems go"
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isActive = true
            statusMessage = "T-\(countdownSeconds) and counting"
            startTimer()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    func holdCountdown() {
        phase = .holding
        missionStatus = "Hold for weather"
        statusMessage = "Countdown holding"
        updateActivity()
    }

    func resumeCountdown() {
        phase = .countdown
        missionStatus = "All systems go"
        statusMessage = "Countdown resumed"
        updateActivity()
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
        guard phase != .holding else { return }

        if phase == .countdown {
            secondsToLaunch -= 1

            if secondsToLaunch <= 0 {
                liftoff()
            }
        } else {
            // Post-launch phases
            missionElapsed += 1
            secondsToLaunch = -missionElapsed

            // Progress through phases
            switch missionElapsed {
            case 5:
                phase = .maxQ
                missionStatus = "Maximum dynamic pressure"
                statusMessage = "Max-Q!"
            case 15:
                phase = .meco
                missionStatus = "Main engine cutoff"
                statusMessage = "MECO confirmed"
            case 25:
                phase = .success
                missionStatus = "Mission success!"
                statusMessage = "Mission accomplished!"
                timer?.invalidate()
            default:
                break
            }
        }

        updateActivity()
    }

    private func liftoff() {
        phase = .liftoff
        missionStatus = "We have liftoff!"
        statusMessage = "LIFTOFF!"
    }

    private func updateActivity() {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let updatedState = RocketActivityAttributes.ContentState(
            secondsToLaunch: secondsToLaunch,
            phase: phase,
            missionStatus: missionStatus
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }

    func endMission() {
        timer?.invalidate()
        timer = nil

        guard #available(iOS 16.1, *),
              let activity = currentActivity else {
            isActive = false
            return
        }

        let finalState = RocketActivityAttributes.ContentState(
            secondsToLaunch: 0,
            phase: phase,
            missionStatus: "Mission ended"
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                isActive = false
                currentActivity = nil
                statusMessage = "Mission ended"
            }
        }
    }
}

#Preview {
    NavigationStack {
        RocketLaunchView()
    }
}
