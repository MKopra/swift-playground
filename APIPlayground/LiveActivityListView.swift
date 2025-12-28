import SwiftUI

/// Hub view listing all Live Activity demos
/// Each demo showcases a unique application of ActivityKit
struct LiveActivityListView: View {
    private let activities: [LiveActivityDemo] = [
        LiveActivityDemo(
            id: "delivery",
            title: "Delivery Tracking",
            subtitle: "Food delivery ETA with driver status",
            icon: "bag.fill",
            color: .orange
        ),
        LiveActivityDemo(
            id: "breathing",
            title: "Breath Pacer",
            subtitle: "Guided breathing with multiple patterns",
            icon: "lungs.fill",
            color: .mint
        ),
        LiveActivityDemo(
            id: "pomodoro",
            title: "Pomodoro Focus",
            subtitle: "25/5 work-break productivity cycles",
            icon: "timer",
            color: .red
        ),
        LiveActivityDemo(
            id: "parking",
            title: "Parking Meter",
            subtitle: "Countdown with urgency colors",
            icon: "car.fill",
            color: .blue
        ),
        LiveActivityDemo(
            id: "caffeine",
            title: "Caffeine Tracker",
            subtitle: "Watch caffeine metabolize in real-time",
            icon: "cup.and.saucer.fill",
            color: .brown
        ),
        LiveActivityDemo(
            id: "workout",
            title: "Gym Rest Timer",
            subtitle: "Rest between sets with rep tracking",
            icon: "dumbbell.fill",
            color: .purple
        ),
        LiveActivityDemo(
            id: "auction",
            title: "Auction Countdown",
            subtitle: "Last-second bidding timer",
            icon: "dollarsign.circle.fill",
            color: .green
        ),
        LiveActivityDemo(
            id: "launch",
            title: "Rocket Launch",
            subtitle: "T-minus countdown to liftoff",
            icon: "airplane.departure",
            color: .indigo
        ),
        LiveActivityDemo(
            id: "sports",
            title: "Sports Score",
            subtitle: "Live game score tracking",
            icon: "sportscourt.fill",
            color: .orange
        ),
        LiveActivityDemo(
            id: "egg",
            title: "Egg Timer",
            subtitle: "Perfect eggs every time",
            icon: "oval.fill",
            color: .yellow
        )
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(activities) { activity in
                    NavigationLink(value: activity) {
                        LiveActivityTile(demo: activity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Live Activities")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: LiveActivityDemo.self) { demo in
            destinationView(for: demo)
        }
    }

    @ViewBuilder
    private func destinationView(for demo: LiveActivityDemo) -> some View {
        switch demo.id {
        case "delivery":
            LiveActivityView()
        case "breathing":
            BreathingView()
        case "pomodoro":
            PomodoroView()
        case "parking":
            ParkingMeterView()
        case "caffeine":
            CaffeineTrackerView()
        case "workout":
            WorkoutRestView()
        case "auction":
            AuctionCountdownView()
        case "launch":
            RocketLaunchView()
        case "sports":
            SportsScoreView()
        case "egg":
            EggTimerView()
        default:
            Text("Coming Soon")
        }
    }
}

struct LiveActivityDemo: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct LiveActivityTile: View {
    let demo: LiveActivityDemo

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(demo.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: demo.icon)
                    .font(.title)
                    .foregroundStyle(demo.color)
            }

            VStack(spacing: 4) {
                Text(demo.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(demo.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

#Preview {
    NavigationStack {
        LiveActivityListView()
    }
}
