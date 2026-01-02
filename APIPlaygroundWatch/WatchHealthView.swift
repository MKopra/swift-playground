import SwiftUI
import HealthKit

struct WatchHealthView: View {
    @State private var heartRate: Double?
    @State private var steps: Int?
    @State private var activeCalories: Double?
    @State private var exerciseMinutes: Double?
    @State private var standHours: Int?
    @State private var isAuthorized = false
    @State private var errorMessage: String?

    private let healthStore = HKHealthStore()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !isAuthorized {
                    authorizationSection
                } else {
                    metricsSection
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Health")
        .onAppear {
            checkAuthorization()
        }
    }

    // MARK: - Authorization Section

    private var authorizationSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.largeTitle)
                .foregroundStyle(.pink)

            Text("Health Access")
                .font(.headline)

            Text("Grant access to view your health metrics")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Authorize") {
                requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding()
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(spacing: 8) {
            // Heart Rate
            metricCard(
                icon: "heart.fill",
                color: .pink,
                title: "Heart Rate",
                value: heartRate.map { "\(Int($0))" } ?? "--",
                unit: "BPM"
            )

            // Steps
            metricCard(
                icon: "figure.walk",
                color: .green,
                title: "Steps",
                value: steps.map { "\($0)" } ?? "--",
                unit: "today"
            )

            // Active Calories
            metricCard(
                icon: "flame.fill",
                color: .orange,
                title: "Active Cal",
                value: activeCalories.map { "\(Int($0))" } ?? "--",
                unit: "kcal"
            )

            // Exercise Minutes
            metricCard(
                icon: "figure.run",
                color: .yellow,
                title: "Exercise",
                value: exerciseMinutes.map { "\(Int($0))" } ?? "--",
                unit: "min"
            )

            // Stand Hours
            metricCard(
                icon: "figure.stand",
                color: .cyan,
                title: "Stand",
                value: standHours.map { "\($0)" } ?? "--",
                unit: "hours"
            )

            Button {
                fetchAllMetrics()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
    }

    private func metricCard(icon: String, color: Color, title: String, value: String, unit: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.headline)
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(8)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - HealthKit Functions

    private func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit not available"
            return
        }

        let heartRateType = HKQuantityType(.heartRate)
        let status = healthStore.authorizationStatus(for: heartRateType)

        if status == .sharingAuthorized {
            isAuthorized = true
            fetchAllMetrics()
        }
    }

    private func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.appleStandTime)
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    isAuthorized = true
                    fetchAllMetrics()
                } else if let error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func fetchAllMetrics() {
        fetchHeartRate()
        fetchSteps()
        fetchActiveCalories()
        fetchExerciseMinutes()
        fetchStandHours()
    }

    private func fetchHeartRate() {
        let heartRateType = HKQuantityType(.heartRate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async {
                heartRate = value
            }
        }
        healthStore.execute(query)
    }

    private func fetchSteps() {
        let stepsType = HKQuantityType(.stepCount)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        let query = HKStatisticsQuery(
            quantityType: stepsType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            DispatchQueue.main.async {
                steps = Int(sum.doubleValue(for: .count()))
            }
        }
        healthStore.execute(query)
    }

    private func fetchActiveCalories() {
        let caloriesType = HKQuantityType(.activeEnergyBurned)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        let query = HKStatisticsQuery(
            quantityType: caloriesType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            DispatchQueue.main.async {
                activeCalories = sum.doubleValue(for: .kilocalorie())
            }
        }
        healthStore.execute(query)
    }

    private func fetchExerciseMinutes() {
        let exerciseType = HKQuantityType(.appleExerciseTime)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            DispatchQueue.main.async {
                exerciseMinutes = sum.doubleValue(for: .minute())
            }
        }
        healthStore.execute(query)
    }

    private func fetchStandHours() {
        let standType = HKQuantityType(.appleStandTime)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        let query = HKStatisticsQuery(
            quantityType: standType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            DispatchQueue.main.async {
                standHours = Int(sum.doubleValue(for: .minute()) / 60)
            }
        }
        healthStore.execute(query)
    }
}

#Preview {
    NavigationStack {
        WatchHealthView()
    }
}
