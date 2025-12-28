import SwiftUI
import UIKit

// MARK: - BatteryView
/// A comprehensive battery monitoring interface with usage statistics and history.
///
/// Features:
/// - Real-time battery level and state monitoring
/// - Battery level history graph
/// - Charging time estimation
/// - Usage time estimates by activity type
/// - Thermal state monitoring
/// - Low Power Mode detection
/// - Drain rate calculation
/// - Session statistics
///
/// APIs Demonstrated:
/// - UIDevice battery monitoring
/// - ProcessInfo for thermal state and low power mode
/// - NotificationCenter for battery events
/// - UserDefaults for history persistence
struct BatteryView: View {
    @StateObject private var battery = BatteryMonitor()
    @State private var chargingBoltOffset: CGFloat = 0
    @State private var glowPulse: CGFloat = 1.0
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background gradient based on battery level
            LinearGradient(
                colors: backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Charging particles
            if battery.isCharging {
                ChargingParticles()
            }

            VStack(spacing: 16) {
                // Large battery visualization
                ZStack {
                    // Glow effect
                    RoundedRectangle(cornerRadius: 24)
                        .fill(batteryColor.opacity(0.3))
                        .frame(width: 140, height: 220)
                        .blur(radius: 25)
                        .scaleEffect(glowPulse)

                    // Battery body
                    BatteryShape()
                        .fill(Color(white: 0.15))
                        .frame(width: 120, height: 200)
                        .overlay(
                            BatteryShape()
                                .stroke(Color(white: 0.3), lineWidth: 2)
                        )

                    // Battery level fill
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [batteryColor.opacity(0.8), batteryColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: 100,
                                height: max(0, 160 * battery.level)
                            )
                            .animation(.easeInOut(duration: 0.5), value: battery.level)
                    }
                    .frame(width: 120, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Percentage text
                    VStack(spacing: 2) {
                        Text("\(Int(battery.level * 100))")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("%")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .shadow(color: .black.opacity(0.3), radius: 5)

                    // Charging indicator
                    if battery.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.yellow)
                            .offset(y: chargingBoltOffset)
                            .opacity(0.8)
                            .shadow(color: .yellow, radius: 10)
                    }
                }

                // Status text
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: battery.isCharging ? "bolt.fill" : "battery.100")
                            .foregroundStyle(battery.isCharging ? .yellow : batteryColor)
                        Text(battery.stateDescription)
                            .fontWeight(.medium)
                    }
                    .font(.title3)
                    .foregroundStyle(.white)

                    if battery.isCharging, let timeToFull = battery.estimatedTimeToFull {
                        Text("Full in \(timeToFull)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else if !battery.isCharging, let remaining = battery.estimatedTimeRemaining {
                        Text("\(remaining) remaining")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }

                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("History").tag(1)
                    Text("Usage").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab content
                TabView(selection: $selectedTab) {
                    OverviewTab(battery: battery)
                        .tag(0)

                    HistoryTab(battery: battery)
                        .tag(1)

                    UsageTab(battery: battery)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.top)
        }
        .navigationTitle("Battery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            startAnimations()
        }
    }

    private var batteryColor: Color {
        if battery.level > 0.5 { return .green }
        if battery.level > 0.2 { return .yellow }
        return .red
    }

    private var backgroundColors: [Color] {
        if battery.isCharging {
            return [Color(red: 0.2, green: 0.15, blue: 0), Color(red: 0.1, green: 0.08, blue: 0)]
        }
        if battery.level > 0.5 {
            return [Color(red: 0, green: 0.15, blue: 0.05), Color(red: 0, green: 0.08, blue: 0.02)]
        }
        if battery.level > 0.2 {
            return [Color(red: 0.15, green: 0.12, blue: 0), Color(red: 0.08, green: 0.06, blue: 0)]
        }
        return [Color(red: 0.2, green: 0.05, blue: 0.05), Color(red: 0.1, green: 0.02, blue: 0.02)]
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = 1.1
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            chargingBoltOffset = -10
        }
    }
}

// MARK: - OverviewTab
/// Displays battery overview with stats and indicators.
struct OverviewTab: View {
    @ObservedObject var battery: BatteryMonitor

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    BatteryStatCard(
                        icon: "bolt.circle.fill",
                        title: "State",
                        value: battery.stateDescription,
                        color: battery.isCharging ? .yellow : .gray
                    )

