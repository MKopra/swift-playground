import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Workout Live Activity Intent

/// Intent to log a completed set from the Live Activity
@available(iOS 16.2, *)
struct LogWorkoutSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Log Set"
    static var description = IntentDescription("Mark the current set as complete")

    func perform() async throws -> some IntentResult {
        // Find the active workout activity and update it
        if #available(iOS 16.1, *) {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                let currentState = activity.content.state
                let useRestTimer = activity.attributes.useRestTimer

                // Calculate new state
                let newSet = currentState.currentSet + (useRestTimer ? 0 : 1)
                let isResting = useRestTimer

                // Check if workout should end
                if newSet > currentState.totalSets && !useRestTimer {
                    // End the workout
                    let finalState = WorkoutActivityAttributes.ContentState(
                        secondsRemaining: 0,
                        totalSeconds: currentState.totalSeconds,
                        currentSet: currentState.totalSets,
                        totalSets: currentState.totalSets,
                        exerciseName: currentState.exerciseName,
                        weight: currentState.weight,
                        reps: currentState.reps,
                        isResting: false,
                        restEndTime: nil
                    )
                    await activity.end(
                        ActivityContent(state: finalState, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                } else {
                    // Calculate rest end time for auto-updating timer
                    let restEndTime: Date? = useRestTimer ? Date().addingTimeInterval(TimeInterval(currentState.totalSeconds)) : nil

                    // Update to resting or next set
                    let updatedState = WorkoutActivityAttributes.ContentState(
                        secondsRemaining: useRestTimer ? currentState.totalSeconds : 0,
                        totalSeconds: currentState.totalSeconds,
                        currentSet: useRestTimer ? currentState.currentSet : newSet,
                        totalSets: currentState.totalSets,
                        exerciseName: currentState.exerciseName,
                        weight: currentState.weight,
                        reps: currentState.reps,
                        isResting: isResting,
                        restEndTime: restEndTime
                    )
                    await activity.update(ActivityContent(state: updatedState, staleDate: nil))
                }
                break
            }
        }
        return .result()
    }
}

// MARK: - Pomodoro Live Activity

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // Lock Screen
            HStack(spacing: 16) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(lineWidth: 6)
                        .opacity(0.3)
                    Circle()
                        .trim(from: 0, to: progress(context.state))
                        .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: context.state.isWorkPhase ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.title2)
                }
                .frame(width: 60, height: 60)
                .foregroundStyle(context.state.isWorkPhase ? .red : .green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.isWorkPhase ? "Focus Time" : "Break Time")
                        .font(.headline)
                    Text(context.attributes.taskName)
                        .font(.subheadline)
                        .opacity(0.8)
                    Text("Session \(context.state.currentSession)/\(context.state.totalSessions)")
                        .font(.caption)
                        .opacity(0.6)
                }

                Spacer()

                Text(formatTime(context.state.secondsRemaining))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .padding()
            .foregroundStyle(.white)
            .activityBackgroundTint(context.state.isWorkPhase ? .red.opacity(0.9) : .green.opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isWorkPhase ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.title)
                        .foregroundStyle(context.state.isWorkPhase ? .red : .green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.currentSession)/\(context.state.totalSessions)")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.isWorkPhase ? "Focus" : "Break")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatTime(context.state.secondsRemaining))
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isWorkPhase ? "brain.head.profile" : "cup.and.saucer.fill")
                    .foregroundStyle(context.state.isWorkPhase ? .red : .green)
            } compactTrailing: {
                Text(formatTime(context.state.secondsRemaining))
                    .font(.caption)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(context.state.isWorkPhase ? .red : .green)
            }
        }
    }

    private func progress(_ state: PomodoroActivityAttributes.ContentState) -> Double {
        guard state.totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(state.secondsRemaining) / Double(state.totalSeconds))
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Parking Meter Live Activity

