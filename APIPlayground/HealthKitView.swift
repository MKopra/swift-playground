import SwiftUI
import HealthKit

// MARK: - HealthKitView
/// A comprehensive health data interface using HealthKit.
///
/// Features:
/// - Step count tracking with daily history
/// - Heart rate monitoring with trends
/// - Activity rings visualization
/// - Sleep analysis with stages
/// - Workout history
/// - Body measurements
/// - Respiratory data
/// - Nutrition tracking
///
/// APIs Demonstrated:
/// - HKHealthStore for data access
/// - HKStatisticsQuery for aggregated data
/// - HKSampleQuery for individual samples
/// - HKActivitySummaryQuery for activity rings
/// - HKStatisticsCollectionQuery for historical data
/// - HKWorkoutType for workout data
/// - HKCharacteristicType for user characteristics
///
/// Note: This API is NOT available in Flutter - requires native HealthKit implementation.
/// HealthKit provides secure access to health and fitness data with user permission.
struct HealthKitView: View {
    @StateObject private var healthManager = ComprehensiveHealthManager()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Dark mode background gradient
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.12, green: 0.12, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if healthManager.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading Health Data...")
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 16)
                    Spacer()
                } else if !healthManager.isHealthKitAvailable {
                    HealthKitUnavailableView()
                } else if !healthManager.isAuthorized && healthManager.authorizationError == nil {
                    DarkAuthorizationCard(healthManager: healthManager)
                        .padding()
                } else {
                    // Demo mode banner if showing demo data
                    if healthManager.isDemoMode {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.cyan)
                            Text("Demo Mode - HealthKit requires entitlements")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(.cyan.opacity(0.15))
                    }

                    // Tab selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(HealthTab.allCases, id: \.self) { tab in
                                TabButton(title: tab.title, icon: tab.icon, isSelected: selectedTab == tab.rawValue) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedTab = tab.rawValue
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    // Content
                    ScrollView {
                        VStack(spacing: 16) {
                            switch HealthTab(rawValue: selectedTab) {
                            case .activity:
                                ActivitySection(healthManager: healthManager)
                            case .heart:
                                HeartSection(healthManager: healthManager)
                            case .sleep:
                                SleepSection(healthManager: healthManager)
                            case .body:
                                BodySection(healthManager: healthManager)
                            case .workouts:
                                WorkoutsSection(healthManager: healthManager)
                            case .nutrition:
                                NutritionSection(healthManager: healthManager)
                            case .none:
                                EmptyView()
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Health")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await healthManager.initialize()
        }
    }
}

// MARK: - Health Tabs
enum HealthTab: Int, CaseIterable {
    case activity = 0
    case heart = 1
    case sleep = 2
    case body = 3
    case workouts = 4
    case nutrition = 5

    var title: String {
        switch self {
        case .activity: return "Activity"
        case .heart: return "Heart"
        case .sleep: return "Sleep"
        case .body: return "Body"
        case .workouts: return "Workouts"
        case .nutrition: return "Nutrition"
        }
    }

    var icon: String {
        switch self {
        case .activity: return "figure.walk"
        case .heart: return "heart.fill"
        case .sleep: return "moon.zzz.fill"
        case .body: return "figure.stand"
        case .workouts: return "flame.fill"
        case .nutrition: return "fork.knife"
        }
    }
}

