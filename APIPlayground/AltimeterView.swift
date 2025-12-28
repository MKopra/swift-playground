import SwiftUI
import CoreMotion

// MARK: - AltimeterView
/// A comprehensive altimeter interface with elevation tracking and floor counting.
///
/// Features:
/// - Real-time relative altitude monitoring
/// - Barometric pressure display
/// - Elevation history graph with min/max tracking
/// - Floor counting (ascended/descended)
/// - Mountain visualization with climber indicator
/// - Temperature estimation based on altitude
/// - Animated cloud effects
///
/// APIs Demonstrated:
/// - CMAltimeter for altitude and pressure data
/// - CMPedometer for floor counting
/// - Relative altitude tracking
struct AltimeterView: View {
    @StateObject private var altimeter = AltimeterManager()
    @State private var showingHistory = false

    var body: some View {
        ZStack {
            // Sky gradient background
            LinearGradient(
                colors: skyColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Altitude gauge
                AltitudeGauge(altimeter: altimeter)
                    .padding(.top, 20)

                // Floor counter
                if altimeter.isFloorCountingAvailable {
                    FloorCounter(
                        floorsAscended: altimeter.floorsAscended,
                        floorsDescended: altimeter.floorsDescended
                    )
                    .padding(.top, 16)
                }

                // Mountain visualization
                MountainView(altitude: altimeter.relativeAltitude)
                    .frame(height: 150)
                    .padding(.top, 8)

                Spacer()

                // Stats cards
                HStack(spacing: 16) {
                    AltimeterStatCard(
                        icon: "gauge.with.dots.needle.bottom.50percent",
                        title: "Pressure",
                        value: String(format: "%.2f", altimeter.pressure),
                        unit: "kPa",
                        color: .blue
                    )

                    AltimeterStatCard(
                        icon: "thermometer.medium",
                        title: "Est. Temp",
                        value: String(format: "%.0f", estimatedTemp),
                        unit: "°C",
                        color: .orange
                    )

                    AltimeterStatCard(
                        icon: "arrow.up.arrow.down",
                        title: "Range",
                        value: String(format: "%.1f", altimeter.maxAltitude - altimeter.minAltitude),
                        unit: "m",
                        color: .green
                    )
                }
                .padding(.horizontal)

                // Elevation history button
                Button(action: { showingHistory = true }) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("View Elevation History")
                        Spacer()
                        Text("\(altimeter.altitudeHistory.count) points")
                            .foregroundStyle(.gray)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.top, 16)

                // Controls
                HStack(spacing: 16) {
                    Button(action: { altimeter.resetBaseline() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: { altimeter.clearHistory() }) {
                        Label("Clear", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Toggle("", isOn: $altimeter.isActive)
                        .labelsHidden()
                }
                .padding(.horizontal)
                .padding(.vertical, 16)

                if let error = altimeter.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.bottom, 8)
                }
            }
        }
        .navigationTitle("Altimeter")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingHistory) {
            ElevationHistoryView(altimeter: altimeter)
        }
        .onAppear { altimeter.start() }
        .onDisappear { altimeter.stop() }
    }

    private var skyColors: [Color] {
        let altitude = altimeter.relativeAltitude
        if altitude > 50 { return [Color(red: 0.1, green: 0.1, blue: 0.3), .blue] }
        if altitude > 20 { return [.blue, .cyan] }
        if altitude > 0 { return [.cyan, Color(red: 0.5, green: 0.8, blue: 1.0)] }
        return [Color(red: 0.3, green: 0.4, blue: 0.5), Color(red: 0.5, green: 0.6, blue: 0.7)]
    }

    private var estimatedTemp: Double {
        20 - (altimeter.relativeAltitude * 0.0065)
    }
}

// MARK: - AltitudeGauge
/// Circular gauge displaying current altitude.
struct AltitudeGauge: View {
    @ObservedObject var altimeter: AltimeterManager

    private var altitudeProgress: CGFloat {
        min(1.0, abs(altimeter.relativeAltitude) / 100)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 240, height: 240)