struct ParkingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingActivityAttributes.self) { context in
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(urgencyColor(context.state).opacity(0.2))
                    Image(systemName: "car.fill")
                        .font(.title)
                        .foregroundStyle(urgencyColor(context.state))
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.location)
                        .font(.headline)
                    Text(context.state.spotInfo)
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    if context.state.isExpired {
                        Text("EXPIRED")
                            .font(.headline)
                            .foregroundStyle(.red)
                    } else {
                        Text("\(context.state.minutesRemaining)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("min left")
                            .font(.caption)
                            .opacity(0.8)
                    }
                }
            }
            .padding()
            .foregroundStyle(.white)
            .activityBackgroundTint(urgencyColor(context.state).opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "car.fill")
                        .foregroundStyle(urgencyColor(context.state))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.licensePlate)
                        .font(.caption)
                        .monospaced()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.location)
                        Spacer()
                        if context.state.isExpired {
                            Text("EXPIRED")
                                .foregroundStyle(.red)
                                .fontWeight(.bold)
                        } else {
                            Text("\(context.state.minutesRemaining) min")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .foregroundStyle(urgencyColor(context.state))
            } compactTrailing: {
                Text("\(context.state.minutesRemaining)m")
                    .font(.caption)
                    .foregroundStyle(urgencyColor(context.state))
            } minimal: {
                Image(systemName: "parkingsign.circle.fill")
                    .foregroundStyle(urgencyColor(context.state))
            }
        }
    }

    private func urgencyColor(_ state: ParkingActivityAttributes.ContentState) -> Color {
        if state.isExpired { return .red }
        let percentage = Double(state.minutesRemaining) / Double(max(state.totalMinutes, 1))
        if percentage > 0.3 { return .green }
        if percentage > 0.1 { return .yellow }
        return .red
    }
}

// MARK: - Caffeine Tracker Live Activity

struct CaffeineLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CaffeineActivityAttributes.self) { context in
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 6)
                        .opacity(0.3)
                    Circle()
                        .trim(from: 0, to: context.state.currentMg / context.state.startMg)
                        .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title2)
                }
                .frame(width: 60, height: 60)
                .foregroundStyle(.brown)

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.drinkName)
                        .font(.headline)
                    Text("Started \(context.attributes.startTime, style: .relative) ago")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(Int(context.state.currentMg))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("mg caffeine")
                        .font(.caption)
                        .opacity(0.8)
                }
            }
            .padding()
            .foregroundStyle(.white)
            .activityBackgroundTint(.brown.opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundStyle(.brown)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.currentMg))mg")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        ProgressView(value: context.state.currentMg, total: context.state.startMg)
                            .tint(.brown)
                        Text("Clear by \(context.state.estimatedClearTime, style: .time)")
                            .font(.caption)
                    }
                }
            } compactLeading: {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(.brown)
            } compactTrailing: {
                Text("\(Int(context.state.currentMg))")
                    .font(.caption)
            } minimal: {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(.brown)
            }
        }
    }
}

// MARK: - Workout Rest Timer Live Activity

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 6)
                        .opacity(0.3)
                    if context.state.isResting {
                        Circle()
                            .trim(from: 0, to: 1.0 - Double(context.state.secondsRemaining) / Double(max(context.state.totalSeconds, 1)))
                            .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    Image(systemName: context.state.isResting ? "pause.fill" : "dumbbell.fill")
                        .font(.title2)
                }
                .frame(width: 60, height: 60)
                .foregroundStyle(context.state.isResting ? .orange : .purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.isResting ? "REST" : "LIFT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(context.state.isResting ? .orange : .green)
                    Text(context.state.exerciseName)
                        .font(.headline)
                    Text("Set \(context.state.currentSet)/\(context.state.totalSets) • \(context.state.weight)lb × \(context.state.reps)")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                if context.state.isResting, let endTime = context.state.restEndTime {
                    Text(endTime, style: .timer)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 80)
                } else if !context.state.isResting {
                    Button(intent: LogWorkoutSetIntent()) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("LOG SET")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.green, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .foregroundStyle(.white)
            .activityBackgroundTint(context.state.isResting ? .orange.opacity(0.9) : .purple.opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isResting ? "pause.fill" : "dumbbell.fill")
                        .foregroundStyle(context.state.isResting ? .orange : .purple)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(context.state.exerciseName)
                                .fontWeight(.medium)
                            Text("\(context.state.weight)lb × \(context.state.reps)")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        Spacer()
                        if context.state.isResting, let endTime = context.state.restEndTime {
                            Text(endTime, style: .timer)
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(.orange)
                        } else if !context.state.isResting {
                            Button(intent: LogWorkoutSetIntent()) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("LOG SET")
                                        .fontWeight(.bold)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.green, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isResting ? "timer" : "dumbbell.fill")
                    .foregroundStyle(context.state.isResting ? .orange : .purple)
            } compactTrailing: {
                if context.state.isResting, let endTime = context.state.restEndTime {
                    Text(endTime, style: .timer)
                        .font(.caption)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                } else {
                    Text("Set \(context.state.currentSet)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            } minimal: {
                if context.state.isResting, let endTime = context.state.restEndTime {
                    Text(endTime, style: .timer)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                } else {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(.purple)
                }
            }
        }
    }
}

