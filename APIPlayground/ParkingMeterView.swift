import SwiftUI
import ActivityKit

/// Parking Meter Timer - Countdown with urgency-based color changes
/// Perfect for Live Activity: time-critical, glanceable, high-anxiety use case
struct ParkingMeterView: View {
    @StateObject private var manager = ParkingActivityManager()
    @State private var selectedMinutes: Int = 60
    @State private var licensePlate: String = "ABC 1234"
    @State private var location: String = "Main St & 5th Ave"
    @State private var spotInfo: String = "Meter #42"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusCard
                if manager.isActive {
                    meterCard
                }
                configurationCard
                controlsCard
                infoCard
            }
            .padding()
        }
        .navigationTitle("Parking Meter")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: manager.isActive ? "car.fill" : "car")
                        .foregroundStyle(urgencyColor)
                        .font(.title2)
                    Text(manager.isActive ? "Meter Running" : "No Active Meter")
                        .font(.headline)
                    Spacer()
                    if manager.isActive {
                        Text(urgencyText)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(urgencyColor.opacity(0.2), in: Capsule())
                            .foregroundStyle(urgencyColor)
                    }
                }

                if manager.isActive {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.location)
                                .font(.subheadline)
                            Text(manager.spotInfo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(formatTime(manager.minutesRemaining))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(urgencyColor)
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
            Label("Status", systemImage: "parkingsign.circle")
        }
    }

    // MARK: - Meter Card
    private var meterCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Visual meter
                ZStack {
                    // Meter background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 120)

                    HStack(spacing: 20) {
                        // Meter icon
                        ZStack {
                            Circle()
                                .fill(urgencyColor.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "parkingsign")
                                .font(.system(size: 36))
                                .foregroundStyle(urgencyColor)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(formatTime(manager.minutesRemaining))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(urgencyColor)

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.3))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(urgencyColor)
                                        .frame(width: geo.size.width * manager.progress)
                                }
                            }
                            .frame(height: 8)

                            Text("\(manager.licensePlate) • \(manager.spotInfo)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }

                // Time remaining breakdown
                if manager.minutesRemaining > 0 {
                    HStack {
                        Image(systemName: "clock")
                        Text("Expires at \(expirationTime)")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        } label: {
            Label("Meter Status", systemImage: "gauge.with.needle")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                TextField("License Plate", text: $licensePlate)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isActive)

                TextField("Location", text: $location)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isActive)

                TextField("Spot Info", text: $spotInfo)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isActive)

                HStack {
                    Text("Duration")
                    Spacer()
                    Picker("Minutes", selection: $selectedMinutes) {
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                        Text("4 hours").tag(240)
                    }
                    .pickerStyle(.menu)
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
                        manager.startMeter(
                            minutes: selectedMinutes,
                            licensePlate: licensePlate,
                            location: location,
                            spotInfo: spotInfo
                        )
                    } label: {
                        Label("Start Meter", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button {
                            manager.addTime(minutes: 15)
                        } label: {
                            Label("+15 min", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }

                        Button {
                            manager.addTime(minutes: 30)
                        } label: {
                            Label("+30 min", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                    }

                    Button {
                        manager.endMeter()
                    } label: {
                        Label("End Parking", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red, in: RoundedRectangle(cornerRadius: 12))
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
                ParkingInfoRow(title: "Alert Timing", value: "Warning at 30%, Critical at 10%")
                ParkingInfoRow(title: "Color Coding", value: "Green → Yellow → Red")

                Divider()

                Text("Never get a parking ticket again. The Live Activity changes color as your meter expires, giving you urgent visual feedback right from your Lock Screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("About", systemImage: "info.circle")
        }
    }

    private var urgency: ParkingUrgency {
        ParkingUrgency.from(minutes: manager.minutesRemaining, total: manager.totalMinutes)
    }

    private var urgencyColor: Color {
        switch urgency {
        case .safe: return .green
        case .warning: return .yellow
        case .critical: return .red
        case .expired: return .red
        }
    }

    private var urgencyText: String {
        switch urgency {
        case .safe: return "PLENTY OF TIME"
        case .warning: return "RUNNING LOW"
        case .critical: return "HURRY!"
        case .expired: return "EXPIRED"
        }
    }

    private var expirationTime: String {
        let expiration = Date().addingTimeInterval(TimeInterval(manager.minutesRemaining * 60))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: expiration)
    }

    private func formatTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

struct ParkingInfoRow: View {
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

// MARK: - Parking Activity Manager

@MainActor
class ParkingActivityManager: ObservableObject {
    @Published var isActive = false
    @Published var minutesRemaining: Int = 60
    @Published var totalMinutes: Int = 60
    @Published var licensePlate: String = ""
    @Published var location: String = ""
    @Published var spotInfo: String = ""
    @Published var progress: Double = 1.0
    @Published var statusMessage = "Ready to track parking"

    private var currentActivity: Activity<ParkingActivityAttributes>?
    private var timer: Timer?
    private var secondsCounter: Int = 0

    init() {
        checkExistingActivities()
    }

    private func checkExistingActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<ParkingActivityAttributes>.activities {
                currentActivity = activity
                isActive = true
                licensePlate = activity.attributes.licensePlate
                location = activity.attributes.location
                updateFromState(activity.content.state)
                statusMessage = "Resumed parking session"
                startTimer()
                break
            }
        }
    }

    private func updateFromState(_ state: ParkingActivityAttributes.ContentState) {
        minutesRemaining = state.minutesRemaining
        totalMinutes = state.totalMinutes
        spotInfo = state.spotInfo
        progress = Double(minutesRemaining) / Double(totalMinutes)
    }

    func startMeter(minutes: Int, licensePlate: String, location: String, spotInfo: String) {
        guard #available(iOS 16.1, *) else {
            statusMessage = "Requires iOS 16.1+"
            return
        }

        self.minutesRemaining = minutes
        self.totalMinutes = minutes
        self.licensePlate = licensePlate
        self.location = location
        self.spotInfo = spotInfo
        self.secondsCounter = 0

        let attributes = ParkingActivityAttributes(
            licensePlate: licensePlate,
            location: location
        )

        let initialState = ParkingActivityAttributes.ContentState(
            minutesRemaining: minutes,
            totalMinutes: minutes,
            isExpired: false,
            spotInfo: spotInfo
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isActive = true
            statusMessage = "Meter started - \(minutes) minutes"
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
        secondsCounter += 1

        // Update minutes every 60 seconds
        if secondsCounter >= 60 {
            secondsCounter = 0
            minutesRemaining -= 1
            progress = Double(minutesRemaining) / Double(totalMinutes)
            updateActivity()

            if minutesRemaining <= 0 {
                statusMessage = "METER EXPIRED!"
            }
        }
    }

    func addTime(minutes: Int) {
        minutesRemaining += minutes
        totalMinutes += minutes
        progress = Double(minutesRemaining) / Double(totalMinutes)
        statusMessage = "Added \(minutes) minutes"
        updateActivity()
    }

    private func updateActivity() {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let updatedState = ParkingActivityAttributes.ContentState(
            minutesRemaining: minutesRemaining,
            totalMinutes: totalMinutes,
            isExpired: minutesRemaining <= 0,
            spotInfo: spotInfo
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }

    func endMeter() {
        timer?.invalidate()
        timer = nil

        guard #available(iOS 16.1, *),
              let activity = currentActivity else {
            isActive = false
            return
        }

        let finalState = ParkingActivityAttributes.ContentState(
            minutesRemaining: 0,
            totalMinutes: totalMinutes,
            isExpired: true,
            spotInfo: spotInfo
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                isActive = false
                currentActivity = nil
                statusMessage = "Parking session ended"
            }
        }
    }
}

#Preview {
    NavigationStack {
        ParkingMeterView()
    }
}