            Circle()
                .trim(from: 0, to: altitudeProgress)
                .stroke(
                    LinearGradient(
                        colors: altimeter.relativeAltitude >= 0
                            ? [.blue, .cyan, .green]
                            : [.purple, .red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.3), value: altitudeProgress)

            VStack(spacing: 4) {
                Image(systemName: altimeter.relativeAltitude >= 0 ? "arrow.up" : "arrow.down")
                    .font(.title)
                    .foregroundStyle(altimeter.relativeAltitude >= 0 ? .green : .red)

                Text(String(format: "%.1f", abs(altimeter.relativeAltitude)))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("meters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("MIN")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text(String(format: "%.1f", altimeter.minAltitude))
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    VStack(spacing: 2) {
                        Text("MAX")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Text(String(format: "%.1f", altimeter.maxAltitude))
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.top, 4)
            }

            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(.primary.opacity(0.3))
                    .frame(width: 2, height: i % 3 == 0 ? 15 : 8)
                    .offset(y: -95)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
    }
}

// MARK: - FloorCounter
/// Displays floors ascended and descended.
struct FloorCounter: View {
    let floorsAscended: Int
    let floorsDescended: Int

    var body: some View {
        HStack(spacing: 32) {
            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("\(floorsAscended)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("floors up")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                Text("\(floorsDescended)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("floors down")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - AltimeterStatCard
/// Statistics card for altimeter readings.
struct AltimeterStatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .monospacedDigit()
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ElevationHistoryView
/// Displays elevation history as a graph.
struct ElevationHistoryView: View {
    @ObservedObject var altimeter: AltimeterManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    HistoryStat(title: "Current", value: String(format: "%.1fm", altimeter.relativeAltitude), color: .blue)
                    HistoryStat(title: "Minimum", value: String(format: "%.1fm", altimeter.minAltitude), color: .purple)
                    HistoryStat(title: "Maximum", value: String(format: "%.1fm", altimeter.maxAltitude), color: .green)
                }
                .padding(.horizontal)

                ElevationGraph(history: altimeter.altitudeHistory, minAlt: altimeter.minAltitude, maxAlt: altimeter.maxAltitude)
                    .frame(height: 250)
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    Text("\(altimeter.altitudeHistory.count) data points")
                        .font(.subheadline)
                        .foregroundStyle(.gray)

                    if let first = altimeter.altitudeHistory.first?.timestamp,
                       let last = altimeter.altitudeHistory.last?.timestamp {
                        let duration = last.timeIntervalSince(first)
                        Text("Duration: \(formatDuration(duration))")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Elevation History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(minutes)m \(secs)s"
    }
}

// MARK: - HistoryStat
/// Single statistic for history view.
struct HistoryStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - ElevationGraph
/// Line graph showing elevation over time.
struct ElevationGraph: View {
    let history: [AltitudePoint]
    let minAlt: Double
    let maxAlt: Double

    var body: some View {
        GeometryReader { geo in
            let range = max(1, maxAlt - minAlt)
            let padding: CGFloat = 20

            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        Divider()
                        Spacer()
                    }
                }

                if minAlt <= 0 && maxAlt >= 0 {
                    let zeroY = geo.size.height - padding - ((0 - minAlt) / range * (geo.size.height - padding * 2))
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: zeroY))
                        path.addLine(to: CGPoint(x: geo.size.width, y: zeroY))
                    }
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }

                if history.count > 1 {
                    Path { path in
                        for (index, point) in history.enumerated() {
                            let x = CGFloat(index) / CGFloat(history.count - 1) * geo.size.width
                            let y = geo.size.height - padding - ((point.altitude - minAlt) / range * (geo.size.height - padding * 2))
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(colors: [.blue, .cyan, .green], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )

                    Path { path in
                        for (index, point) in history.enumerated() {
                            let x = CGFloat(index) / CGFloat(history.count - 1) * geo.size.width
                            let y = geo.size.height - padding - ((point.altitude - minAlt) / range * (geo.size.height - padding * 2))
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: geo.size.height - padding))
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - padding))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                }

                VStack {
                    Text(String(format: "%.1fm", maxAlt))
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(String(format: "%.1fm", minAlt))
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - MountainView
/// Animated mountain visualization with altitude indicator.
struct MountainView: View {
    let altitude: Double
    @State private var cloudOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MountainShape(peaks: [0.3, 0.6, 0.4, 0.7, 0.5])
                    .fill(Color.gray.opacity(0.3))
                    .offset(y: 20)

                MountainShape(peaks: [0.4, 0.8, 0.3, 0.6, 0.5, 0.7])
                    .fill(LinearGradient(colors: [Color(red: 0.3, green: 0.35, blue: 0.4), Color(red: 0.4, green: 0.45, blue: 0.5)], startPoint: .top, endPoint: .bottom))

                Circle()
                    .fill(.red)
                    .frame(width: 12, height: 12)
                    .shadow(color: .red, radius: 5)
                    .offset(x: 0, y: -min(max(altitude, 0), 100) * 1.2)

                ForEach(0..<3, id: \.self) { i in
                    CloudShape()
                        .fill(.white.opacity(0.6))
                        .frame(width: 60, height: 30)
                        .offset(x: -geo.size.width / 2 + CGFloat(i) * 80 + cloudOffset, y: -40 + CGFloat(i) * 20)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                cloudOffset = 200
            }
        }
    }
}

// MARK: - MountainShape
/// Custom mountain silhouette shape.
struct MountainShape: Shape {
    let peaks: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: 0, y: height))
        let segmentWidth = width / CGFloat(peaks.count - 1)
        for (i, peak) in peaks.enumerated() {
            let x = CGFloat(i) * segmentWidth
            let y = height - (CGFloat(peak) * height)
            if i == 0 {
                path.addLine(to: CGPoint(x: x, y: y))
            } else {
                let prevX = CGFloat(i - 1) * segmentWidth
                let controlX = (prevX + x) / 2
                path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: controlX, y: y - 20))
            }
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

