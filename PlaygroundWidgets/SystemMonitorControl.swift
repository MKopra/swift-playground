import WidgetKit
import SwiftUI
import AppIntents

// MARK: - System Info Control (iOS 18+)

@available(iOS 18.0, *)
struct SystemMonitorControl: ControlWidget {
    static let kind: String = "com.apiplayground.SystemMonitorControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: ShowSystemStatsIntent()) {
                let stats = SystemStats.current()

                Label {
                    Text("CPU \(Int(stats.cpuUsage * 100))%  RAM \(Int(stats.memoryUsagePercent * 100))%")
                } icon: {
                    Image(systemName: "cpu")
                }
            }
        }
        .displayName("System Info")
        .description("Shows CPU and RAM usage. Tap for details.")
    }
}

// MARK: - Show System Stats Intent (runs shortcut-style UI)

struct ShowSystemStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Show System Stats"
    static var description = IntentDescription("Shows current CPU and RAM statistics")

    // This tells the system to show the result in Siri/Shortcuts UI
    static var isDiscoverable: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let stats = SystemStats.current()

        let cpuPercent = Int(stats.cpuUsage * 100)
        let ramPercent = Int(stats.memoryUsagePercent * 100)
        let ramUsed = String(format: "%.1f", stats.memoryUsedGB)
        let ramTotal = String(format: "%.1f", stats.memoryTotalGB)

        return .result(
            dialog: "CPU: \(cpuPercent)% • RAM: \(ramPercent)%"
        ) {
            SystemStatsSnippetView(
                cpuPercent: cpuPercent,
                ramPercent: ramPercent,
                ramUsed: ramUsed,
                ramTotal: ramTotal
            )
        }
    }
}

// MARK: - Snippet View for Stats Display

struct SystemStatsSnippetView: View {
    let cpuPercent: Int
    let ramPercent: Int
    let ramUsed: String
    let ramTotal: String

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // CPU
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .opacity(0.2)
                            .foregroundStyle(.cyan)

                        Circle()
                            .trim(from: 0, to: Double(cpuPercent) / 100.0)
                            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .foregroundStyle(.cyan)
                            .rotationEffect(.degrees(-90))

                        Text("\(cpuPercent)%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .frame(width: 70, height: 70)

                    Text("CPU")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                // RAM
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .opacity(0.2)
                            .foregroundStyle(.green)

                        Circle()
                            .trim(from: 0, to: Double(ramPercent) / 100.0)
                            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .foregroundStyle(.green)
                            .rotationEffect(.degrees(-90))

                        Text("\(ramPercent)%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .frame(width: 70, height: 70)

                    Text("RAM")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(ramUsed) / \(ramTotal) GB used")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - App Shortcut for System Stats

struct SystemStatsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowSystemStatsIntent(),
            phrases: [
                "Show system stats in \(.applicationName)",
                "What's my CPU usage in \(.applicationName)",
                "Check RAM usage in \(.applicationName)",
                "System info \(.applicationName)"
            ],
            shortTitle: "System Info",
            systemImageName: "cpu"
        )
    }
}
