import SwiftUI
import ActivityKit

/// Caffeine Tracker - Watch caffeine metabolize in real-time
/// Uses exponential decay (half-life ~5 hours) to show caffeine levels
struct CaffeineTrackerView: View {
    @StateObject private var manager = CaffeineActivityManager()
    @State private var selectedDrink: CaffeineDrink = .coffee
    @State private var customMg: Double = 100

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusCard
                if manager.isActive {
                    metabolismCard
                }
                drinkSelectionCard
                controlsCard
                infoCard
            }
            .padding()
        }
        .navigationTitle("Caffeine Tracker")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .foregroundStyle(manager.isActive ? .brown : .secondary)
                        .font(.title2)
                    Text(manager.isActive ? "Tracking Caffeine" : "No Active Tracking")
                        .font(.headline)
                    Spacer()
                    if manager.isActive {
                        Text("\(Int(manager.currentMg)) mg")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(caffeineColor.opacity(0.2), in: Capsule())
                            .foregroundStyle(caffeineColor)
                    }
                }

                if manager.isActive {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.drinkName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Started \(formatTime(manager.hoursElapsed)) ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("\(Int(manager.currentMg))")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(caffeineColor)
                            Text("mg remaining")
                                .font(.caption)
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
            Label("Status", systemImage: "waveform.path.ecg")
        }
    }

    // MARK: - Metabolism Card
    private var metabolismCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Decay visualization
                ZStack {
                    // Background cup
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 140)

                    HStack(spacing: 20) {
                        // Cup visualization
                        ZStack(alignment: .bottom) {
                            // Cup outline
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.brown, lineWidth: 3)
                                .frame(width: 60, height: 80)

                            // Liquid fill
                            RoundedRectangle(cornerRadius: 6)
                                .fill(caffeineColor.opacity(0.7))
                                .frame(width: 54, height: 74 * (manager.currentMg / manager.startMg))
                                .animation(.easeInOut(duration: 0.5), value: manager.currentMg)
                        }
                        .padding(.leading)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Started:")
                                Spacer()
                                Text("\(Int(manager.startMg)) mg")
                                    .fontWeight(.bold)
                            }
                            HStack {
                                Text("Current:")
                                Spacer()
                                Text("\(Int(manager.currentMg)) mg")
                                    .fontWeight(.bold)
                                    .foregroundStyle(caffeineColor)
                            }
                            HStack {
                                Text("Metabolized:")
                                Spacer()
                                Text("\(Int(manager.startMg - manager.currentMg)) mg")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                            }

                            Divider()

                            HStack {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundStyle(.indigo)
                                Text("Clear by: \(formatClearTime)")
                                    .font(.subheadline)
                            }
                        }
                        .font(.subheadline)
                        .padding(.trailing)
                    }
                }

                // Decay curve preview
                HStack(spacing: 4) {
                    ForEach(0..<12) { hour in
                        let level = calculateLevel(at: Double(hour))
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 2)
                                .fill(hour <= Int(manager.hoursElapsed) ? caffeineColor : caffeineColor.opacity(0.3))
                                .frame(width: 20, height: max(4, 40 * level / manager.startMg))
                        }
                        .frame(height: 50)
                    }
                }

                HStack {
                    Text("0h")
                    Spacer()
                    Text("6h")
                    Spacer()
                    Text("12h")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        } label: {
            Label("Metabolism", systemImage: "chart.line.downtrend.xyaxis")
        }
    }

    // MARK: - Drink Selection Card
    private var drinkSelectionCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                ForEach(CaffeineDrink.allCases, id: \.self) { drink in
                    Button {
                        selectedDrink = drink
                    } label: {
                        HStack {
                            Image(systemName: drink.icon)
                                .font(.title2)
                                .frame(width: 40)
                                .foregroundStyle(drink == selectedDrink ? .white : .brown)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(drink.name)
                                    .font(.headline)
                                Text("\(drink.caffeineMg) mg caffeine")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            .foregroundStyle(drink == selectedDrink ? .white : .primary)

                            Spacer()

                            if drink == selectedDrink {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(drink == selectedDrink ? Color.brown : Color.secondary.opacity(0.1))
                        )
                    }
                    .disabled(manager.isActive)
                }
            }
        } label: {
            Label("Select Drink", systemImage: "list.bullet")
        }
    }

    // MARK: - Controls Card
    private var controlsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                if !manager.isActive {
                    Button {
                        manager.startTracking(drink: selectedDrink)
                    } label: {
                        Label("Start Tracking \(selectedDrink.name)", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.brown, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button {
                            manager.addDrink(drink: selectedDrink)
                        } label: {
                            Label("Add Another", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }

                        Button {
                            manager.endTracking()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
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
                CaffeineInfoRow(title: "Half-life", value: "~5 hours")
                CaffeineInfoRow(title: "Safe daily limit", value: "400 mg")
                CaffeineInfoRow(title: "Sleep cutoff", value: "< 50 mg")

                Divider()

                Text("Caffeine has a half-life of about 5 hours. This tracker uses exponential decay to estimate how much caffeine remains in your system, helping you know when it's safe to sleep.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("About", systemImage: "info.circle")
        }
    }

    private var caffeineColor: Color {
        let level = manager.currentMg
        if level > 300 { return .red }
        if level > 150 { return .orange }
        if level > 50 { return .brown }
        return .green
    }

    private var formatClearTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: manager.estimatedClearTime)
    }

    private func formatTime(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(m)m"
    }

    private func calculateLevel(at hours: Double) -> Double {
        // Exponential decay with 5-hour half-life
        return manager.startMg * pow(0.5, hours / 5.0)
    }
}

enum CaffeineDrink: CaseIterable {
    case espresso, coffee, latte, tea, energyDrink, soda

    var name: String {
        switch self {
        case .espresso: return "Espresso"
        case .coffee: return "Coffee"
        case .latte: return "Latte"
        case .tea: return "Green Tea"
        case .energyDrink: return "Energy Drink"
        case .soda: return "Cola"
        }
    }

    var caffeineMg: Int {
        switch self {
        case .espresso: return 63
        case .coffee: return 95
        case .latte: return 75
        case .tea: return 28
        case .energyDrink: return 80
        case .soda: return 34
        }
    }

    var icon: String {
        switch self {
        case .espresso: return "cup.and.saucer.fill"
        case .coffee: return "mug.fill"
        case .latte: return "cup.and.saucer"
        case .tea: return "leaf.fill"
        case .energyDrink: return "bolt.fill"
        case .soda: return "drop.fill"
        }
    }
}

struct CaffeineInfoRow: View {
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

// MARK: - Caffeine Activity Manager

@MainActor
class CaffeineActivityManager: ObservableObject {
    @Published var isActive = false
    @Published var currentMg: Double = 0
    @Published var startMg: Double = 0
    @Published var hoursElapsed: Double = 0
    @Published var drinkName: String = ""
    @Published var estimatedClearTime: Date = Date()
    @Published var statusMessage = "Ready to track caffeine"

    private var currentActivity: Activity<CaffeineActivityAttributes>?
    private var timer: Timer?
    private var startTime: Date = Date()

    // Caffeine half-life in hours
    private let halfLife: Double = 5.0

    init() {
        checkExistingActivities()
    }

    private func checkExistingActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<CaffeineActivityAttributes>.activities {
                currentActivity = activity
                isActive = true
                drinkName = activity.attributes.drinkName
                startTime = activity.attributes.startTime
                updateFromState(activity.content.state)
                statusMessage = "Resumed caffeine tracking"
                startTimer()
                break
            }
        }
    }

    private func updateFromState(_ state: CaffeineActivityAttributes.ContentState) {
        currentMg = state.currentMg
        startMg = state.startMg
        hoursElapsed = state.hoursElapsed
        estimatedClearTime = state.estimatedClearTime
    }

    func startTracking(drink: CaffeineDrink) {
        guard #available(iOS 16.1, *) else {
            statusMessage = "Requires iOS 16.1+"
            return
        }

        self.drinkName = drink.name
        self.startMg = Double(drink.caffeineMg)
        self.currentMg = startMg
        self.hoursElapsed = 0
        self.startTime = Date()
        calculateClearTime()

        let attributes = CaffeineActivityAttributes(
            drinkName: drink.name,
            startTime: startTime
        )

        let initialState = CaffeineActivityAttributes.ContentState(
            currentMg: currentMg,
            startMg: startMg,
            hoursElapsed: 0,
            estimatedClearTime: estimatedClearTime
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isActive = true
            statusMessage = "Tracking \(Int(startMg)) mg caffeine"
            startTimer()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    func addDrink(drink: CaffeineDrink) {
        let addedMg = Double(drink.caffeineMg)
        startMg += addedMg
        currentMg += addedMg
        drinkName = "\(drinkName) + \(drink.name)"
        calculateClearTime()
        statusMessage = "Added \(Int(addedMg)) mg from \(drink.name)"
        updateActivity()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        hoursElapsed = Date().timeIntervalSince(startTime) / 3600.0

        // Exponential decay: C(t) = C0 * (0.5)^(t/halfLife)
        currentMg = startMg * pow(0.5, hoursElapsed / halfLife)

        calculateClearTime()

        if currentMg < 10 {
            statusMessage = "Caffeine almost cleared!"
        }

        updateActivity()
    }

    private func calculateClearTime() {
        // Time to reach 10mg (essentially cleared)
        // 10 = startMg * 0.5^(t/5)
        // t = 5 * log2(startMg / 10)
        let hoursToClearing = halfLife * log2(max(currentMg, 1) / 10.0)
        estimatedClearTime = Date().addingTimeInterval(max(0, hoursToClearing * 3600))
    }

    private func updateActivity() {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let updatedState = CaffeineActivityAttributes.ContentState(
            currentMg: currentMg,
            startMg: startMg,
            hoursElapsed: hoursElapsed,
            estimatedClearTime: estimatedClearTime
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }

    func endTracking() {
        timer?.invalidate()
        timer = nil

        guard #available(iOS 16.1, *),
              let activity = currentActivity else {
            isActive = false
            return
        }

        let finalState = CaffeineActivityAttributes.ContentState(
            currentMg: 0,
            startMg: startMg,
            hoursElapsed: hoursElapsed,
            estimatedClearTime: Date()
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                isActive = false
                currentActivity = nil
                statusMessage = "Caffeine tracking stopped"
            }
        }
    }
}

#Preview {
    NavigationStack {
        CaffeineTrackerView()
    }
}