// MARK: - TabButton
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.pink : Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - HealthKitUnavailableView
struct HealthKitUnavailableView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 70))
                .foregroundStyle(.gray)

            Text("HealthKit Not Available")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("This device does not support HealthKit. HealthKit is available on iPhone and Apple Watch.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - DarkAuthorizationCard
struct DarkAuthorizationCard: View {
    @ObservedObject var healthManager: ComprehensiveHealthManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundStyle(.pink)

            Text("Access Your Health Data")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Grant access to view comprehensive health metrics including activity, heart rate, sleep, workouts, and more.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            if healthManager.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            } else {
                Button(action: { Task { await healthManager.requestAuthorization() } }) {
                    Text("Authorize Health Access")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            if let error = healthManager.authorizationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Activity Section
struct ActivitySection: View {
    @ObservedObject var healthManager: ComprehensiveHealthManager

    var body: some View {
        VStack(spacing: 16) {
            // Activity Rings
            DarkActivityRingsCard(summary: healthManager.activitySummary)

            // Steps Card
            DarkMetricCard(
                title: "Steps",
                value: healthManager.stepCount.formatted(.number.grouping(.automatic)),
                subtitle: "Today",
                icon: "figure.walk",
                color: .green,
                trend: healthManager.stepsTrend
            )

            // Distance Card
            DarkMetricCard(
                title: "Distance",
                value: String(format: "%.2f km", healthManager.distance / 1000),
                subtitle: "Today",
                icon: "location.fill",
                color: .blue,
                trend: nil
            )

            // Active Calories
            DarkMetricCard(
                title: "Active Calories",
                value: "\(Int(healthManager.activeCalories))",
                subtitle: "kcal burned",
                icon: "flame.fill",
                color: .orange,
                trend: nil
            )

            // Flights Climbed
            DarkMetricCard(
                title: "Flights Climbed",
                value: "\(healthManager.flightsClimbed)",
                subtitle: "floors",
                icon: "figure.stairs",
                color: .cyan,
                trend: nil
            )

            // Stand Hours
            DarkMetricCard(
                title: "Stand Hours",
                value: "\(healthManager.standHours)/12",
                subtitle: "hours",
                icon: "figure.stand",
                color: .teal,
                trend: nil
            )

            // Exercise Minutes
            DarkMetricCard(
                title: "Exercise",
                value: "\(healthManager.exerciseMinutes)",
                subtitle: "minutes",
                icon: "bolt.fill",
                color: .yellow,
                trend: nil
            )

            // Steps History
            if !healthManager.stepHistory.isEmpty {
                DarkStepsHistoryCard(history: healthManager.stepHistory)
            }
        }
    }
}

// MARK: - Heart Section
struct HeartSection: View {
    @ObservedObject var healthManager: ComprehensiveHealthManager

    var body: some View {
        VStack(spacing: 16) {
            // Current Heart Rate
            DarkHeartRateCard(
                currentRate: healthManager.heartRate,
                restingRate: healthManager.restingHeartRate,
                walkingRate: healthManager.walkingHeartRate
            )

            // Heart Rate Variability
            DarkMetricCard(
                title: "Heart Rate Variability",
                value: String(format: "%.0f ms", healthManager.heartRateVariability),
                subtitle: "SDNN",
                icon: "waveform.path.ecg",
                color: .purple,
                trend: nil
            )

            // Blood Oxygen
            DarkMetricCard(
                title: "Blood Oxygen",
                value: String(format: "%.0f%%", healthManager.bloodOxygen),
                subtitle: "SpO2",
                icon: "drop.fill",
                color: .red,
                trend: nil
            )

            // Respiratory Rate
            DarkMetricCard(
                title: "Respiratory Rate",
                value: String(format: "%.0f", healthManager.respiratoryRate),
                subtitle: "breaths/min",
                icon: "lungs.fill",
                color: .cyan,
                trend: nil
            )

            // Heart Rate History
            if !healthManager.heartRateHistory.isEmpty {
                DarkHeartRateHistoryCard(history: healthManager.heartRateHistory)
            }
        }
    }
}

// MARK: - Sleep Section
struct SleepSection: View {
    @ObservedObject var healthManager: ComprehensiveHealthManager

    var body: some View {
        VStack(spacing: 16) {
            // Sleep Summary
            DarkSleepSummaryCard(
                totalSleep: healthManager.sleepHours,
                deepSleep: healthManager.deepSleepHours,
                remSleep: healthManager.remSleepHours,
                coreSleep: healthManager.coreSleepHours,
                awakeTime: healthManager.awakeTimeHours
            )

            // Sleep Goal Progress
            DarkMetricCard(
                title: "Sleep Goal",
                value: String(format: "%.1f / 8 hrs", healthManager.sleepHours),
                subtitle: "Last night",
                icon: "moon.zzz.fill",
                color: .indigo,
                trend: nil
            )

            // Time in Bed
            DarkMetricCard(
                title: "Time in Bed",
                value: String(format: "%.1f hrs", healthManager.timeInBed),
                subtitle: "Last night",
                icon: "bed.double.fill",
                color: .purple,
                trend: nil
            )

            // Bedtime
            if let bedtime = healthManager.bedtime {
                DarkMetricCard(
                    title: "Bedtime",
                    value: bedtime.formatted(date: .omitted, time: .shortened),
                    subtitle: "Last night",
                    icon: "moon.fill",
                    color: .indigo,
                    trend: nil
                )
            }

            // Wake Time
            if let wakeTime = healthManager.wakeTime {
                DarkMetricCard(
                    title: "Wake Time",
                    value: wakeTime.formatted(date: .omitted, time: .shortened),
                    subtitle: "This morning",
                    icon: "sunrise.fill",
                    color: .orange,
                    trend: nil
                )
            }

            // Sleep Efficiency
            if healthManager.timeInBed > 0 {
                let efficiency = (healthManager.sleepHours / healthManager.timeInBed) * 100
                DarkMetricCard(
                    title: "Sleep Efficiency",
                    value: String(format: "%.0f%%", efficiency),
                    subtitle: "Time asleep vs in bed",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    trend: nil
                )
            }
        }
    }
}

// MARK: - Body Section
struct BodySection: View {
    @ObservedObject var healthManager: ComprehensiveHealthManager

    var body: some View {
        VStack(spacing: 16) {
            // Weight
            DarkMetricCard(
                title: "Weight",
                value: String(format: "%.1f kg", healthManager.weight),
                subtitle: "Latest",
                icon: "scalemass.fill",
                color: .blue,
                trend: healthManager.weightTrend
            )

            // Height
            DarkMetricCard(
                title: "Height",
                value: String(format: "%.0f cm", healthManager.height * 100),
                subtitle: "Recorded",
                icon: "ruler.fill",
                color: .green,
                trend: nil
            )

            // BMI
            if healthManager.weight > 0 && healthManager.height > 0 {
                let bmi = healthManager.weight / (healthManager.height * healthManager.height)
                DarkMetricCard(
                    title: "BMI",
                    value: String(format: "%.1f", bmi),
                    subtitle: bmiCategory(bmi),
                    icon: "figure.stand",
                    color: bmiColor(bmi),
                    trend: nil
                )
            }

            // Body Fat Percentage
            if healthManager.bodyFatPercentage > 0 {
                DarkMetricCard(
                    title: "Body Fat",
                    value: String(format: "%.1f%%", healthManager.bodyFatPercentage),
                    subtitle: "Estimated",
                    icon: "percent",
                    color: .orange,
                    trend: nil
                )
            }

            // Lean Body Mass
            if healthManager.leanBodyMass > 0 {
                DarkMetricCard(
                    title: "Lean Body Mass",
                    value: String(format: "%.1f kg", healthManager.leanBodyMass),
                    subtitle: "Estimated",
                    icon: "figure.strengthtraining.traditional",
                    color: .purple,
                    trend: nil
                )
            }

            // Waist Circumference
            if healthManager.waistCircumference > 0 {
                DarkMetricCard(
                    title: "Waist",
                    value: String(format: "%.0f cm", healthManager.waistCircumference * 100),
                    subtitle: "Circumference",
                    icon: "circle.dashed",
                    color: .cyan,
                    trend: nil
                )
            }
        }
    }

    private func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    private func bmiColor(_ bmi: Double) -> Color {
        switch bmi {
        case ..<18.5: return .orange
        case 18.5..<25: return .green
        case 25..<30: return .yellow
        default: return .red
        }
    }
}

// MARK: - Workouts Section
struct WorkoutsSection: View {
    @ObservedObject var healthManager: ComprehensiveHealthManager

    var body: some View {
        VStack(spacing: 16) {
            // Workout Summary
            DarkMetricCard(
                title: "Workouts This Week",
                value: "\(healthManager.workoutsThisWeek)",
                subtitle: "sessions",
                icon: "figure.run",
                color: .green,
                trend: nil
            )

            // Total Workout Duration
            DarkMetricCard(
                title: "Total Duration",
                value: formatDuration(healthManager.totalWorkoutDuration),
                subtitle: "this week",
                icon: "timer",
                color: .orange,
                trend: nil
            )

            // Workout Calories
            DarkMetricCard(
                title: "Workout Calories",
                value: "\(Int(healthManager.workoutCalories))",
                subtitle: "kcal this week",
                icon: "flame.fill",
                color: .red,
                trend: nil
            )

            // Recent Workouts
            if !healthManager.recentWorkouts.isEmpty {
                DarkWorkoutsCard(workouts: healthManager.recentWorkouts)
            }

            // VO2 Max
            if healthManager.vo2Max > 0 {
                DarkMetricCard(
                    title: "VO2 Max",
                    value: String(format: "%.1f", healthManager.vo2Max),
                    subtitle: "mL/kg/min",
                    icon: "lungs.fill",
                    color: .purple,
                    trend: nil
                )
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

// MARK: - Nutrition Section
struct NutritionSection: View {
    @ObservedObject var healthManager: ComprehensiveHealthManager

    var body: some View {
        VStack(spacing: 16) {
            // Dietary Energy
            DarkMetricCard(
                title: "Calories Consumed",
                value: "\(Int(healthManager.dietaryEnergy))",
                subtitle: "kcal today",
                icon: "fork.knife",
                color: .orange,
                trend: nil
            )

            // Water Intake
            DarkMetricCard(
                title: "Water",
                value: String(format: "%.1f L", healthManager.waterIntake),
                subtitle: "today",
                icon: "drop.fill",
                color: .blue,
                trend: nil
            )

            // Caffeine
            DarkMetricCard(
                title: "Caffeine",
                value: "\(Int(healthManager.caffeineIntake))",
                subtitle: "mg today",
                icon: "cup.and.saucer.fill",
                color: .brown,
                trend: nil
            )

            // Protein
            DarkMetricCard(
                title: "Protein",
                value: String(format: "%.0f g", healthManager.proteinIntake),
                subtitle: "today",
                icon: "fish.fill",
                color: .red,
                trend: nil
            )

            // Carbohydrates
            DarkMetricCard(
                title: "Carbohydrates",
                value: String(format: "%.0f g", healthManager.carbsIntake),
                subtitle: "today",
                icon: "leaf.fill",
                color: .green,
                trend: nil
            )

            // Fat
            DarkMetricCard(
                title: "Fat",
                value: String(format: "%.0f g", healthManager.fatIntake),
                subtitle: "today",
                icon: "drop.triangle.fill",
                color: .yellow,
                trend: nil
            )

            // Mindful Minutes
            DarkMetricCard(
                title: "Mindful Minutes",
                value: "\(healthManager.mindfulMinutes)",
                subtitle: "today",
                icon: "brain.head.profile",
                color: .purple,
                trend: nil
            )
        }
    }
}

// MARK: - Dark Mode Cards

struct DarkActivityRingsCard: View {
    let summary: ActivitySummaryData?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Rings")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                // Rings visualization
                ZStack {
                    // Move ring (red)
                    DarkRingView(
                        progress: summary?.moveProgress ?? 0,
                        color: .red,
                        lineWidth: 14
                    )
                    .frame(width: 110, height: 110)

                    // Exercise ring (green)
                    DarkRingView(
                        progress: summary?.exerciseProgress ?? 0,
                        color: .green,
                        lineWidth: 14
                    )
                    .frame(width: 82, height: 82)

                    // Stand ring (blue)
                    DarkRingView(
                        progress: summary?.standProgress ?? 0,
                        color: .cyan,
                        lineWidth: 14
                    )
                    .frame(width: 54, height: 54)
                }

                // Ring labels
                VStack(alignment: .leading, spacing: 10) {
                    DarkRingLabel(
                        title: "Move",
                        value: "\(Int(summary?.activeCalories ?? 0))",
                        goal: "\(Int(summary?.moveGoal ?? 500))",
                        unit: "CAL",
                        color: .red
                    )

                    DarkRingLabel(
                        title: "Exercise",
                        value: "\(Int(summary?.exerciseMinutes ?? 0))",
                        goal: "\(Int(summary?.exerciseGoal ?? 30))",
                        unit: "MIN",
                        color: .green
                    )

                    DarkRingLabel(
                        title: "Stand",
                        value: "\(Int(summary?.standHours ?? 0))",
                        goal: "\(Int(summary?.standGoal ?? 12))",
                        unit: "HRS",
                        color: .cyan
                    )
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DarkRingView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.25), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 4)
        }
    }
}

struct DarkRingLabel: View {
    let title: String
    let value: String
    let goal: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Text("\(value)/\(goal)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

struct DarkMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: Double?

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            if let trend = trend {
                DarkTrendIndicator(trend: trend)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DarkTrendIndicator: View {
    let trend: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
            Text(String(format: "%.0f%%", abs(trend)))
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(trend >= 0 ? .green : .red)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((trend >= 0 ? Color.green : Color.red).opacity(0.2), in: Capsule())
    }
}

struct DarkHeartRateCard: View {
    let currentRate: Double
    let restingRate: Double
    let walkingRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title)
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse.byLayer, options: .repeating)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Heart Rate")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Latest reading")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(currentRate))")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("BPM")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            Divider()
                .background(.white.opacity(0.2))

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resting")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(restingRate))")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text("BPM")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Walking Avg")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(walkingRate))")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text("BPM")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DarkStepsHistoryCard: View {
    let history: [DailySteps]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Steps This Week")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(history.suffix(7)) { day in
                    VStack(spacing: 6) {
                        Text(day.steps >= 10000 ? "10k+" : "\(day.steps / 1000)k")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                day.steps >= 10000
                                    ? LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.green.opacity(0.6), .green.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: 32, height: max(15, CGFloat(day.steps) / 180))
                            .frame(maxHeight: 100)

                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DarkHeartRateHistoryCard: View {
    let history: [HeartRateSample]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heart Rate Today")
                .font(.headline)
                .foregroundStyle(.white)

            if history.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Range")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))

                        let minRate = history.map(\.rate).min() ?? 0
                        let maxRate = history.map(\.rate).max() ?? 0
                        Text("\(Int(minRate)) - \(Int(maxRate)) BPM")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Average")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))

                        let avgRate = history.map(\.rate).reduce(0, +) / Double(history.count)
                        Text("\(Int(avgRate)) BPM")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DarkSleepSummaryCard: View {
    let totalSleep: Double
    let deepSleep: Double
    let remSleep: Double
    let coreSleep: Double
    let awakeTime: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.fill")
                    .font(.title)
                    .foregroundStyle(.indigo)

                Text("Sleep Analysis")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f", totalSleep))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("hours")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Sleep stages bar
            GeometryReader { geo in
                let total = deepSleep + remSleep + coreSleep + awakeTime
                let deepWidth = total > 0 ? geo.size.width * (deepSleep / total) : 0
                let remWidth = total > 0 ? geo.size.width * (remSleep / total) : 0
                let coreWidth = total > 0 ? geo.size.width * (coreSleep / total) : 0
                let awakeWidth = total > 0 ? geo.size.width * (awakeTime / total) : 0

                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.indigo)
                        .frame(width: deepWidth)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.purple)
                        .frame(width: remWidth)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cyan)
                        .frame(width: coreWidth)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.opacity(0.5))
                        .frame(width: awakeWidth)
                }
            }
            .frame(height: 12)

            // Sleep breakdown
            HStack(spacing: 16) {
                DarkSleepPhaseIndicator(phase: "Deep", hours: deepSleep, color: .indigo)
                DarkSleepPhaseIndicator(phase: "REM", hours: remSleep, color: .purple)
                DarkSleepPhaseIndicator(phase: "Core", hours: coreSleep, color: .cyan)
                DarkSleepPhaseIndicator(phase: "Awake", hours: awakeTime, color: .orange)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DarkSleepPhaseIndicator: View {
    let phase: String
    let hours: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(phase)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))

            Text(String(format: "%.1fh", hours))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
    }
}

