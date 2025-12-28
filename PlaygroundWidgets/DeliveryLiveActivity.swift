import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity widget for delivery tracking
/// Displays on Lock Screen and Dynamic Island
struct DeliveryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeliveryActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: context.state.currentStatus.icon)
                            .foregroundStyle(.green)
                        Text(context.state.currentStatus.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.state.estimatedDeliveryTime, style: .timer)
                            .font(.caption)
                            .fontWeight(.bold)
                            .monospacedDigit()
                        Text("ETA")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text("Order #\(context.attributes.orderNumber)")
                            .font(.headline)
                        Text(context.attributes.restaurantName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar
                    VStack(spacing: 8) {
                        ProgressView(value: context.state.progress)
                            .tint(.green)

                        HStack {
                            Image(systemName: "bag.fill")
                                .foregroundStyle(context.state.progress >= 0.25 ? .green : .gray)
                            Spacer()
                            Image(systemName: "car.fill")
                                .foregroundStyle(context.state.progress >= 0.5 ? .green : .gray)
                            Spacer()
                            Image(systemName: "house.fill")
                                .foregroundStyle(context.state.progress >= 1.0 ? .green : .gray)
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                // Compact leading (left pill)
                Image(systemName: context.state.currentStatus.icon)
                    .foregroundStyle(.green)
            } compactTrailing: {
                // Compact trailing (right pill)
                Text(context.state.estimatedDeliveryTime, style: .timer)
                    .font(.caption)
                    .fontWeight(.medium)
                    .monospacedDigit()
            } minimal: {
                // Minimal (when other activities are present)
                Image(systemName: "bag.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<DeliveryActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Order #\(context.attributes.orderNumber)")
                        .font(.headline)
                    Text(context.attributes.restaurantName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.estimatedDeliveryTime, style: .timer)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Status
            HStack {
                Image(systemName: context.state.currentStatus.icon)
                    .foregroundStyle(.green)
                    .font(.title3)
                Text(context.state.currentStatus.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if context.state.currentStatus == .onTheWay || context.state.currentStatus == .arriving {
                    Text("- \(context.state.driverName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Progress
            VStack(spacing: 6) {
                ProgressView(value: context.state.progress)
                    .tint(.green)

                HStack {
                    LAProgressStep(icon: "fork.knife", label: "Prep", isComplete: context.state.progress >= 0.1)
                    Spacer()
                    LAProgressStep(icon: "bag.fill", label: "Picked Up", isComplete: context.state.progress >= 0.33)
                    Spacer()
                    LAProgressStep(icon: "car.fill", label: "On Way", isComplete: context.state.progress >= 0.66)
                    Spacer()
                    LAProgressStep(icon: "house.fill", label: "Delivered", isComplete: context.state.progress >= 1.0)
                }
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Progress Step
struct LAProgressStep: View {
    let icon: String
    let label: String
    let isComplete: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .foregroundStyle(isComplete ? .green : .gray)
            Text(label)
                .font(.caption2)
                .foregroundStyle(isComplete ? .primary : .secondary)
        }
    }
}

// MARK: - Preview
#Preview("Lock Screen", as: .content, using: DeliveryActivityAttributes(
    orderNumber: "12345",
    restaurantName: "Pizza Palace",
    orderItems: "2x Pepperoni Pizza"
)) {
    DeliveryLiveActivity()
} contentStates: {
    DeliveryActivityAttributes.ContentState(
        driverName: "John",
        estimatedDeliveryTime: Date().addingTimeInterval(15 * 60),
        currentStatus: .onTheWay,
        progress: 0.6
    )
}
