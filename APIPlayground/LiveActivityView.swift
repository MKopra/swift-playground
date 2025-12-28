import SwiftUI
import ActivityKit

// MARK: - LiveActivityView
/// Demonstrates ActivityKit for Live Activities on Lock Screen and Dynamic Island.
///
/// Features:
/// - Start/update/end Live Activities
/// - Dynamic Island compact and expanded views
/// - Lock Screen live updates
/// - Push token for remote updates
/// - Activity state monitoring
/// - Multiple concurrent activities
///
/// APIs Demonstrated:
/// - ActivityKit framework
/// - Activity<T> for managing activities
/// - ActivityAttributes for defining content
/// - ActivityContent for state updates
/// - Push token retrieval for server updates
///
/// Note: Live Activities require iOS 16.1+ and Widget Extension target.
/// This demo simulates the API without the widget extension.
struct LiveActivityView: View {
    @StateObject private var manager = LiveActivityManager()
    @State private var deliveryProgress: Double = 0.0
    @State private var estimatedMinutes: Int = 30
    @State private var driverName: String = "John"
    @State private var orderNumber: String = "12345"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Card
                statusCard

                // Activity Preview
                activityPreviewCard

                // Controls
                controlsCard

                // Configuration
                configurationCard

                // Info Section
                infoCard
            }
            .padding()
        }
        .navigationTitle("Live Activity")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: manager.isActivityActive ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(manager.isActivityActive ? .green : .secondary)
                    Text(manager.isActivityActive ? "Activity Running" : "No Active Activity")
                        .font(.headline)
                    Spacer()
                }

                if manager.isActivityActive {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Activity ID:")
                                .foregroundStyle(.secondary)
                            Text(manager.activityId ?? "Unknown")
                                .font(.caption)
                                .monospaced()
                        }

                        HStack {
                            Text("State:")
                                .foregroundStyle(.secondary)
                            Text(manager.activityState)
                                .foregroundStyle(.blue)
                        }

                        if let token = manager.pushToken {
                            HStack {
                                Text("Push Token:")
                                    .foregroundStyle(.secondary)
                                Text(token.prefix(20) + "...")
                                    .font(.caption)
                                    .monospaced()
                            }
                        }
                    }
                    .font(.subheadline)
                }

                // ActivityKit availability
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text(manager.availabilityStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Activity Status", systemImage: "rectangle.portrait.on.rectangle.portrait.fill")
        }
    }

    // MARK: - Activity Preview Card
    private var activityPreviewCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                Text("Live Activity Preview")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Simulated Lock Screen Live Activity
                VStack(spacing: 0) {
                    // Lock Screen appearance
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Order #\(orderNumber)")
                                .font(.headline)
                            Text("\(driverName) is on the way")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(estimatedMinutes) min")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("ETA")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.3))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: geo.size.width * deliveryProgress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.top, 12)

                    // Status icons
                    HStack {
                        StatusIcon(icon: "bag.fill", label: "Picked Up", isComplete: deliveryProgress >= 0.33)
                        Spacer()
                        StatusIcon(icon: "car.fill", label: "On Way", isComplete: deliveryProgress >= 0.66)
                        Spacer()
                        StatusIcon(icon: "house.fill", label: "Delivered", isComplete: deliveryProgress >= 1.0)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)

                // Dynamic Island simulation
                VStack(spacing: 8) {
                    Text("Dynamic Island (Compact)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "bag.fill")
                            .foregroundStyle(.green)
                        Text("\(estimatedMinutes) min")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black)
                    .clipShape(Capsule())
                }
            }
        } label: {
            Label("Preview", systemImage: "iphone")
        }
    }

    // MARK: - Controls Card
    private var controlsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                if !manager.isActivityActive {
                    Button(action: {
                        manager.startActivity(
                            orderNumber: orderNumber,
                            driverName: driverName,
                            estimatedMinutes: estimatedMinutes
                        )
                    }) {
                        Label("Start Live Activity", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    // Update button
                    Button(action: {
                        manager.updateActivity(
                            progress: deliveryProgress,
                            estimatedMinutes: estimatedMinutes
                        )
                    }) {
                        Label("Update Activity", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }

                    // End button
                    Button(action: {
                        manager.endActivity(delivered: deliveryProgress >= 1.0)
                    }) {
                        Label("End Activity", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
            }
        } label: {
            Label("Controls", systemImage: "slider.horizontal.3")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Order number
                HStack {
                    Text("Order #")
                    Spacer()
                    TextField("Order", text: $orderNumber)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                // Driver name
                HStack {
                    Text("Driver")
                    Spacer()
                    TextField("Name", text: $driverName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                // ETA
                HStack {
                    Text("ETA (minutes)")
                    Spacer()
                    Stepper("\(estimatedMinutes)", value: $estimatedMinutes, in: 1...120)
                        .frame(width: 120)
                }

                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Delivery Progress")
                        Spacer()
                        Text("\(Int(deliveryProgress * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $deliveryProgress, in: 0...1)
                        .tint(.green)
                }
            }
        } label: {
            Label("Configuration", systemImage: "gearshape")
        }
    }

    // MARK: - Info Card
    private var infoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                LAInfoRow(title: "Framework", value: "ActivityKit")
                LAInfoRow(title: "Min iOS", value: "16.1+")
                LAInfoRow(title: "Requires", value: "Widget Extension")
                LAInfoRow(title: "Max Duration", value: "8 hours (12 extended)")
                LAInfoRow(title: "Max Active", value: "5 per app")

                Divider()

                Text("Live Activities display real-time information on the Lock Screen and Dynamic Island. They require a Widget Extension target with ActivityAttributes defined.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("This Demo")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("This view simulates Live Activity UI and API calls. To display real Live Activities on Lock Screen/Dynamic Island, add a Widget Extension target to your project.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        } label: {
            Label("API Information", systemImage: "info.circle")
        }
    }
}

// MARK: - StatusIcon
struct StatusIcon: View {
    let icon: String
    let label: String
    let isComplete: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(isComplete ? .green : .secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(isComplete ? .primary : .secondary)
        }
    }
}

// MARK: - LAInfoRow
struct LAInfoRow: View {
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

// MARK: - LiveActivityManager
/// Manages Live Activity lifecycle and updates using real ActivityKit APIs.
@MainActor
class LiveActivityManager: ObservableObject {
    @Published var isActivityActive = false
    @Published var activityId: String?
    @Published var activityState = "None"
    @Published var pushToken: String?
    @Published var availabilityStatus = "Checking..."
    @Published var currentStatus: DeliveryStatus = .preparing

    private var currentActivity: Activity<DeliveryActivityAttributes>?

    init() {
        checkAvailability()
        observeActivityState()
    }

    private func checkAvailability() {
        if #available(iOS 16.1, *) {
            let activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
            if activitiesEnabled {
                availabilityStatus = "Live Activities are enabled"
            } else {
                availabilityStatus = "Live Activities are disabled in Settings"
            }
        } else {
            availabilityStatus = "Requires iOS 16.1 or later"
        }
    }

    private func observeActivityState() {
        // Observe any existing activities on launch
        if #available(iOS 16.1, *) {
            for activity in Activity<DeliveryActivityAttributes>.activities {
                currentActivity = activity
                activityId = activity.id
                isActivityActive = true
                updateStateFromActivity(activity)
                observeActivity(activity)
                break // Just use the first one
            }
        }
    }

    private func observeActivity(_ activity: Activity<DeliveryActivityAttributes>) {
        Task {
            // Observe state changes
            for await state in activity.activityStateUpdates {
                await MainActor.run {
                    switch state {
                    case .active:
                        self.activityState = "Active"
                    case .ended:
                        self.activityState = "Ended"
                        self.isActivityActive = false
                        self.currentActivity = nil
                    case .dismissed:
                        self.activityState = "Dismissed"
                        self.isActivityActive = false
                        self.currentActivity = nil
                    case .stale:
                        self.activityState = "Stale"
                    @unknown default:
                        self.activityState = "Unknown"
                    }
                }
            }
        }

        Task {
            // Observe push token updates
            for await token in activity.pushTokenUpdates {
                let tokenString = token.map { String(format: "%02x", $0) }.joined()
                await MainActor.run {
                    self.pushToken = tokenString
                }
            }
        }
    }

    private func updateStateFromActivity(_ activity: Activity<DeliveryActivityAttributes>) {
        activityState = switch activity.activityState {
        case .active: "Active"
        case .ended: "Ended"
        case .dismissed: "Dismissed"
        case .stale: "Stale"
        @unknown default: "Unknown"
        }
    }

    func startActivity(orderNumber: String, driverName: String, estimatedMinutes: Int) {
        guard #available(iOS 16.1, *) else { return }

        let attributes = DeliveryActivityAttributes(
            orderNumber: orderNumber,
            restaurantName: "API Playground Demo",
            orderItems: "Demo delivery"
        )

        let initialState = DeliveryActivityAttributes.ContentState(
            driverName: driverName,
            estimatedDeliveryTime: Date().addingTimeInterval(TimeInterval(estimatedMinutes * 60)),
            currentStatus: .preparing,
            progress: 0.1
        )

        do {
            // Note: pushType: .token requires Push Notification entitlements
            // Using nil for local-only updates (no server push support)
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            activityId = activity.id
            isActivityActive = true
            activityState = "Active"
            currentStatus = .preparing

            observeActivity(activity)

            print("[LiveActivity] Started real activity: \(activity.id)")
        } catch {
            print("[LiveActivity] Failed to start: \(error.localizedDescription)")
            availabilityStatus = "Error: \(error.localizedDescription)"
        }
    }

    func updateActivity(progress: Double, estimatedMinutes: Int) {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        // Determine status based on progress
        let status: DeliveryStatus
        if progress >= 1.0 {
            status = .delivered
        } else if progress >= 0.85 {
            status = .arriving
        } else if progress >= 0.66 {
            status = .onTheWay
        } else if progress >= 0.33 {
            status = .pickedUp
        } else {
            status = .preparing
        }

        currentStatus = status

        let updatedState = DeliveryActivityAttributes.ContentState(
            driverName: activity.content.state.driverName,
            estimatedDeliveryTime: Date().addingTimeInterval(TimeInterval(estimatedMinutes * 60)),
            currentStatus: status,
            progress: progress
        )

        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
            print("[LiveActivity] Updated - Status: \(status.rawValue), Progress: \(Int(progress * 100))%")
        }
    }

    func endActivity(delivered: Bool) {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let finalState = DeliveryActivityAttributes.ContentState(
            driverName: activity.content.state.driverName,
            estimatedDeliveryTime: Date(),
            currentStatus: delivered ? .delivered : .pickedUp,
            progress: delivered ? 1.0 : activity.content.state.progress
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: delivered ? .default : .immediate
            )

            await MainActor.run {
                isActivityActive = false
                activityState = delivered ? "Delivered" : "Cancelled"
                currentActivity = nil

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.activityId = nil
                    self.activityState = "None"
                    self.pushToken = nil
                }
            }

            print("[LiveActivity] Ended - Delivered: \(delivered)")
        }
    }
}

#Preview {
    NavigationStack {
        LiveActivityView()
    }
}