struct DarkWorkoutsCard: View {
    let workouts: [WorkoutData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(workouts.prefix(5)) { workout in
                HStack(spacing: 12) {
                    Image(systemName: workout.icon)
                        .font(.title3)
                        .foregroundStyle(workout.color)
                        .frame(width: 40, height: 40)
                        .background(workout.color.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.type)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)

                        Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDuration(workout.duration))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)

                        Text("\(Int(workout.calories)) cal")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.vertical, 4)

                if workout.id != workouts.prefix(5).last?.id {
                    Divider()
                        .background(.white.opacity(0.1))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

// MARK: - Data Models

struct DailySteps: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
}

struct HeartRateSample: Identifiable {
    let id = UUID()
    let date: Date
    let rate: Double
}

struct ActivitySummaryData {
    let activeCalories: Double
    let moveGoal: Double
    let exerciseMinutes: Double
    let exerciseGoal: Double
    let standHours: Double
    let standGoal: Double

    var moveProgress: Double { moveGoal > 0 ? activeCalories / moveGoal : 0 }
    var exerciseProgress: Double { exerciseGoal > 0 ? exerciseMinutes / exerciseGoal : 0 }
    var standProgress: Double { standGoal > 0 ? standHours / standGoal : 0 }
}

struct WorkoutData: Identifiable {
    let id = UUID()
    let type: String
    let date: Date
    let duration: TimeInterval
    let calories: Double
    let icon: String
    let color: Color
}