                    BatteryStatCard(
                        icon: "heart.fill",
                        title: "Health",
                        value: battery.healthStatus,
                        color: battery.healthColor
                    )

                    BatteryStatCard(
                        icon: "thermometer.medium",
                        title: "Thermal",
                        value: battery.thermalState,
                        color: battery.thermalColor
                    )

                    BatteryStatCard(
                        icon: "arrow.down.circle.fill",
                        title: "Drain Rate",
                        value: battery.drainRateDisplay,
                        color: .cyan
                    )
                }
                .padding(.horizontal)

                // Low Power Mode indicator
                if ProcessInfo.processInfo.isLowPowerModeEnabled {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(.yellow)
                        Text("Low Power Mode Enabled")
                            .font(.subheadline)
                            .foregroundStyle(.yellow)

                        Spacer()

                        Text("Extends battery life")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Session info
                VStack(alignment: .leading, spacing: 12) {
                    Text("This Session")
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: 20) {
                        SessionStat(
                            icon: "clock.fill",
                            label: "Duration",
                            value: battery.sessionDuration
                        )

                        SessionStat(
                            icon: "arrow.down.right",
                            label: "Used",
                            value: battery.sessionDrainDisplay
                        )

                        SessionStat(
                            icon: "bolt.horizontal.fill",
                            label: "Charged",
                            value: battery.sessionChargeDisplay
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Spacer(minLength: 32)
            }
            .padding(.top)
        }
    }
}

// MARK: - HistoryTab
/// Displays battery level history graph.
struct HistoryTab: View {
    @ObservedObject var battery: BatteryMonitor

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // History graph
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Battery History")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Spacer()

                        Text("Last \(battery.history.count) readings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if battery.history.count > 1 {
                        BatteryHistoryGraph(history: battery.history)
                            .frame(height: 200)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Collecting data...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    }

                    // Legend
                    HStack(spacing: 20) {
                        LegendItem(color: .green, label: "> 50%")
                        LegendItem(color: .yellow, label: "20-50%")
                        LegendItem(color: .red, label: "< 20%")
                    }
                    .font(.caption2)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Event log
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Events")
                        .font(.headline)
                        .foregroundStyle(.white)

                    if battery.events.isEmpty {
                        Text("No events recorded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(battery.events.prefix(10)) { event in
                            HStack {
                                Image(systemName: event.icon)
                                    .foregroundStyle(event.color)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(.subheadline)

                                    Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(event.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Spacer(minLength: 32)
            }
            .padding(.top)
        }
    }
}

// MARK: - UsageTab
/// Displays estimated usage times by activity.
struct UsageTab: View {
    @ObservedObject var battery: BatteryMonitor

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Usage estimates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Estimated Usage Time")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Based on current battery level")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        UsageRow(
                            icon: "video.fill",
                            label: "Video Playback",
                            time: battery.videoTime,
                            progress: battery.level,
                            color: .red
                        )

                        UsageRow(
                            icon: "music.note",
                            label: "Audio Playback",
                            time: battery.audioTime,
                            progress: battery.level,
                            color: .pink
                        )

                        UsageRow(
                            icon: "safari.fill",
                            label: "Web Browsing",
                            time: battery.browseTime,
                            progress: battery.level,
                            color: .blue
                        )

                        UsageRow(
                            icon: "gamecontroller.fill",
                            label: "Gaming",
                            time: battery.gamingTime,
                            progress: battery.level,
                            color: .purple
                        )

                        UsageRow(
                            icon: "phone.fill",
                            label: "Talk Time",
                            time: battery.talkTime,
                            progress: battery.level,
                            color: .green
                        )

                        UsageRow(
                            icon: "moon.zzz.fill",
                            label: "Standby",
                            time: battery.standbyTime,
                            progress: battery.level,
                            color: .indigo
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Power tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Battery Tips")
                        .font(.headline)
                        .foregroundStyle(.white)

                    BatteryTip(
                        icon: "sun.max.fill",
                        title: "Reduce Brightness",
                        description: "Lower screen brightness to extend battery life"
                    )

                    BatteryTip(
                        icon: "wifi.slash",
                        title: "Disable Unused Radios",
                        description: "Turn off WiFi, Bluetooth, or Cellular when not needed"
                    )

                    BatteryTip(
                        icon: "location.slash.fill",
                        title: "Limit Location Services",
                        description: "Use location only when necessary"
                    )

                    BatteryTip(
                        icon: "arrow.clockwise",
                        title: "Close Background Apps",
                        description: "Force quit apps you're not using"
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Spacer(minLength: 32)
            }
            .padding(.top)
        }
    }
}

