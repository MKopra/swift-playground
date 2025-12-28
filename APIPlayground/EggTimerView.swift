import SwiftUI
import ActivityKit

/// Egg Timer - Perfect eggs every time
/// Simple, focused Live Activity for kitchen timing
struct EggTimerView: View {
    @StateObject private var manager = EggTimerActivityManager()
    @State private var selectedStyle: EggStyle = .medium
    @State private var quantity: Int = 2

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusCard
                if manager.isActive {
                    timerCard
                }
                styleSelectionCard
                configurationCard
                controlsCard
                infoCard
            }
            .padding()
        }
        .navigationTitle("Egg Timer")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: manager.isActive ? "oval.fill" : "oval")
                        .foregroundStyle(manager.isActive ? .yellow : .secondary)
                        .font(.title2)
                    Text(manager.isActive ? "Cooking..." : "Ready to Cook")
                        .font(.headline)
                    Spacer()
                    if manager.isActive {
                        Text(manager.isDone ? "DONE!" : timeStatus)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.2), in: Capsule())
                            .foregroundStyle(statusColor)
                    }
                }

                if manager.isActive {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(manager.quantity) × \(manager.eggStyle.rawValue)")
                                .font(.subheadline)
                            Text(manager.eggStyle.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if manager.isDone {
                            Text("DONE!")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.green)
                        } else {
                            Text(formatTime(manager.secondsRemaining))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(statusColor)
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
            Label("Status", systemImage: "frying.pan")
        }
    }

    // MARK: - Timer Card
    private var timerCard: some View {
        GroupBox {
            VStack(spacing: 20) {
                // Egg visualization
                ZStack {
                    // Plate
                    Ellipse()
                        .fill(Color(.systemGray5))
                        .frame(width: 180, height: 100)
                        .offset(y: 40)

                    // Eggs
                    HStack(spacing: -10) {
                        ForEach(0..<min(manager.quantity, 4), id: \.self) { index in
                            EggView(
                                style: manager.eggStyle,
                                progress: manager.progress,
                                isDone: manager.isDone
                            )
                            .rotationEffect(.degrees(Double(index - 1) * 15))
                        }
                    }
                }
                .frame(height: 140)

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange, manager.isDone ? .green : .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * (1 - manager.progress))
                                .animation(.linear(duration: 0.5), value: manager.progress)
                        }
                    }
                    .frame(height: 12)

                    HStack {
                        Text("Raw")
                            .font(.caption2)
                        Spacer()
                        Text("Perfect")
                            .font(.caption2)
                        Spacer()
                        Text("Done")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Cooking Progress", systemImage: "flame")
        }
    }

    // MARK: - Style Selection Card
    private var styleSelectionCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                ForEach(EggStyle.allCases, id: \.self) { style in
                    Button {
                        selectedStyle = style
                    } label: {
                        HStack {
                            Image(systemName: style.icon)
                                .font(.title2)
                                .frame(width: 40)
                                .foregroundStyle(style == selectedStyle ? .white : .yellow)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.rawValue)
                                    .font(.headline)
                                HStack {
                                    Text(style.description)
                                    Text("•")
                                    Text("\(style.cookTime / 60) min")
                                }
                                .font(.caption)
                                .opacity(0.8)
                            }
                            .foregroundStyle(style == selectedStyle ? .white : .primary)

                            Spacer()

                            if style == selectedStyle {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(style == selectedStyle ? Color.orange : Color.secondary.opacity(0.1))
                        )
                    }
                    .disabled(manager.isActive)
                }
            }
        } label: {
            Label("Egg Style", systemImage: "list.bullet")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            HStack {
                Text("Quantity")
                Spacer()
                HStack(spacing: 16) {
                    Button {
                        quantity = max(1, quantity - 1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(manager.isActive || quantity <= 1)

                    Text("\(quantity)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(width: 40)

                    Button {
                        quantity = min(12, quantity + 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(manager.isActive || quantity >= 12)

                    Text("eggs")
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Quantity", systemImage: "number")
        }
    }

    // MARK: - Controls Card
    private var controlsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                if !manager.isActive {
                    Button {
                        manager.startTimer(style: selectedStyle, quantity: quantity)
                    } label: {
                        Label("Start Timer", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    if manager.isDone {
                        Button {
                            manager.endTimer()
                        } label: {
                            Label("Done - Clear Timer", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                    } else {
                        HStack(spacing: 12) {
                            Button {
                                manager.addTime(seconds: 30)
                            } label: {
                                Label("+30s", systemImage: "plus")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                            }

                            Button {
                                manager.endTimer()
                            } label: {
                                Label("Cancel", systemImage: "xmark")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.red, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                            }
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
                EggInfoRow(title: "Soft Boiled", value: "6 min - runny yolk")
                EggInfoRow(title: "Medium", value: "9 min - jammy yolk")
                EggInfoRow(title: "Hard Boiled", value: "12 min - fully set")
                EggInfoRow(title: "Poached", value: "4 min - delicate")

                Divider()

                Text("Perfect eggs require precise timing. Start from boiling water for boiled eggs, or use the poached timer for water at a gentle simmer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("Cooking Guide", systemImage: "book")
        }
    }

    private var statusColor: Color {
        if manager.isDone { return .green }
        let remaining = Double(manager.secondsRemaining) / Double(manager.totalSeconds)
        if remaining > 0.5 { return .yellow }
        if remaining > 0.2 { return .orange }
        return .red
    }

    private var timeStatus: String {
        let remaining = Double(manager.secondsRemaining) / Double(manager.totalSeconds)
        if remaining > 0.5 { return "COOKING" }
        if remaining > 0.2 { return "ALMOST" }
        return "SOON!"
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct EggView: View {
    let style: EggStyle
    let progress: Double
    let isDone: Bool

    var body: some View {
        ZStack {
            // Egg white
            Ellipse()
                .fill(Color.white)
                .frame(width: 50, height: 60)
                .shadow(radius: 2)

            // Yolk
            Circle()
                .fill(yolkColor)
                .frame(width: 24, height: 24)
        }
    }

    private var yolkColor: Color {
        if isDone {
            switch style {
            case .soft: return .orange
            case .medium: return .orange.opacity(0.8)
            case .hard: return .yellow
            case .poached: return .orange
            }
        }
        // Transition from orange to lighter as it cooks
        let cooking = 1 - progress
        return Color(
            red: 1.0,
            green: 0.6 + (0.2 * cooking),
            blue: 0.0 + (0.3 * cooking)
        )
    }
}

struct EggInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

// MARK: - Egg Timer Activity Manager

@MainActor
class EggTimerActivityManager: ObservableObject {
    @Published var isActive = false
    @Published var isDone = false
    @Published var secondsRemaining: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var eggStyle: EggStyle = .medium
    @Published var quantity: Int = 2
    @Published var progress: Double = 1.0
    @Published var statusMessage = "Select egg style and start timer"

    private var currentActivity: Activity<EggTimerActivityAttributes>?
    private var timer: Timer?

    init() {
        checkExistingActivities()
    }

    private func checkExistingActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<EggTimerActivityAttributes>.activities {
                currentActivity = activity
                isActive = true
                eggStyle = activity.attributes.eggStyle
                quantity = activity.attributes.quantity
                updateFromState(activity.content.state)
                if !isDone {
                    statusMessage = "Resumed timer"
                    startTimerLoop()
                }
                break
            }
        }
    }

    private func updateFromState(_ state: EggTimerActivityAttributes.ContentState) {
        secondsRemaining = state.secondsRemaining
        totalSeconds = state.totalSeconds
        isDone = state.isDone
        progress = Double(secondsRemaining) / Double(totalSeconds)
    }

    func startTimer(style: EggStyle, quantity: Int) {
        guard #available(iOS 16.1, *) else {
            statusMessage = "Requires iOS 16.1+"
            return
        }

        self.eggStyle = style
        self.quantity = quantity
        self.totalSeconds = style.cookTime
        self.secondsRemaining = totalSeconds
        self.isDone = false
        self.progress = 1.0

        let attributes = EggTimerActivityAttributes(
            eggStyle: style,
            quantity: quantity
        )

        let initialState = EggTimerActivityAttributes.ContentState(
            secondsRemaining: totalSeconds,
            totalSeconds: totalSeconds,
            isDone: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isActive = true
            statusMessage = "Cooking \(quantity) \(style.rawValue.lowercased()) eggs..."
            startTimerLoop()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    func addTime(seconds: Int) {
        secondsRemaining += seconds
        totalSeconds += seconds
        progress = Double(secondsRemaining) / Double(totalSeconds)
        statusMessage = "Added \(seconds) seconds"
        updateActivity()
    }

    private func startTimerLoop() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard !isDone else { return }

        secondsRemaining -= 1
        progress = Double(secondsRemaining) / Double(totalSeconds)

        if secondsRemaining <= 0 {
            finishCooking()
        }

        updateActivity()
    }

    private func finishCooking() {
        timer?.invalidate()
        isDone = true
        secondsRemaining = 0
        statusMessage = "Eggs are ready! Remove from heat."
        updateActivity()
    }

    private func updateActivity() {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let updatedState = EggTimerActivityAttributes.ContentState(
            secondsRemaining: secondsRemaining,
            totalSeconds: totalSeconds,
            isDone: isDone
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }

    func endTimer() {
        timer?.invalidate()
        timer = nil

        guard #available(iOS 16.1, *),
              let activity = currentActivity else {
            isActive = false
            isDone = false
            return
        }

        let finalState = EggTimerActivityAttributes.ContentState(
            secondsRemaining: 0,
            totalSeconds: totalSeconds,
            isDone: true
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                isActive = false
                isDone = false
                currentActivity = nil
                statusMessage = "Timer cleared"
            }
        }
    }
}

#Preview {
    NavigationStack {
        EggTimerView()
    }
}