// MARK: - ComprehensiveHealthManager
/// A comprehensive health manager that fetches real HealthKit data
/// with graceful fallback to demo mode if permissions aren't available
@MainActor
class ComprehensiveHealthManager: ObservableObject {
    // MARK: State Properties
    @Published var isHealthKitAvailable = false
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var isDemoMode = false
    @Published var authorizationError: String?

    // MARK: Activity Properties
    @Published var stepCount: Double = 0
    @Published var stepsTrend: Double = 0
    @Published var distance: Double = 0
    @Published var activeCalories: Double = 0
    @Published var flightsClimbed: Int = 0
    @Published var standHours: Int = 0
    @Published var exerciseMinutes: Int = 0
    @Published var stepHistory: [DailySteps] = []
    @Published var activitySummary: ActivitySummaryData?

    // MARK: Heart Properties
    @Published var heartRate: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var walkingHeartRate: Double = 0
    @Published var heartRateVariability: Double = 0
    @Published var bloodOxygen: Double = 0
    @Published var respiratoryRate: Double = 0
    @Published var heartRateHistory: [HeartRateSample] = []

    // MARK: Sleep Properties
    @Published var sleepHours: Double = 0
    @Published var deepSleepHours: Double = 0
    @Published var remSleepHours: Double = 0
    @Published var coreSleepHours: Double = 0
    @Published var awakeTimeHours: Double = 0
    @Published var timeInBed: Double = 0
    @Published var bedtime: Date?
    @Published var wakeTime: Date?