// MARK: - Auction Countdown Live Activity

struct AuctionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AuctionActivityAttributes.self) { context in
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(context.state.isWinning ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    Image(systemName: context.attributes.itemImage)
                        .font(.title)
                        .foregroundStyle(context.state.isWinning ? .green : .red)
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.itemName)
                        .font(.headline)
                        .lineLimit(1)
                    HStack {
                        Text("$\(context.state.currentBid, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("• \(context.state.numberOfBids) bids")
                            .font(.caption)
                            .opacity(0.8)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    if context.state.isEnded {
                        Text(context.state.isWinning ? "WON!" : "LOST")
                            .font(.headline)
                            .foregroundStyle(context.state.isWinning ? .green : .red)
                    } else {
                        Text(formatTime(context.state.secondsRemaining))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text(context.state.isWinning ? "Winning" : "Outbid")
                            .font(.caption)
                            .foregroundStyle(context.state.isWinning ? .green : .red)
                    }
                }
            }
            .padding()
            .foregroundStyle(.white)
            .activityBackgroundTint(context.state.isWinning ? .green.opacity(0.9) : .orange.opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.itemImage)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("$\(context.state.currentBid, specifier: "%.0f")")
                        .fontWeight(.bold)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.isWinning ? "Winning" : "Outbid!")
                            .foregroundStyle(context.state.isWinning ? .green : .red)
                        Spacer()
                        Text(formatTime(context.state.secondsRemaining))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            } compactLeading: {
                Image(systemName: "gavel.fill")
                    .foregroundStyle(context.state.isWinning ? .green : .red)
            } compactTrailing: {
                Text(formatTime(context.state.secondsRemaining))
                    .font(.caption)
            } minimal: {
                Image(systemName: "gavel.fill")
                    .foregroundStyle(context.state.isWinning ? .green : .red)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return "\(seconds / 3600)h \((seconds % 3600) / 60)m"
        } else if seconds >= 60 {
            return "\(seconds / 60)m \(seconds % 60)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Rocket Launch Live Activity

struct RocketLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RocketActivityAttributes.self) { context in
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(phaseColor(context.state.phase).opacity(0.2))
                    Image(systemName: "airplane.departure")
                        .font(.title)
                        .foregroundStyle(phaseColor(context.state.phase))
                        .rotationEffect(.degrees(-45))
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.missionName)
                        .font(.headline)
                    Text(context.attributes.rocketName)
                        .font(.caption)
                        .opacity(0.8)
                    Text(context.state.missionStatus)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(phaseColor(context.state.phase).opacity(0.3), in: Capsule())
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(context.state.phase.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                    if context.state.secondsToLaunch > 0 {
                        Text(formatCountdown(context.state.secondsToLaunch))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                    } else {
                        Text("+\(formatCountdown(-context.state.secondsToLaunch))")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                    }
                }
            }
            .padding()
            .foregroundStyle(.white)
            .activityBackgroundTint(phaseColor(context.state.phase).opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "airplane.departure")
                        .rotationEffect(.degrees(-45))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.phase.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.missionName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(formatCountdown(context.state.secondsToLaunch))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                }
            } compactLeading: {
                Image(systemName: "airplane.departure")
                    .foregroundStyle(phaseColor(context.state.phase))
            } compactTrailing: {
                Text(formatCountdown(context.state.secondsToLaunch))
                    .font(.caption)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "airplane.departure")
                    .foregroundStyle(phaseColor(context.state.phase))
            }
        }
    }

    private func phaseColor(_ phase: LaunchPhase) -> Color {
        switch phase {
        case .holding: return .yellow
        case .countdown: return .blue
        case .liftoff: return .orange
        case .maxQ: return .red
        case .meco: return .purple
        case .success: return .green
        }
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let absSeconds = abs(seconds)
        let mins = absSeconds / 60
        let secs = absSeconds % 60
        let prefix = seconds < 0 ? "+" : "T-"
        return String(format: "%@%02d:%02d", prefix, mins, secs)
    }
}