// MARK: - Supporting Views

struct BatteryShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Main body
        let bodyRect = CGRect(x: 0, y: 16, width: rect.width, height: rect.height - 16)
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: 18, height: 18))

        // Top terminal
        let terminalWidth: CGFloat = rect.width * 0.4
        let terminalRect = CGRect(
            x: (rect.width - terminalWidth) / 2,
            y: 0,
            width: terminalWidth,
            height: 20
        )
        path.addRoundedRect(in: terminalRect, cornerSize: CGSize(width: 6, height: 6))

        return path
    }
}

struct ChargingParticles: View {
    @State private var particles: [(id: UUID, x: CGFloat)] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    ChargingParticle()
                        .offset(x: particle.x + geo.size.width / 2)
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let newParticle = (id: UUID(), x: CGFloat.random(in: -80...80))
            particles.append(newParticle)

            if particles.count > 15 {
                particles.removeFirst()
            }
        }
    }
}

struct ChargingParticle: View {
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 6, height: 6)
            .blur(radius: 2)
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 2)) {
                    offsetY = -300
                    opacity = 0
                }
            }
    }
}

struct BatteryStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SessionStat: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}

struct BatteryHistoryGraph: View {
    let history: [BatteryReading]

    var body: some View {
        GeometryReader { geo in
            let points = historyPoints(in: geo.size)

            ZStack {
                // Grid lines
                ForEach([0.25, 0.5, 0.75], id: \.self) { level in
                    Path { path in
                        let y = geo.size.height * (1 - CGFloat(level))
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }

                // Fill gradient
                Path { path in
                    guard !points.isEmpty else { return }
                    path.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                    path.addLine(to: points[0])

                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }

                    path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [.green.opacity(0.3), .green.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                Path { path in
                    guard !points.isEmpty else { return }
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [.green, .yellow, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // Current level dot
                if let lastPoint = points.last {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                        .position(lastPoint)
                }
            }
        }
    }

    private func historyPoints(in size: CGSize) -> [CGPoint] {
        guard history.count > 1 else { return [] }

        let xStep = size.width / CGFloat(max(1, history.count - 1))
        return history.enumerated().map { index, reading in
            CGPoint(
                x: CGFloat(index) * xStep,
                y: size.height * (1 - CGFloat(reading.level))
            )
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

struct UsageRow: View {
    let icon: String
    let label: String
    let time: String
    let progress: CGFloat
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(time)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
    }
}

struct BatteryTip: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.yellow)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models

/// A battery level reading at a point in time.
struct BatteryReading: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: CGFloat
    let isCharging: Bool
}

/// A battery-related event.
struct BatteryEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let title: String
    let detail: String
    let icon: String
    let color: Color
}

// MARK: - BatteryMonitor
/// Manages battery monitoring, history tracking, and statistics.
///
/// This class provides:
/// - Real-time battery level and state monitoring
/// - Battery level history with persistence
/// - Drain/charge rate calculation
/// - Usage time estimates
/// - Thermal state monitoring
/// - Session statistics tracking
@MainActor
class BatteryMonitor: ObservableObject {
    // MARK: Published Properties
    @Published var level: CGFloat = 0
    @Published var isCharging = false
    @Published var stateDescription = "Unknown"
    @Published var history: [BatteryReading] = []
    @Published var events: [BatteryEvent] = []

    // MARK: Private Properties
    private var sessionStartLevel: CGFloat = 0
    private var sessionStartTime = Date()
    private var lastLevel: CGFloat = 0
    private var lastLevelTime = Date()
    private var historyTimer: Timer?

    // MARK: Computed Properties - Health & State

    var healthStatus: String {
        // Simplified health based on level behavior
        if level > 0.2 { return "Good" }
        if level > 0.1 { return "Fair" }
        return "Low"
    }

    var healthColor: Color {
        if level > 0.2 { return .green }
        if level > 0.1 { return .yellow }
        return .red
    }

    var thermalState: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Normal"
        case .fair: return "Warm"
        case .serious: return "Hot"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    var thermalColor: Color {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }

    // MARK: Computed Properties - Drain Rate

    var drainRateDisplay: String {
        guard !isCharging else { return "N/A" }
        let elapsed = Date().timeIntervalSince(lastLevelTime)
        guard elapsed > 60, lastLevel > level else { return "--" }

        let drainPerHour = (lastLevel - level) / CGFloat(elapsed / 3600)
        return String(format: "%.1f%%/hr", drainPerHour * 100)
    }

    // MARK: Computed Properties - Time Estimates

    var estimatedTimeToFull: String? {
        guard isCharging, level < 1.0 else { return nil }
        let remaining = 1.0 - level
        // Estimate ~2 hours for full charge
        let hours = Double(remaining) * 2
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }
        return String(format: "%.1fh", hours)
    }

    var estimatedTimeRemaining: String? {
        guard !isCharging, level > 0 else { return nil }
        // Rough estimate: 10 hours at full
        let hours = Double(level) * 10
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }
        return String(format: "%.0fh", hours)
    }

    // MARK: Computed Properties - Session Stats

    var sessionDuration: String {
        let elapsed = Date().timeIntervalSince(sessionStartTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var sessionDrainDisplay: String {
        let drain = max(0, sessionStartLevel - level)
        return String(format: "%.0f%%", drain * 100)
    }

    var sessionChargeDisplay: String {
        let charge = max(0, level - sessionStartLevel)
        if charge > 0 {
            return String(format: "+%.0f%%", charge * 100)
        }
        return "0%"
    }

    // MARK: Computed Properties - Usage Estimates

    var videoTime: String { formatHours(Double(level) * 8) }
    var audioTime: String { formatHours(Double(level) * 40) }
    var browseTime: String { formatHours(Double(level) * 12) }
    var gamingTime: String { formatHours(Double(level) * 4) }
    var talkTime: String { formatHours(Double(level) * 20) }
    var standbyTime: String { formatHours(Double(level) * 200) }

    // MARK: Initialization

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBatteryInfo()
        sessionStartLevel = level
        lastLevel = level

        setupNotifications()
        startHistoryRecording()
    }

    // MARK: Private Methods

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleLevelChange()
        }

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleStateChange()
        }
    }

    private func updateBatteryInfo() {
        let device = UIDevice.current
        level = CGFloat(max(0, device.batteryLevel))

        switch device.batteryState {
        case .unknown:
            stateDescription = "Unknown"
            isCharging = false
        case .unplugged:
            stateDescription = "On Battery"
            isCharging = false
        case .charging:
            stateDescription = "Charging"
            isCharging = true
        case .full:
            stateDescription = "Fully Charged"
            isCharging = false
        @unknown default:
            stateDescription = "Unknown"
            isCharging = false
        }
    }

    private func handleLevelChange() {
        let previousLevel = level
        updateBatteryInfo()

        // Record history
        history.append(BatteryReading(
            timestamp: Date(),
            level: level,
            isCharging: isCharging
        ))

        // Keep last 100 readings
        if history.count > 100 {
            history.removeFirst()
        }

        // Log significant changes
        let change = level - previousLevel
        if abs(change) >= 0.05 {
            let event = BatteryEvent(
                timestamp: Date(),
                title: change > 0 ? "Battery Charged" : "Battery Drained",
                detail: String(format: "%+.0f%%", change * 100),
                icon: change > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                color: change > 0 ? .green : .orange
            )
            events.insert(event, at: 0)
            if events.count > 50 {
                events.removeLast()
            }
        }
    }

    private func handleStateChange() {
        let wasCharging = isCharging
        updateBatteryInfo()

        // Log state changes
        if wasCharging != isCharging {
            let event = BatteryEvent(
                timestamp: Date(),
                title: isCharging ? "Charging Started" : "Charging Stopped",
                detail: String(format: "%.0f%%", level * 100),
                icon: isCharging ? "bolt.fill" : "bolt.slash.fill",
                color: isCharging ? .yellow : .gray
            )
            events.insert(event, at: 0)

            // Update drain tracking
            lastLevel = level
            lastLevelTime = Date()
        }
    }

    private func startHistoryRecording() {
        // Record every 30 seconds
        historyTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.history.append(BatteryReading(
                    timestamp: Date(),
                    level: self.level,
                    isCharging: self.isCharging
                ))
                if self.history.count > 100 {
                    self.history.removeFirst()
                }
            }
        }
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        } else if hours < 10 {
            return String(format: "%.1fh", hours)
        } else {
            return "\(Int(hours))h"
        }
    }

    deinit {
        historyTimer?.invalidate()
    }
}

#Preview {
    NavigationStack {
        BatteryView()
    }
}