    // MARK: Body Properties
    @Published var weight: Double = 0
    @Published var weightTrend: Double = 0
    @Published var height: Double = 0
    @Published var bodyFatPercentage: Double = 0
    @Published var leanBodyMass: Double = 0
    @Published var waistCircumference: Double = 0

    // MARK: Workout Properties
    @Published var workoutsThisWeek: Int = 0
    @Published var totalWorkoutDuration: TimeInterval = 0
    @Published var workoutCalories: Double = 0
    @Published var vo2Max: Double = 0
    @Published var recentWorkouts: [WorkoutData] = []

    // MARK: Nutrition Properties
    @Published var dietaryEnergy: Double = 0
    @Published var waterIntake: Double = 0
    @Published var caffeineIntake: Double = 0
    @Published var proteinIntake: Double = 0
    @Published var carbsIntake: Double = 0
    @Published var fatIntake: Double = 0
    @Published var mindfulMinutes: Int = 0

    // MARK: Private Properties
    private var healthStore: HKHealthStore?

    // MARK: Initialization
    init() {
        // Check if HealthKit is available on this device
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        if isHealthKitAvailable {
            healthStore = HKHealthStore()
        }
    }

    // MARK: Public Methods

    func initialize() async {
        guard isHealthKitAvailable else {
            authorizationError = "HealthKit is not available on this device."
            return
        }

        isLoading = true
        // Don't auto-request, let user tap the authorize button
        isLoading = false
    }

    func requestAuthorization() async {
        guard let healthStore = healthStore else {
            showDemoMode()
            return
        }

        isLoading = true
        authorizationError = nil

        // Build types to read
        var typesToRead: Set<HKObjectType> = []

        if let t = HKQuantityType.quantityType(forIdentifier: .stepCount) { typesToRead.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) { typesToRead.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { typesToRead.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .heartRate) { typesToRead.insert(t) }
        if let t = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { typesToRead.insert(t) }
        typesToRead.insert(HKObjectType.activitySummaryType())

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            await fetchHealthDataSafely()
        } catch {
            print("HealthKit authorization error: \(error)")
            authorizationError = "HealthKit requires the HealthKit entitlement. Using demo data."
            showDemoMode()
        }

        isLoading = false
    }

    private func fetchHealthDataSafely() async {
        guard let healthStore = healthStore else { return }

        // Fetch step count
        if let type = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

            do {
                let value = try await fetchStatistic(healthStore: healthStore, type: type, predicate: predicate, unit: .count())
                stepCount = value
            } catch {
                print("Step count error: \(error)")
            }
        }