// MARK: - CloudShape
/// Fluffy cloud shape.
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: 0, y: rect.height * 0.3, width: rect.width * 0.5, height: rect.height * 0.7))
        path.addEllipse(in: CGRect(x: rect.width * 0.25, y: 0, width: rect.width * 0.5, height: rect.height * 0.8))
        path.addEllipse(in: CGRect(x: rect.width * 0.5, y: rect.height * 0.2, width: rect.width * 0.5, height: rect.height * 0.8))
        return path
    }
}

// MARK: - AltitudePoint
/// Single altitude measurement with timestamp.
struct AltitudePoint: Identifiable {
    let id = UUID()
    let altitude: Double
    let timestamp: Date
}

// MARK: - AltimeterManager
/// Manages altimeter updates, floor counting, and history tracking.
///
/// This class provides:
/// - Relative altitude monitoring
/// - Barometric pressure readings
/// - Floor counting (ascended/descended)
/// - Altitude history with min/max tracking
/// - Baseline reset functionality
@MainActor
class AltimeterManager: ObservableObject {
    @Published var pressure: Double = 101.325
    @Published var relativeAltitude: Double = 0
    @Published var minAltitude: Double = 0
    @Published var maxAltitude: Double = 0
    @Published var floorsAscended: Int = 0
    @Published var floorsDescended: Int = 0
    @Published var altitudeHistory: [AltitudePoint] = []
    @Published var error: String?
    @Published var isActive = true {
        didSet { if isActive { start() } else { stop() } }
    }

    var isFloorCountingAvailable: Bool { CMPedometer.isFloorCountingAvailable() }

    private let altimeter = CMAltimeter()
    private let pedometer = CMPedometer()
    private var baselineAltitude: Double?
    private var lastHistoryUpdate: Date?

    func start() {
        startAltimeter()
        startFloorCounting()
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
        pedometer.stopUpdates()
    }

    func resetBaseline() {
        baselineAltitude = nil
        minAltitude = 0
        maxAltitude = 0
    }

    func clearHistory() {
        altitudeHistory.removeAll()
        minAltitude = relativeAltitude
        maxAltitude = relativeAltitude
    }

    private func startAltimeter() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            error = "Altimeter not available"
            return
        }

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else {
                Task { @MainActor in self?.error = error?.localizedDescription }
                return
            }
            Task { @MainActor in
                self.pressure = data.pressure.doubleValue
                let altitude = data.relativeAltitude.doubleValue
                if self.baselineAltitude == nil {
                    self.baselineAltitude = altitude
                    self.minAltitude = 0
                    self.maxAltitude = 0
                }
                let relative = altitude - (self.baselineAltitude ?? 0)
                self.relativeAltitude = relative
                if relative < self.minAltitude { self.minAltitude = relative }
                if relative > self.maxAltitude { self.maxAltitude = relative }
                let now = Date()
                if self.lastHistoryUpdate == nil || now.timeIntervalSince(self.lastHistoryUpdate!) >= 0.5 {
                    self.altitudeHistory.append(AltitudePoint(altitude: relative, timestamp: now))
                    self.lastHistoryUpdate = now
                    if self.altitudeHistory.count > 500 { self.altitudeHistory.removeFirst() }
                }
            }
        }
    }

    private func startFloorCounting() {
        guard CMPedometer.isFloorCountingAvailable() else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: startOfDay) { [weak self] data, _ in
            guard let data = data else { return }
            Task { @MainActor in
                self?.floorsAscended = data.floorsAscended?.intValue ?? 0
                self?.floorsDescended = data.floorsDescended?.intValue ?? 0
            }
        }
    }
}

#Preview {
    NavigationStack {
        AltimeterView()
    }
}