// MARK: - Sports Score Live Activity

struct SportsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SportsActivityAttributes.self) { context in
            HStack(spacing: 8) {
                // Home team
                VStack {
                    Text(context.attributes.homeTeam)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("\(context.state.homeScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    if context.state.possession == "home" {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .fill(.clear)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity)

                // Game info
                VStack(spacing: 4) {
                    Text(context.state.quarter)
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(context.state.timeRemaining)
                        .font(.headline)
                        .monospacedDigit()
                    Text(context.state.lastPlay)
                        .font(.caption2)
                        .lineLimit(1)
                        .opacity(0.8)
                }
                .frame(width: 80)

                // Away team
                VStack {
                    Text(context.attributes.awayTeam)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("\(context.state.awayScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    if context.state.possession == "away" {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .fill(.clear)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .foregroundStyle(.white)
            .activityBackgroundTint(.orange.opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        Text(context.attributes.homeTeam)
                            .font(.caption)
                        Text("\(context.state.homeScore)")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        Text(context.attributes.awayTeam)
                            .font(.caption)
                        Text("\(context.state.awayScore)")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.quarter)
                        Spacer()
                        Text(context.state.timeRemaining)
                            .monospacedDigit()
                    }
                    .font(.caption)
                }
            } compactLeading: {
                Text("\(context.state.homeScore)")
                    .fontWeight(.bold)
            } compactTrailing: {
                Text("\(context.state.awayScore)")
                    .fontWeight(.bold)
            } minimal: {
                Image(systemName: "sportscourt.fill")
            }
        }
    }
}

// MARK: - Egg Timer Live Activity

struct EggTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EggTimerActivityAttributes.self) { context in
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 6)
                        .opacity(0.3)
                    Circle()
                        .trim(from: 0, to: progress(context.state))
                        .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(context.state.isDone ? "!" : "")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .frame(width: 60, height: 60)
                .foregroundStyle(context.state.isDone ? .green : .yellow)

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.eggStyle.rawValue)
                        .font(.headline)
                    Text("\(context.attributes.quantity) egg\(context.attributes.quantity > 1 ? "s" : "")")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                if context.state.isDone {
                    Text("DONE!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                } else {
                    Text(formatTime(context.state.secondsRemaining))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .padding()
            .foregroundStyle(.white)
            .activityBackgroundTint(context.state.isDone ? .green.opacity(0.9) : .yellow.opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "oval.fill")
                        .foregroundStyle(.yellow)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.eggStyle.rawValue)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isDone {
                        Text("Eggs are ready!")
                            .font(.headline)
                    } else {
                        HStack {
                            Text("\(context.attributes.quantity) eggs")
                            Spacer()
                            Text(formatTime(context.state.secondsRemaining))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "oval.fill")
                    .foregroundStyle(.yellow)
            } compactTrailing: {
                Text(formatTime(context.state.secondsRemaining))
                    .font(.caption)
            } minimal: {
                Image(systemName: "oval.fill")
                    .foregroundStyle(.yellow)
            }
        }
    }

    private func progress(_ state: EggTimerActivityAttributes.ContentState) -> Double {
        guard state.totalSeconds > 0 else { return 1 }
        return 1.0 - (Double(state.secondsRemaining) / Double(state.totalSeconds))
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