        // Fetch heart rate
        if let type = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            do {
                let value = try await fetchLatestSample(healthStore: healthStore, type: type, unit: HKUnit.count().unitDivided(by: .minute()))
                heartRate = value
            } catch {
                print("Heart rate error: \(error)")
            }
        }

        // Data fetched successfully - don't fall into demo mode just because values are 0
        // User might legitimately have 0 steps or no recent heart rate
        isDemoMode = false
    }

    private func fetchStatistic(healthStore: HKHealthStore, type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                    continuation.resume(returning: value)
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatestSample(healthStore: HKHealthStore, type: HKQuantityType, unit: HKUnit) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = samples?.first as? HKQuantitySample {
                    let value = sample.quantity.doubleValue(for: unit)
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }

    private func fillDemoDataForMissingFields() {
        // Fill in realistic demo data for fields we couldn't fetch
        if distance == 0 { distance = 6_230 }
        if activeCalories == 0 { activeCalories = 423 }
        if flightsClimbed == 0 { flightsClimbed = 12 }
        if standHours == 0 { standHours = 10 }
        if exerciseMinutes == 0 { exerciseMinutes = 32 }
        if restingHeartRate == 0 { restingHeartRate = 58 }
        if walkingHeartRate == 0 { walkingHeartRate = 98 }
        if heartRateVariability == 0 { heartRateVariability = 45 }
        if bloodOxygen == 0 { bloodOxygen = 98 }
        if respiratoryRate == 0 { respiratoryRate = 14 }
        if sleepHours == 0 {
            sleepHours = 7.2
            deepSleepHours = 1.8
            remSleepHours = 1.5
            coreSleepHours = 3.9
            awakeTimeHours = 0.3
            timeInBed = 7.8
        }
        if weight == 0 { weight = 75.5 }
        if height == 0 { height = 1.78 }

        // Activity summary
        if activitySummary == nil {
            activitySummary = ActivitySummaryData(
                activeCalories: activeCalories,
                moveGoal: 500,
                exerciseMinutes: Double(exerciseMinutes),
                exerciseGoal: 30,
                standHours: Double(standHours),
                standGoal: 12
            )
        }

        // Step history
        if stepHistory.isEmpty {
            let calendar = Calendar.current
            stepHistory = (0..<7).map { daysAgo in
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
                return DailySteps(date: date, steps: Int.random(in: 5000...14000))
            }.reversed()
        }
    }

    // MARK: Private Methods

    private func showDemoMode() {
        isDemoMode = true
        isAuthorized = true

        // Activity demo data
        stepCount = 8_547
        stepsTrend = 12.5
        distance = 6_230
        activeCalories = 423
        flightsClimbed = 12
        standHours = 10
        exerciseMinutes = 32

        // Heart demo data
        heartRate = 72
        restingHeartRate = 58
        walkingHeartRate = 98
        heartRateVariability = 45
        bloodOxygen = 98
        respiratoryRate = 14

        // Sleep demo data
        sleepHours = 7.2
        deepSleepHours = 1.8
        remSleepHours = 1.5
        coreSleepHours = 3.9
        awakeTimeHours = 0.3
        timeInBed = 7.8
        bedtime = Calendar.current.date(bySettingHour: 23, minute: 15, second: 0, of: Date())
        wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())

        // Body demo data
        weight = 75.5
        weightTrend = -2.3
        height = 1.78
        bodyFatPercentage = 18.5
        leanBodyMass = 61.5
        waistCircumference = 0.82

        // Workout demo data
        workoutsThisWeek = 4
        totalWorkoutDuration = 3600 * 2.5
        workoutCalories = 1_250
        vo2Max = 42.5
        recentWorkouts = [
            WorkoutData(type: "Running", date: Date().addingTimeInterval(-86400), duration: 1800, calories: 320, icon: "figure.run", color: .green),
            WorkoutData(type: "Cycling", date: Date().addingTimeInterval(-172800), duration: 2700, calories: 450, icon: "figure.outdoor.cycle", color: .orange),
            WorkoutData(type: "Strength", date: Date().addingTimeInterval(-259200), duration: 3600, calories: 280, icon: "figure.strengthtraining.traditional", color: .purple),
            WorkoutData(type: "Swimming", date: Date().addingTimeInterval(-345600), duration: 2400, calories: 380, icon: "figure.pool.swim", color: .cyan)
        ]

        // Nutrition demo data
        dietaryEnergy = 1_850
        waterIntake = 2.1
        caffeineIntake = 95
        proteinIntake = 85
        carbsIntake = 220
        fatIntake = 65
        mindfulMinutes = 15

        // Step history demo data
        let calendar = Calendar.current
        stepHistory = (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let steps = Int.random(in: 5000...14000)
            return DailySteps(date: date, steps: steps)
        }.reversed()

        // Heart rate history demo data
        heartRateHistory = (0..<24).map { hoursAgo in
            let date = calendar.date(byAdding: .hour, value: -hoursAgo, to: Date())!
            let rate = Double.random(in: 55...90)
            return HeartRateSample(date: date, rate: rate)
        }.reversed()

        // Activity summary demo data
        activitySummary = ActivitySummaryData(
            activeCalories: 423,
            moveGoal: 500,
            exerciseMinutes: 32,
            exerciseGoal: 30,
            standHours: 10,
            standGoal: 12
        )
    }

    private func fetchAllHealthDataSafely() async {
        guard let healthStore = healthStore else { return }

        // Use a simpler approach - fetch one at a time with delays to prevent overwhelming the system
        await fetchStepCountSafe(healthStore)
        await fetchDistanceSafe(healthStore)
        await fetchActiveCaloriesSafe(healthStore)
        await fetchHeartRateSafe(healthStore)
        await fetchSleepDataSafe(healthStore)
        await fetchStepHistorySafe(healthStore)
        await fetchActivitySummarySafe(healthStore)
    }

    private func fetchStepCountSafe(_ healthStore: HKHealthStore) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                Task { @MainActor in
                    self?.stepCount = value
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchDistanceSafe(_ healthStore: HKHealthStore) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                Task { @MainActor in
                    self?.distance = value
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchActiveCaloriesSafe(_ healthStore: HKHealthStore) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                Task { @MainActor in
                    self?.activeCalories = value
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchHeartRateSafe(_ healthStore: HKHealthStore) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                Task { @MainActor in
                    self?.heartRate = value
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchSleepDataSafe(_ healthStore: HKHealthStore) async {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
                var totalSleep: TimeInterval = 0

                if let categorySamples = samples as? [HKCategorySample] {
                    for sample in categorySamples {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate)
                        if sample.value != HKCategoryValueSleepAnalysis.awake.rawValue &&
                           sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue {
                            totalSleep += duration
                        }
                    }
                }

                Task { @MainActor in
                    self?.sleepHours = totalSleep / 3600
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchStepHistorySafe(_ healthStore: HKHealthStore) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else { return }

        var interval = DateComponents()
        interval.day = 1

        await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: interval
            )

            query.initialResultsHandler = { [weak self] _, results, _ in
                var history: [DailySteps] = []
                results?.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    history.append(DailySteps(date: statistics.startDate, steps: Int(steps)))
                }

                Task { @MainActor in
                    self?.stepHistory = history
                    continuation.resume()
                }
            }

            healthStore.execute(query)
        }
    }

    private func fetchActivitySummarySafe(_ healthStore: HKHealthStore) async {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)

        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: components, end: components)

        await withCheckedContinuation { continuation in
            let query = HKActivitySummaryQuery(predicate: predicate) { [weak self] _, summaries, _ in
                Task { @MainActor in
                    if let summary = summaries?.first {
                        self?.activitySummary = ActivitySummaryData(
                            activeCalories: summary.activeEnergyBurned.doubleValue(for: .kilocalorie()),
                            moveGoal: summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()),
                            exerciseMinutes: summary.appleExerciseTime.doubleValue(for: .minute()),
                            exerciseGoal: summary.appleExerciseTimeGoal.doubleValue(for: .minute()),
                            standHours: summary.appleStandHours.doubleValue(for: .count()),
                            standGoal: summary.appleStandHoursGoal.doubleValue(for: .count())
                        )
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: Activity Fetchers

    private func fetchStepCount() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                        continuation.resume(returning: value)
                    }
                }
                healthStore.execute(query)
            }
            stepCount = result
        } catch {
            print("Step count fetch error: \(error)")
        }
    }

    private func fetchDistance() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        let value = result?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                        continuation.resume(returning: value)
                    }
                }
                healthStore.execute(query)
            }
            distance = result
        } catch {
            print("Distance fetch error: \(error)")
        }
    }

    private func fetchActiveCalories() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                        continuation.resume(returning: value)
                    }
                }
                healthStore.execute(query)
            }
            activeCalories = result
        } catch {
            print("Active calories fetch error: \(error)")
        }
    }

    private func fetchFlightsClimbed() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                        continuation.resume(returning: value)
                    }
                }
                healthStore.execute(query)
            }
            flightsClimbed = Int(result)
        } catch {
            print("Flights climbed fetch error: \(error)")
        }
    }

    private func fetchStandTime() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .appleStandTime) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        let value = result?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                        continuation.resume(returning: value)
                    }
                }
                healthStore.execute(query)
            }
            standHours = Int(result / 60)
        } catch {
            print("Stand time fetch error: \(error)")
        }
    }

    private func fetchExerciseTime() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        let value = result?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                        continuation.resume(returning: value)
                    }
                }
                healthStore.execute(query)
            }
            exerciseMinutes = Int(result)
        } catch {
            print("Exercise time fetch error: \(error)")
        }
    }

    // MARK: Heart Fetchers

    private func fetchHeartRate() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            heartRate = result
        } catch {
            print("Heart rate fetch error: \(error)")
        }
    }

    private func fetchRestingHeartRate() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            restingHeartRate = result
        } catch {
            print("Resting heart rate fetch error: \(error)")
        }
    }

    private func fetchWalkingHeartRate() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            walkingHeartRate = result
        } catch {
            print("Walking heart rate fetch error: \(error)")
        }
    }

    private func fetchHeartRateVariability() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            heartRateVariability = result
        } catch {
            print("HRV fetch error: \(error)")
        }
    }

    private func fetchBloodOxygen() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: .percent()) * 100
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            bloodOxygen = result
        } catch {
            print("Blood oxygen fetch error: \(error)")
        }
    }

    private func fetchRespiratoryRate() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            respiratoryRate = result
        } catch {
            print("Respiratory rate fetch error: \(error)")
        }
    }

    // MARK: Sleep Fetcher

    private func fetchSleepData() async {
        guard let healthStore = healthStore,
              let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                    }
                }
                healthStore.execute(query)
            }

            var totalSleep: TimeInterval = 0
            var deepSleep: TimeInterval = 0
            var remSleep: TimeInterval = 0
            var coreSleep: TimeInterval = 0
            var awakeTime: TimeInterval = 0
            var inBedTime: TimeInterval = 0
            var earliestBedtime: Date?
            var latestWakeTime: Date?

            for sample in samples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)

                if earliestBedtime == nil || sample.startDate < earliestBedtime! {
                    earliestBedtime = sample.startDate
                }
                if latestWakeTime == nil || sample.endDate > latestWakeTime! {
                    latestWakeTime = sample.endDate
                }

                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deepSleep += duration
                    totalSleep += duration
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    remSleep += duration
                    totalSleep += duration
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    coreSleep += duration
                    totalSleep += duration
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    totalSleep += duration
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    awakeTime += duration
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    inBedTime += duration
                default:
                    break
                }
            }

            sleepHours = totalSleep / 3600
            deepSleepHours = deepSleep / 3600
            remSleepHours = remSleep / 3600
            coreSleepHours = coreSleep / 3600
            awakeTimeHours = awakeTime / 3600
            timeInBed = max(inBedTime, totalSleep + awakeTime) / 3600
            bedtime = earliestBedtime
            wakeTime = latestWakeTime
        } catch {
            print("Sleep data fetch error: \(error)")
        }
    }

    // MARK: Body Fetchers

    private func fetchWeight() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            weight = result
        } catch {
            print("Weight fetch error: \(error)")
        }
    }

    private func fetchHeight() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .height) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: .meter())
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            height = result
        } catch {
            print("Height fetch error: \(error)")
        }
    }

    private func fetchBodyFat() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: .percent()) * 100
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            bodyFatPercentage = result
        } catch {
            print("Body fat fetch error: \(error)")
        }
    }

    private func fetchLeanBodyMass() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            leanBodyMass = result
        } catch {
            print("Lean body mass fetch error: \(error)")
        }
    }

    // MARK: Workout Fetchers

    private func fetchWorkouts() async {
        guard let healthStore = healthStore else { return }

        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
                let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples as? [HKWorkout] ?? [])
                    }
                }
                healthStore.execute(query)
            }

            workoutsThisWeek = workouts.count
            totalWorkoutDuration = workouts.reduce(0) { $0 + $1.duration }
            workoutCalories = workouts.reduce(0) { $0 + ($1.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) }

            recentWorkouts = workouts.prefix(10).map { workout in
                WorkoutData(
                    type: workoutTypeName(workout.workoutActivityType),
                    date: workout.endDate,
                    duration: workout.duration,
                    calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                    icon: workoutIcon(workout.workoutActivityType),
                    color: workoutColor(workout.workoutActivityType)
                )
            }
        } catch {
            print("Workouts fetch error: \(error)")
        }
    }

    private func fetchVO2Max() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let sample = samples?.first as? HKQuantitySample {
                        let value = sample.quantity.doubleValue(for: HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute()))
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(returning: 0)
                    }
                }
                healthStore.execute(query)
            }
            vo2Max = result
        } catch {
            print("VO2 Max fetch error: \(error)")
        }
    }

    // MARK: Nutrition Fetchers

    private func fetchNutritionData() async {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        // Dietary Energy
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            dietaryEnergy = await fetchNutrientSum(type: type, predicate: predicate, unit: .kilocalorie())
        }

        // Water
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            waterIntake = await fetchNutrientSum(type: type, predicate: predicate, unit: .liter())
        }

        // Caffeine
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) {
            caffeineIntake = await fetchNutrientSum(type: type, predicate: predicate, unit: .gramUnit(with: .milli))
        }

        // Protein
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            proteinIntake = await fetchNutrientSum(type: type, predicate: predicate, unit: .gram())
        }

        // Carbs
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            carbsIntake = await fetchNutrientSum(type: type, predicate: predicate, unit: .gram())
        }

        // Fat
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            fatIntake = await fetchNutrientSum(type: type, predicate: predicate, unit: .gram())
        }
    }

    private func fetchNutrientSum(type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async -> Double {
        guard let healthStore = healthStore else { return 0 }

        do {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                        continuation.resume(returning: value)
                    }
                }
                healthStore.execute(query)
            }
        } catch {
            print("Nutrient fetch error: \(error)")
            return 0
        }
    }

    private func fetchMindfulMinutes() async {
        guard let healthStore = healthStore,
              let type = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                    }
                }
                healthStore.execute(query)
            }

            let totalMinutes = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } / 60
            mindfulMinutes = Int(totalMinutes)
        } catch {
            print("Mindful minutes fetch error: \(error)")
        }
    }

    // MARK: History Fetchers

    private func fetchStepHistory() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else { return }

        var interval = DateComponents()
        interval.day = 1

        do {
            let history = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[DailySteps], Error>) in
                let query = HKStatisticsCollectionQuery(
                    quantityType: type,
                    quantitySamplePredicate: nil,
                    options: .cumulativeSum,
                    anchorDate: calendar.startOfDay(for: startDate),
                    intervalComponents: interval
                )

                query.initialResultsHandler = { _, results, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let results = results else {
                        continuation.resume(returning: [])
                        return
                    }

                    var history: [DailySteps] = []
                    results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                        let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                        history.append(DailySteps(date: statistics.startDate, steps: Int(steps)))
                    }
                    continuation.resume(returning: history)
                }

                healthStore.execute(query)
            }

            stepHistory = history

            // Calculate trend
            if history.count >= 2 {
                let recentAvg = history.suffix(3).map(\.steps).reduce(0, +) / max(1, history.suffix(3).count)
                let previousAvg = history.prefix(3).map(\.steps).reduce(0, +) / max(1, history.prefix(3).count)
                if previousAvg > 0 {
                    stepsTrend = Double(recentAvg - previousAvg) / Double(previousAvg) * 100
                }
            }
        } catch {
            print("Step history fetch error: \(error)")
        }
    }

    private func fetchHeartRateHistory() async {
        guard let healthStore = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                    }
                }
                healthStore.execute(query)
            }

            heartRateHistory = samples.map { sample in
                HeartRateSample(
                    date: sample.endDate,
                    rate: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                )
            }
        } catch {
            print("Heart rate history fetch error: \(error)")
        }
    }

    private func fetchActivitySummary() async {
        guard let healthStore = healthStore else { return }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)

        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: components, end: components)

        do {
            let summary = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKActivitySummary?, Error>) in
                let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: summaries?.first)
                    }
                }
                healthStore.execute(query)
            }

            if let summary = summary {
                activitySummary = ActivitySummaryData(
                    activeCalories: summary.activeEnergyBurned.doubleValue(for: .kilocalorie()),
                    moveGoal: summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()),
                    exerciseMinutes: summary.appleExerciseTime.doubleValue(for: .minute()),
                    exerciseGoal: summary.appleExerciseTimeGoal.doubleValue(for: .minute()),
                    standHours: summary.appleStandHours.doubleValue(for: .count()),
                    standGoal: summary.appleStandHoursGoal.doubleValue(for: .count())
                )
            }
        } catch {
            print("Activity summary fetch error: \(error)")
        }
    }

    // MARK: Helper Functions

    private func workoutTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .hiking: return "Hiking"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .dance: return "Dance"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stairs"
        case .pilates: return "Pilates"
        case .crossTraining: return "Cross Training"
        default: return "Workout"
        }
    }

    private func workoutIcon(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .walking: return "figure.walk"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.yoga"
        case .hiking: return "figure.hiking"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .highIntensityIntervalTraining: return "figure.highintensity.intervaltraining"
        case .dance: return "figure.dance"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rowing"
        case .stairClimbing: return "figure.stairs"
        case .pilates: return "figure.pilates"
        default: return "figure.mixed.cardio"
        }
    }

    private func workoutColor(_ type: HKWorkoutActivityType) -> Color {
        switch type {
        case .running: return .green
        case .cycling: return .orange
        case .walking: return .blue
        case .swimming: return .cyan
        case .yoga: return .purple
        case .hiking: return .brown
        case .functionalStrengthTraining, .traditionalStrengthTraining: return .red
        case .highIntensityIntervalTraining: return .pink
        default: return .green
        }
    }
}

#Preview {
    NavigationStack {
        HealthKitView()
    }
}
