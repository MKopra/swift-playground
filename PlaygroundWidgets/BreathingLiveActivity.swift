import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity for guided breathing exercises
/// Uses the 5-15 second update rate as a FEATURE for breathing cycle guidance
struct BreathingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BreathingActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenBreathingView(context: context)
                .activityBackgroundTint(backgroundColor(for: context.state.phase))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: context.attributes.pattern.icon)
                            .font(.title2)
                        Text(context.attributes.pattern.rawValue)
                            .font(.caption2)
                            .opacity(0.8)
                    }
                    .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Cycle \(context.state.currentCycle)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("of \(context.state.totalCycles)")
                            .font(.caption2)
                            .opacity(0.8)
                    }
                    .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.center) {
                    BreathingCircleView(
                        phase: context.state.phase,
                        progress: phaseProgress(context.state),
                        size: 60
                    )
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: context.state.phase.icon)
                            .font(.title3)
                        Text(context.state.phase.instruction)
                            .font(.headline)
                        Spacer()
                        Text("\(context.state.secondsRemaining)s")
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                }
            } compactLeading: {
                // Compact leading - breathing circle
                BreathingCircleView(
                    phase: context.state.phase,
                    progress: phaseProgress(context.state),
                    size: 24
                )
            } compactTrailing: {
                // Compact trailing - seconds remaining
                Text("\(context.state.secondsRemaining)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(phaseColor(context.state.phase))
            } minimal: {
                // Minimal - just the breathing circle
                BreathingCircleView(
                    phase: context.state.phase,
                    progress: phaseProgress(context.state),
                    size: 22
                )
            }
            .keylineTint(phaseColor(context.state.phase))
        }
    }

    private func backgroundColor(for phase: BreathingPhase) -> Color {
        switch phase {
        case .inhale: return Color.blue.opacity(0.9)
        case .holdIn: return Color.purple.opacity(0.9)
        case .exhale: return Color.green.opacity(0.9)
        case .holdOut: return Color.gray.opacity(0.9)
        }
    }

    private func phaseColor(_ phase: BreathingPhase) -> Color {
        switch phase {
        case .inhale: return .blue
        case .holdIn: return .purple
        case .exhale: return .green
        case .holdOut: return .gray
        }
    }

    private func phaseProgress(_ state: BreathingActivityAttributes.ContentState) -> Double {
        guard state.phaseTotal > 0 else { return 0 }
        return 1.0 - (Double(state.secondsRemaining) / Double(state.phaseTotal))
    }
}

// MARK: - Lock Screen View

struct LockScreenBreathingView: View {
    let context: ActivityViewContext<BreathingActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Breathing circle
            BreathingCircleView(
                phase: context.state.phase,
                progress: phaseProgress,
                size: 80
            )

            VStack(alignment: .leading, spacing: 8) {
                // Pattern name
                HStack {
                    Image(systemName: context.attributes.pattern.icon)
                    Text(context.attributes.pattern.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white.opacity(0.9))

                // Current instruction
                HStack {
                    Image(systemName: context.state.phase.icon)
                        .font(.title2)
                    Text(context.state.phase.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)

                // Timer and cycle
                HStack {
                    Text("\(context.state.secondsRemaining)s")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()

                    Spacer()

                    Text("Cycle \(context.state.currentCycle)/\(context.state.totalCycles)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2), in: Capsule())
                }
                .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding()
    }

    private var phaseProgress: Double {
        guard context.state.phaseTotal > 0 else { return 0 }
        return 1.0 - (Double(context.state.secondsRemaining) / Double(context.state.phaseTotal))
    }
}

// MARK: - Breathing Circle View

struct BreathingCircleView: View {
    let phase: BreathingPhase
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(lineWidth: size * 0.08)
                .opacity(0.3)
                .foregroundStyle(.white)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-90))

            // Inner circle that "breathes"
            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: innerCircleSize, height: innerCircleSize)

            // Phase icon
            Image(systemName: phaseIcon)
                .font(.system(size: size * 0.25))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    private var innerCircleSize: CGFloat {
        let minSize = size * 0.3
        let maxSize = size * 0.7

        switch phase {
        case .inhale:
            // Growing
            return minSize + (maxSize - minSize) * progress
        case .holdIn:
            // Stay large
            return maxSize
        case .exhale:
            // Shrinking
            return maxSize - (maxSize - minSize) * progress
        case .holdOut:
            // Stay small
            return minSize
        }
    }

    private var phaseIcon: String {
        switch phase {
        case .inhale: return "arrow.down"
        case .holdIn: return "pause"
        case .exhale: return "arrow.up"
        case .holdOut: return "circle"
        }
    }
}
