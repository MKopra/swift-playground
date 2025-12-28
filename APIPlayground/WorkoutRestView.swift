import SwiftUI
import ActivityKit

/// Gym Rest Timer - Track rest between sets with rep/weight logging
/// Perfect Live Activity use case: hands are busy, glanceable timer needed
struct WorkoutRestView: View {
    @StateObject private var manager = WorkoutActivityManager()
    @State private var workoutName: String = "Push Day"
    @State private var exerciseName: String = "Bench Press"
    @State private var weight: Int = 135
    @State private var reps: Int = 10
    @State private var sets: Int = 4
    @State private var restSeconds: Int = 90
    @State private var useRestTimer: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusCard
                if manager.isActive {
                    timerCard
                }
                exerciseCard
                configurationCard
                controlsCard
                infoCard
            }
            .padding()
        }
        .navigationTitle("Gym Rest Timer")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: manager.isActive ? "dumbbell.fill" : "dumbbell")
                        .foregroundStyle(manager.isActive ? .purple : .secondary)
                        .font(.title2)
                    Text(manager.isActive ? manager.workoutName : "Ready to Workout")
                        .font(.headline)
                    Spacer()
                    if manager.isActive {
                        Text("Set \(manager.currentSet)/\(manager.totalSets)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                }

                if manager.isActive {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.exerciseName)
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("\(manager.weight) lbs × \(manager.reps) reps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if manager.isResting {
                            Text("\(manager.secondsRemaining)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(restColor)
                        } else {
                            Text("GO!")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.green)
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
            Label("Status", systemImage: "figure.strengthtraining.traditional")
        }
    }

    // MARK: - Timer Card
    private var timerCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Rest timer visualization
                ZStack {
                    Circle()
                        .stroke(lineWidth: 12)
                        .opacity(0.2)
                        .foregroundStyle(restColor)

                    Circle()
                        .trim(from: 0, to: manager.progress)
                        .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .foregroundStyle(restColor)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: manager.progress)

                    VStack {
                        if manager.isResting {
                            Text("\(manager.secondsRemaining)s")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("REST")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 32))
                            Text("LIFT!")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundStyle(restColor)
                }
                .frame(width: 140, height: 140)

                // Set progress
                HStack(spacing: 8) {
                    ForEach(1...manager.totalSets, id: \.self) { set in
                        ZStack {
                            Circle()
                                .fill(set < manager.currentSet ? .green :
                                        set == manager.currentSet ? .purple : .gray.opacity(0.3))
                                .frame(width: 32, height: 32)

                            if set < manager.currentSet {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(set)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(set == manager.currentSet ? .white : .secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } label: {
            Label("Timer", systemImage: "timer")
        }
    }

    // MARK: - Exercise Card
    private var exerciseCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                TextField("Exercise Name", text: $exerciseName)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isActive)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Weight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button {
                                weight = max(5, weight - 5)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(manager.isActive)

                            Text("\(weight)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(width: 60)

                            Button {
                                weight += 5
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(manager.isActive)

                            Text("lbs")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button {
                                reps = max(1, reps - 1)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(manager.isActive)

                            Text("\(reps)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(width: 40)

                            Button {
                                reps += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(manager.isActive)
                        }
                    }
                }
            }
        } label: {
            Label("Current Exercise", systemImage: "figure.walk")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                TextField("Workout Name", text: $workoutName)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isActive)

                HStack {
                    Text("Total Sets")
                    Spacer()
                    Stepper("\(sets)", value: $sets, in: 1...10)
                        .disabled(manager.isActive)
                }

                Toggle("Use Rest Timer", isOn: $useRestTimer)
                    .disabled(manager.isActive)

                if useRestTimer {
                    HStack {
                        Text("Rest Time")
                        Spacer()
                        Picker("Rest", selection: $restSeconds) {
                            Text("30s").tag(30)
                            Text("60s").tag(60)
                            Text("90s").tag(90)
                            Text("120s").tag(120)
                            Text("180s").tag(180)
                        }
                        .pickerStyle(.menu)
                        .disabled(manager.isActive)
                    }
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
                        manager.startWorkout(
                            workoutName: workoutName,
                            exerciseName: exerciseName,
                            weight: weight,
                            reps: reps,
                            totalSets: sets,
                            restSeconds: restSeconds,
                            useRestTimer: useRestTimer
                        )
                    } label: {
                        Label("Start Workout", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    if manager.isResting && manager.useRestTimer {
                        HStack(spacing: 12) {
                            Button {
                                manager.skipRest()
                            } label: {
                                Label("Skip Rest", systemImage: "forward.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.orange, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                            }

                            Button {
                                manager.addRest(seconds: 30)
                            } label: {
                                Label("+30s", systemImage: "plus")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                            }
                        }
                    } else {
                        Button {
                            manager.logSet()
                        } label: {
                            Label("Log Set \(manager.currentSet)", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                    }

                    Button {
                        manager.endWorkout()
                    } label: {
                        Label("End Workout", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
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
                WorkoutInfoRow(title: "Ideal Rest (Strength)", value: "2-3 min")
                WorkoutInfoRow(title: "Ideal Rest (Hypertrophy)", value: "60-90s")
                WorkoutInfoRow(title: "Ideal Rest (Endurance)", value: "30-60s")

                Divider()

                Text("Rest intervals are crucial for muscle recovery between sets. The Live Activity keeps your timer visible without picking up your phone, so you can focus on your workout.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("About", systemImage: "info.circle")
        }
    }

    private var restColor: Color {
        if !manager.isResting { return .green }
        let ratio = Double(manager.secondsRemaining) / Double(manager.totalSeconds)
        if ratio > 0.5 { return .green }
        if ratio > 0.2 { return .orange }
        return .red
    }
}

struct WorkoutInfoRow: View {
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

// MARK: - Workout Activity Manager

@MainActor
class WorkoutActivityManager: ObservableObject {
    @Published var isActive = false
    @Published var isResting = false
    @Published var secondsRemaining: Int = 90
    @Published var totalSeconds: Int = 90
    @Published var currentSet: Int = 1
    @Published var totalSets: Int = 4
    @Published var workoutName: String = ""
    @Published var exerciseName: String = ""
    @Published var weight: Int = 0
    @Published var reps: Int = 0
    @Published var progress: Double = 1.0
    @Published var statusMessage = "Ready to start workout"
    @Published var useRestTimer: Bool = true
    @Published var restEndTime: Date? = nil

    private var currentActivity: Activity<WorkoutActivityAttributes>?
    private var timer: Timer?
    private var restDuration: Int = 90

    init() {
        checkExistingActivities()
    }

    private func checkExistingActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                currentActivity = activity
                isActive = true
                workoutName = activity.attributes.workoutName
                useRestTimer = activity.attributes.useRestTimer
                updateFromState(activity.content.state)
                statusMessage = "Resumed workout"
                if isResting && useRestTimer {
                    startTimer()
                }
                break
            }
        }
    }

    private func updateFromState(_ state: WorkoutActivityAttributes.ContentState) {
        secondsRemaining = state.secondsRemaining
        totalSeconds = state.totalSeconds
        currentSet = state.currentSet
        totalSets = state.totalSets
        exerciseName = state.exerciseName
        weight = state.weight
        reps = state.reps
        isResting = state.isResting
        restEndTime = state.restEndTime
        progress = totalSeconds > 0 ? Double(secondsRemaining) / Double(totalSeconds) : 0
    }

    func startWorkout(workoutName: String, exerciseName: String, weight: Int, reps: Int, totalSets: Int, restSeconds: Int, useRestTimer: Bool) {
        guard #available(iOS 16.1, *) else {
            statusMessage = "Requires iOS 16.1+"
            return
        }

        self.workoutName = workoutName
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.totalSets = totalSets
        self.restDuration = restSeconds
        self.currentSet = 1
        self.isResting = false
        self.totalSeconds = restSeconds
        self.secondsRemaining = 0
        self.useRestTimer = useRestTimer

        let attributes = WorkoutActivityAttributes(workoutName: workoutName, useRestTimer: useRestTimer)
        let initialState = WorkoutActivityAttributes.ContentState(
            secondsRemaining: 0,
            totalSeconds: restSeconds,
            currentSet: 1,
            totalSets: totalSets,
            exerciseName: exerciseName,
            weight: weight,
            reps: reps,
            isResting: false,
            restEndTime: nil
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isActive = true
            statusMessage = "Do set 1 of \(totalSets)!"
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    /// Log a set without starting rest timer (used when rest timer is disabled or when completing a set)
    func logSet() {
        if useRestTimer {
            // Start rest timer
            isResting = true
            secondsRemaining = restDuration
            totalSeconds = restDuration
            restEndTime = Date().addingTimeInterval(TimeInterval(restDuration))
            progress = 1.0
            statusMessage = "Rest time - \(restDuration)s"
            startTimer()
        } else {
            // Just log the set and move to next
            currentSet += 1
            restEndTime = nil
            if currentSet > totalSets {
                endWorkout()
                return
            }
            statusMessage = "Set logged! Do set \(currentSet) of \(totalSets)"
        }
        updateActivity()
    }

    func skipRest() {
        timer?.invalidate()
        finishRest()
    }

    func addRest(seconds: Int) {
        secondsRemaining += seconds
        totalSeconds += seconds
        if let currentEndTime = restEndTime {
            restEndTime = currentEndTime.addingTimeInterval(TimeInterval(seconds))
        }
        progress = Double(secondsRemaining) / Double(totalSeconds)
        statusMessage = "Added \(seconds)s rest"
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
        guard isResting else { return }

        secondsRemaining -= 1
        progress = Double(secondsRemaining) / Double(totalSeconds)

        if secondsRemaining <= 0 {
            finishRest()
        }

        updateActivity()
    }

    private func finishRest() {
        timer?.invalidate()
        isResting = false
        restEndTime = nil
        currentSet += 1

        if currentSet > totalSets {
            endWorkout()
            return
        }

        secondsRemaining = 0
        statusMessage = "Do set \(currentSet) of \(totalSets)!"
        updateActivity()
    }

    private func updateActivity() {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let updatedState = WorkoutActivityAttributes.ContentState(
            secondsRemaining: secondsRemaining,
            totalSeconds: totalSeconds,
            currentSet: currentSet,
            totalSets: totalSets,
            exerciseName: exerciseName,
            weight: weight,
            reps: reps,
            isResting: isResting,
            restEndTime: restEndTime
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }

    func endWorkout() {
        timer?.invalidate()
        timer = nil
        restEndTime = nil

        guard #available(iOS 16.1, *),
              let activity = currentActivity else {
            isActive = false
            return
        }

        let finalState = WorkoutActivityAttributes.ContentState(
            secondsRemaining: 0,
            totalSeconds: totalSeconds,
            currentSet: currentSet,
            totalSets: totalSets,
            exerciseName: exerciseName,
            weight: weight,
            reps: reps,
            isResting: false,
            restEndTime: nil
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                isActive = false
                currentActivity = nil
                statusMessage = "Workout complete! \(currentSet - 1) sets done"
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutRestView()
    }
}
