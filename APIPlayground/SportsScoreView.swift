import SwiftUI
import ActivityKit

/// Sports Score Tracker - Live game score updates
/// Classic Live Activity use case: real-time score updates
struct SportsScoreView: View {
    @StateObject private var manager = SportsActivityManager()
    @State private var homeTeam: String = "Lions"
    @State private var awayTeam: String = "Tigers"
    @State private var homeColor: Color = .blue
    @State private var awayColor: Color = .orange

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusCard
                if manager.isActive {
                    scoreboardCard
                    gameControlCard
                }
                configurationCard
                controlsCard
                infoCard
            }
            .padding()
        }
        .navigationTitle("Sports Score")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: manager.isActive ? "sportscourt.fill" : "sportscourt")
                        .foregroundStyle(manager.isActive ? .green : .secondary)
                        .font(.title2)
                    Text(manager.isActive ? "Game In Progress" : "No Active Game")
                        .font(.headline)
                    Spacer()
                    if manager.isActive {
                        Text(manager.quarter)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }

                if manager.isActive {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(manager.homeTeam) vs \(manager.awayTeam)")
                                .font(.subheadline)
                            Text(manager.timeRemaining)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Text("\(manager.homeScore)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: manager.homeColor))
                            Text("-")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("\(manager.awayScore)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: manager.awayColor))
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
            Label("Game Status", systemImage: "flag.checkered")
        }
    }

    // MARK: - Scoreboard Card
    private var scoreboardCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Main scoreboard
                HStack(spacing: 0) {
                    // Home team
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: manager.homeColor).opacity(0.2))
                                .frame(width: 60, height: 60)
                            Text(String(manager.homeTeam.prefix(1)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(hex: manager.homeColor))
                        }
                        Text(manager.homeTeam)
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("\(manager.homeScore)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: manager.homeColor))

                        if manager.possession == "home" {
                            Image(systemName: "football.fill")
                                .foregroundStyle(.brown)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Center divider
                    VStack(spacing: 8) {
                        Text(manager.quarter)
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(manager.timeRemaining)
                            .font(.title2)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 80)

                    // Away team
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: manager.awayColor).opacity(0.2))
                                .frame(width: 60, height: 60)
                            Text(String(manager.awayTeam.prefix(1)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(hex: manager.awayColor))
                        }
                        Text(manager.awayTeam)
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("\(manager.awayScore)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: manager.awayColor))

                        if manager.possession == "away" {
                            Image(systemName: "football.fill")
                                .foregroundStyle(.brown)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical)

                // Last play
                if !manager.lastPlay.isEmpty {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundStyle(.secondary)
                        Text(manager.lastPlay)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        } label: {
            Label("Scoreboard", systemImage: "rectangle.split.3x1")
        }
    }

    // MARK: - Game Control Card
    private var gameControlCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Score buttons
                HStack(spacing: 16) {
                    // Home scoring
                    VStack(spacing: 8) {
                        Text(manager.homeTeam)
                            .font(.caption)
                            .fontWeight(.bold)
                        HStack(spacing: 8) {
                            Button("+1") { manager.addScore(team: "home", points: 1) }
                                .buttonStyle(ScoreButtonStyle(color: Color(hex: manager.homeColor)))
                            Button("+3") { manager.addScore(team: "home", points: 3) }
                                .buttonStyle(ScoreButtonStyle(color: Color(hex: manager.homeColor)))
                            Button("+7") { manager.addScore(team: "home", points: 7) }
                                .buttonStyle(ScoreButtonStyle(color: Color(hex: manager.homeColor)))
                        }
                    }

                    Divider()

                    // Away scoring
                    VStack(spacing: 8) {
                        Text(manager.awayTeam)
                            .font(.caption)
                            .fontWeight(.bold)
                        HStack(spacing: 8) {
                            Button("+1") { manager.addScore(team: "away", points: 1) }
                                .buttonStyle(ScoreButtonStyle(color: Color(hex: manager.awayColor)))
                            Button("+3") { manager.addScore(team: "away", points: 3) }
                                .buttonStyle(ScoreButtonStyle(color: Color(hex: manager.awayColor)))
                            Button("+7") { manager.addScore(team: "away", points: 7) }
                                .buttonStyle(ScoreButtonStyle(color: Color(hex: manager.awayColor)))
                        }
                    }
                }

                Divider()

                // Game controls
                HStack(spacing: 12) {
                    Button {
                        manager.togglePossession()
                    } label: {
                        Label("Possession", systemImage: "arrow.left.arrow.right")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.purple.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.purple)
                    }

                    Button {
                        manager.advanceQuarter()
                    } label: {
                        Label("Next Quarter", systemImage: "forward.fill")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.blue)
                    }
                }
            }
        } label: {
            Label("Game Control", systemImage: "slider.horizontal.3")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                HStack {
                    TextField("Home Team", text: $homeTeam)
                        .textFieldStyle(.roundedBorder)
                        .disabled(manager.isActive)

                    ColorPicker("", selection: $homeColor)
                        .labelsHidden()
                        .disabled(manager.isActive)
                }

                HStack {
                    TextField("Away Team", text: $awayTeam)
                        .textFieldStyle(.roundedBorder)
                        .disabled(manager.isActive)

                    ColorPicker("", selection: $awayColor)
                        .labelsHidden()
                        .disabled(manager.isActive)
                }
            }
        } label: {
            Label("Teams", systemImage: "person.2")
        }
    }

    // MARK: - Controls Card
    private var controlsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                if !manager.isActive {
                    Button {
                        manager.startGame(
                            homeTeam: homeTeam,
                            awayTeam: awayTeam,
                            homeColor: homeColor.toHex(),
                            awayColor: awayColor.toHex()
                        )
                    } label: {
                        Label("Start Game", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    Button {
                        manager.endGame()
                    } label: {
                        Label("End Game", systemImage: "stop.fill")
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
                SportsInfoRow(title: "Score Updates", value: "Real-time")
                SportsInfoRow(title: "Possession", value: "Visual indicator")

                Divider()

                Text("Track live sports scores without constantly checking your phone. The Dynamic Island shows the current score, quarter, and time remaining at a glance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("About", systemImage: "info.circle")
        }
    }
}

struct ScoreButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.bold)
            .frame(width: 36, height: 36)
            .background(color, in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct SportsInfoRow: View {
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

// Color extension for hex conversion
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "0000FF" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

// MARK: - Sports Activity Manager

@MainActor
class SportsActivityManager: ObservableObject {
    @Published var isActive = false
    @Published var homeScore: Int = 0
    @Published var awayScore: Int = 0
    @Published var quarter: String = "Q1"
    @Published var timeRemaining: String = "15:00"
    @Published var possession: String = "home"
    @Published var lastPlay: String = ""
    @Published var homeTeam: String = ""
    @Published var awayTeam: String = ""
    @Published var homeColor: String = "0000FF"
    @Published var awayColor: String = "FF8000"
    @Published var statusMessage = "Ready to start game"

    private var currentActivity: Activity<SportsActivityAttributes>?
    private var timer: Timer?
    private var secondsRemaining: Int = 900 // 15 minutes per quarter
    private var currentQuarter: Int = 1

    init() {
        checkExistingActivities()
    }

    private func checkExistingActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<SportsActivityAttributes>.activities {
                currentActivity = activity
                isActive = true
                homeTeam = activity.attributes.homeTeam
                awayTeam = activity.attributes.awayTeam
                homeColor = activity.attributes.homeColor
                awayColor = activity.attributes.awayColor
                updateFromState(activity.content.state)
                statusMessage = "Resumed game"
                startTimer()
                break
            }
        }
    }

    private func updateFromState(_ state: SportsActivityAttributes.ContentState) {
        homeScore = state.homeScore
        awayScore = state.awayScore
        quarter = state.quarter
        timeRemaining = state.timeRemaining
        possession = state.possession
        lastPlay = state.lastPlay
    }

    func startGame(homeTeam: String, awayTeam: String, homeColor: String, awayColor: String) {
        guard #available(iOS 16.1, *) else {
            statusMessage = "Requires iOS 16.1+"
            return
        }

        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeColor = homeColor
        self.awayColor = awayColor
        self.homeScore = 0
        self.awayScore = 0
        self.quarter = "Q1"
        self.currentQuarter = 1
        self.secondsRemaining = 900
        self.timeRemaining = "15:00"
        self.possession = "home"
        self.lastPlay = "Game started"

        let attributes = SportsActivityAttributes(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeColor: homeColor,
            awayColor: awayColor
        )

        let initialState = SportsActivityAttributes.ContentState(
            homeScore: 0,
            awayScore: 0,
            quarter: "Q1",
            timeRemaining: "15:00",
            possession: "home",
            lastPlay: "Game started"
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isActive = true
            statusMessage = "Game started!"
            startTimer()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    func addScore(team: String, points: Int) {
        if team == "home" {
            homeScore += points
            lastPlay = "\(homeTeam) scored \(points)!"
        } else {
            awayScore += points
            lastPlay = "\(awayTeam) scored \(points)!"
        }
        statusMessage = lastPlay
        updateActivity()
    }

    func togglePossession() {
        possession = possession == "home" ? "away" : "home"
        lastPlay = "\(possession == "home" ? homeTeam : awayTeam) ball"
        updateActivity()
    }

    func advanceQuarter() {
        currentQuarter += 1
        if currentQuarter > 4 {
            endGame()
            return
        }
        quarter = "Q\(currentQuarter)"
        secondsRemaining = 900
        timeRemaining = "15:00"
        lastPlay = "Start of \(quarter)"
        statusMessage = lastPlay
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
        secondsRemaining -= 1
        if secondsRemaining < 0 {
            secondsRemaining = 0
        }

        let mins = secondsRemaining / 60
        let secs = secondsRemaining % 60
        timeRemaining = String(format: "%d:%02d", mins, secs)

        // Only update activity every 10 seconds to save resources
        if secondsRemaining % 10 == 0 {
            updateActivity()
        }
    }

    private func updateActivity() {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let updatedState = SportsActivityAttributes.ContentState(
            homeScore: homeScore,
            awayScore: awayScore,
            quarter: quarter,
            timeRemaining: timeRemaining,
            possession: possession,
            lastPlay: lastPlay
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }

    func endGame() {
        timer?.invalidate()
        timer = nil

        guard #available(iOS 16.1, *),
              let activity = currentActivity else {
            isActive = false
            return
        }

        let winner = homeScore > awayScore ? homeTeam : (awayScore > homeScore ? awayTeam : "Tie")
        lastPlay = homeScore == awayScore ? "Game ended in a tie!" : "\(winner) wins!"

        let finalState = SportsActivityAttributes.ContentState(
            homeScore: homeScore,
            awayScore: awayScore,
            quarter: "FINAL",
            timeRemaining: "0:00",
            possession: "",
            lastPlay: lastPlay
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                isActive = false
                currentActivity = nil
                statusMessage = lastPlay
            }
        }
    }
}

#Preview {
    NavigationStack {
        SportsScoreView()
    }
}
