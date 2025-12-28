import SwiftUI
import UserNotifications

// MARK: - NotificationsView
/// A comprehensive notification testing interface demonstrating UserNotifications framework.
///
/// Features:
/// - Permission status display and request
/// - Multiple notification types (basic, with image, actionable)
/// - Custom scheduling (immediate, delayed, calendar-based)
/// - Notification categories with custom actions
/// - Pending notifications management
/// - Notification history viewing
///
/// APIs Demonstrated:
/// - UNUserNotificationCenter for notification management
/// - UNMutableNotificationContent for notification content
/// - UNTimeIntervalNotificationTrigger for time-based triggers
/// - UNCalendarNotificationTrigger for calendar-based triggers
/// - UNNotificationCategory for actionable notifications
/// - UNNotificationAction for notification buttons
struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var selectedTab = 0
    @State private var customTitle = "API Playground"
    @State private var customBody = "This is a test notification!"
    @State private var customDelay: Double = 5
    @State private var notificationStyle: NotificationStyle = .basic
    @State private var scheduledDate = Date().addingTimeInterval(60)

    var body: some View {
        List {
            // Permission status section
            Section {
                HStack {
                    Image(systemName: notificationManager.statusIcon)
                        .foregroundStyle(notificationManager.statusColor)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Permission Status")
                            .font(.headline)
                        Text(notificationManager.statusDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if notificationManager.permissionStatus == .notDetermined {
                        Button("Request") {
                            notificationManager.requestPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }

            // Quick send section
            Section("Quick Send") {
                ForEach(QuickNotification.allCases) { notification in
                    Button(action: { notificationManager.sendQuickNotification(notification) }) {
                        HStack {
                            Image(systemName: notification.icon)
                                .foregroundStyle(notification.color)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(notification.title)
                                    .foregroundStyle(.primary)
                                Text(notification.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(notification.delay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(notificationManager.permissionStatus != .authorized)
                }
            }

            // Custom notification section
            Section("Custom Notification") {
                TextField("Title", text: $customTitle)
                TextField("Body", text: $customBody)

                Picker("Style", selection: $notificationStyle) {
                    ForEach(NotificationStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Delay")
                        Spacer()
                        Text("\(Int(customDelay)) seconds")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $customDelay, in: 1...60, step: 1)
                }

                Button(action: sendCustomNotification) {
                    Label("Schedule Notification", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(notificationManager.permissionStatus != .authorized)
            }

            // Calendar-based scheduling
            Section("Schedule for Date") {
                DatePicker(
                    "Date & Time",
                    selection: $scheduledDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )

                Button(action: scheduleCalendarNotification) {
                    Label("Schedule for \(scheduledDate.formatted(date: .abbreviated, time: .shortened))", systemImage: "calendar.badge.clock")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(notificationManager.permissionStatus != .authorized)
            }

            // Pending notifications section
            Section {
                HStack {
                    Text("Pending Notifications")
                    Spacer()
                    Text("\(notificationManager.pendingCount)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                if notificationManager.pendingCount > 0 {
                    Button(role: .destructive, action: {
                        notificationManager.clearAllPending()
                    }) {
                        Label("Clear All Pending", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Notification categories info
            Section("Actionable Notifications") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom notification categories are registered that allow users to respond directly from the notification banner.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(action: sendActionableNotification) {
                        Label("Send Actionable Notification", systemImage: "hand.tap")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(notificationManager.permissionStatus != .authorized)
                }
            }

            // Settings link
            Section {
                Button(action: openSettings) {
                    Label("Open Notification Settings", systemImage: "gear")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notificationManager.checkStatus()
            notificationManager.registerCategories()
        }
        .refreshable {
            notificationManager.checkStatus()
        }
    }

    /// Sends a custom notification with user-specified content.
    private func sendCustomNotification() {
        notificationManager.sendCustomNotification(
            title: customTitle,
            body: customBody,
            delay: customDelay,
            style: notificationStyle
        )
    }

    /// Schedules a notification for a specific date/time.
    private func scheduleCalendarNotification() {
        notificationManager.scheduleCalendarNotification(
            title: customTitle,
            body: customBody,
            date: scheduledDate
        )
    }

    /// Sends an actionable notification with response buttons.
    private func sendActionableNotification() {
        notificationManager.sendActionableNotification()
    }

    /// Opens the app's notification settings.
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - QuickNotification
/// Predefined notification templates.
enum QuickNotification: String, CaseIterable, Identifiable {
    case instant
    case delayed5
    case delayed10
    case delayed30
    case withSound
    case withBadge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instant: return "Instant Notification"
        case .delayed5: return "5 Second Delay"
        case .delayed10: return "10 Second Delay"
        case .delayed30: return "30 Second Delay"
        case .withSound: return "With Custom Sound"
        case .withBadge: return "With Badge Update"
        }
    }

    var subtitle: String {
        switch self {
        case .instant: return "Sends immediately"
        case .delayed5: return "Leave app to see notification"
        case .delayed10: return "Leave app to see notification"
        case .delayed30: return "Leave app to see notification"
        case .withSound: return "Includes notification sound"
        case .withBadge: return "Updates app badge to 1"
        }
    }

    var icon: String {
        switch self {
        case .instant: return "bolt.fill"
        case .delayed5, .delayed10, .delayed30: return "clock.fill"
        case .withSound: return "speaker.wave.3.fill"
        case .withBadge: return "app.badge.fill"
        }
    }

    var color: Color {
        switch self {
        case .instant: return .yellow
        case .delayed5: return .blue
        case .delayed10: return .purple
        case .delayed30: return .indigo
        case .withSound: return .green
        case .withBadge: return .red
        }
    }

    var delay: String {
        switch self {
        case .instant: return "Now"
        case .delayed5: return "5s"
        case .delayed10: return "10s"
        case .delayed30: return "30s"
        case .withSound: return "3s"
        case .withBadge: return "3s"
        }
    }

    var delayInterval: TimeInterval {
        switch self {
        case .instant: return 0.1
        case .delayed5: return 5
        case .delayed10: return 10
        case .delayed30: return 30
        case .withSound, .withBadge: return 3
        }
    }
}

// MARK: - NotificationStyle
/// Visual styles for notifications.
enum NotificationStyle: String, CaseIterable, Identifiable {
    case basic = "Basic"
    case withSubtitle = "With Subtitle"
    case withSound = "With Sound"
    case silent = "Silent"

    var id: String { rawValue }
}

// MARK: - NotificationManager
/// Manages all notification-related functionality.
///
/// This class handles:
/// - Permission requests and status tracking
/// - Notification scheduling and delivery
/// - Category and action registration
/// - Pending notification management
@MainActor
class NotificationManager: ObservableObject {
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingCount = 0

    private let center = UNUserNotificationCenter.current()

    /// Status icon based on permission state.
    var statusIcon: String {
        switch permissionStatus {
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        case .provisional: return "clock.fill"
        case .ephemeral: return "timer"
        @unknown default: return "circle"
        }
    }

    /// Status color based on permission state.
    var statusColor: Color {
        switch permissionStatus {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        case .provisional: return .yellow
        case .ephemeral: return .blue
        @unknown default: return .gray
        }
    }

    /// Status description text.
    var statusDescription: String {
        switch permissionStatus {
        case .authorized: return "Notifications are enabled"
        case .denied: return "Notifications are disabled in Settings"
        case .notDetermined: return "Permission not yet requested"
        case .provisional: return "Delivering quietly"
        case .ephemeral: return "App Clip notifications"
        @unknown default: return "Unknown status"
        }
    }

    /// Checks current notification permission status.
    func checkStatus() {
        center.getNotificationSettings { settings in
            Task { @MainActor in
                self.permissionStatus = settings.authorizationStatus
            }
        }
        updatePendingCount()
    }

    /// Requests notification permission from the user.
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            Task { @MainActor in
                self.checkStatus()
            }
        }
    }

    /// Registers notification categories for actionable notifications.
    func registerCategories() {
        let replyAction = UNNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: .destructive
        )

        let reminderAction = UNNotificationAction(
            identifier: "REMIND_ACTION",
            title: "Remind in 1 Hour",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "ACTION_CATEGORY",
            actions: [replyAction, reminderAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        center.setNotificationCategories([category])
    }

    /// Sends a quick notification from preset templates.
    func sendQuickNotification(_ notification: QuickNotification) {
        let content = UNMutableNotificationContent()
        content.title = "API Playground"
        content.body = notification.title

        switch notification {
        case .withSound:
            content.sound = .default
        case .withBadge:
            content.badge = 1
            content.sound = .default
        default:
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: notification.delayInterval,
            repeats: false
        )

        scheduleNotification(content: content, trigger: trigger)
    }

    /// Sends a custom notification with specified parameters.
    func sendCustomNotification(
        title: String,
        body: String,
        delay: TimeInterval,
        style: NotificationStyle
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        switch style {
        case .withSubtitle:
            content.subtitle = "Custom Notification"
            content.sound = .default
        case .withSound:
            content.sound = .default
        case .silent:
            break
        case .basic:
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(0.1, delay),
            repeats: false
        )

        scheduleNotification(content: content, trigger: trigger)
    }

    /// Schedules a notification for a specific date.
    func scheduleCalendarNotification(title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        scheduleNotification(content: content, trigger: trigger)
    }

    /// Sends an actionable notification with buttons.
    func sendActionableNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Action Required"
        content.body = "This notification has action buttons. Long-press or pull down to see options."
        content.categoryIdentifier = "ACTION_CATEGORY"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        scheduleNotification(content: content, trigger: trigger)
    }

    /// Clears all pending notifications.
    func clearAllPending() {
        center.removeAllPendingNotificationRequests()
        center.setBadgeCount(0)
        updatePendingCount()
    }

    /// Updates the pending notification count.
    private func updatePendingCount() {
        center.getPendingNotificationRequests { requests in
            Task { @MainActor in
                self.pendingCount = requests.count
            }
        }
    }

    /// Schedules a notification with the given content and trigger.
    private func scheduleNotification(
        content: UNMutableNotificationContent,
        trigger: UNNotificationTrigger
    ) {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { [weak self] error in
            if error == nil {
                Task { @MainActor in
                    self?.updatePendingCount()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
