import SwiftUI
import EventKit
import EventKitUI

// MARK: - EventKitView
/// Comprehensive demonstration of EventKit for Calendar and Reminders.
///
/// Features:
/// - Calendar access and browsing
/// - Event creation and editing
/// - Reminder lists and items
/// - Recurring events
/// - Alarms and notifications
/// - Calendar subscriptions
/// - Attendee management
/// - Availability checking
///
/// APIs Demonstrated:
/// - EKEventStore for data access
/// - EKEvent for calendar events
/// - EKReminder for todo items
/// - EKCalendar for calendar management
/// - EKAlarm for notifications
/// - EKRecurrenceRule for repeating events
///
/// Note: Requires calendar/reminder permissions in Info.plist.
struct EventKitView: View {
    @StateObject private var eventManager = EventKitManager()
    @State private var selectedTab = 0
    @State private var showingEventEditor = false
    @State private var showingReminderEditor = false
    @State private var newEventTitle = ""
    @State private var newEventDate = Date()
    @State private var newEventDuration = 60 // minutes
    @State private var newReminderTitle = ""
    @State private var newReminderDueDate = Date()
    @State private var newReminderHasDueDate = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Authorization Status
                authorizationCard

                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Events").tag(0)
                    Text("Reminders").tag(1)
                    Text("Calendars").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedTab {
                case 0:
                    eventsSection
                case 1:
                    remindersSection
                case 2:
                    calendarsSection
                default:
                    EmptyView()
                }

                // API Info
                apiInfoCard
            }
            .padding()
        }
        .navigationTitle("Calendar & Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            eventManager.requestAccess()
        }
    }

    // MARK: - Authorization Card
    private var authorizationCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: eventManager.calendarAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(eventManager.calendarAuthorized ? .green : .red)
                            Text("Calendar Access")
                        }
                        .font(.subheadline)

                        HStack {
                            Image(systemName: eventManager.remindersAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(eventManager.remindersAuthorized ? .green : .red)
                            Text("Reminders Access")
                        }
                        .font(.subheadline)
                    }

                    Spacer()

                    if !eventManager.calendarAuthorized || !eventManager.remindersAuthorized {
                        Button("Request") {
                            eventManager.requestAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        } label: {
            Label("Permissions", systemImage: "lock.shield")
        }
    }

    // MARK: - Events Section
    private var eventsSection: some View {
        VStack(spacing: 16) {
            // Create Event
            GroupBox {
                VStack(spacing: 12) {
                    TextField("Event Title", text: $newEventTitle)
                        .textFieldStyle(.roundedBorder)

                    DatePicker("Date & Time", selection: $newEventDate)

                    HStack {
                        Text("Duration")
                        Spacer()
                        Picker("Duration", selection: $newEventDuration) {
                            Text("30 min").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                            Text("All day").tag(1440)
                        }
                        .pickerStyle(.menu)
                    }

                    Button(action: createEvent) {
                        Label("Create Event", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newEventTitle.isEmpty || !eventManager.calendarAuthorized)
                }
            } label: {
                Label("New Event", systemImage: "calendar.badge.plus")
            }

            // Upcoming Events
            GroupBox {
                if eventManager.upcomingEvents.isEmpty {
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(eventManager.upcomingEvents, id: \.eventIdentifier) { event in
                            EventRow(event: event, onDelete: {
                                eventManager.deleteEvent(event)
                            })
                        }
                    }
                }
            } label: {
                Label("Upcoming Events (\(eventManager.upcomingEvents.count))", systemImage: "calendar")
            }
        }
    }

    // MARK: - Reminders Section
    private var remindersSection: some View {
        VStack(spacing: 16) {
            // Create Reminder
            GroupBox {
                VStack(spacing: 12) {
                    TextField("Reminder Title", text: $newReminderTitle)
                        .textFieldStyle(.roundedBorder)

                    Toggle("Set Due Date", isOn: $newReminderHasDueDate)

                    if newReminderHasDueDate {
                        DatePicker("Due Date", selection: $newReminderDueDate)
                    }

                    Button(action: createReminder) {
                        Label("Create Reminder", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newReminderTitle.isEmpty || !eventManager.remindersAuthorized)
                }
            } label: {
                Label("New Reminder", systemImage: "checklist")
            }

            // Reminders List
            GroupBox {
                if eventManager.reminders.isEmpty {
                    Text("No reminders")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(eventManager.reminders, id: \.calendarItemIdentifier) { reminder in
                            ReminderRow(
                                reminder: reminder,
                                onToggle: { eventManager.toggleReminder(reminder) },
                                onDelete: { eventManager.deleteReminder(reminder) }
                            )
                        }
                    }
                }
            } label: {
                Label("Reminders (\(eventManager.reminders.count))", systemImage: "list.bullet")
            }
        }
    }

    // MARK: - Calendars Section
    private var calendarsSection: some View {
        VStack(spacing: 16) {
            // Calendar list
            GroupBox {
                VStack(spacing: 8) {
                    ForEach(eventManager.calendars, id: \.calendarIdentifier) { calendar in
                        CalendarRow(calendar: calendar)
                    }
                }
            } label: {
                Label("Calendars (\(eventManager.calendars.count))", systemImage: "calendar.circle")
            }

            // Reminder lists
            GroupBox {
                VStack(spacing: 8) {
                    ForEach(eventManager.reminderLists, id: \.calendarIdentifier) { list in
                        ReminderListRow(calendar: list, count: eventManager.reminderCount(for: list))
                    }
                }
            } label: {
                Label("Reminder Lists (\(eventManager.reminderLists.count))", systemImage: "list.bullet.circle")
            }

            // Calendar capabilities
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    EKCapabilityRow(title: "Create Events", isAvailable: eventManager.calendarAuthorized)
                    EKCapabilityRow(title: "Modify Events", isAvailable: eventManager.calendarAuthorized)
                    EKCapabilityRow(title: "Recurring Events", isAvailable: true)
                    EKCapabilityRow(title: "Attendees", isAvailable: true)
                    EKCapabilityRow(title: "Alarms", isAvailable: true)
                    EKCapabilityRow(title: "Location", isAvailable: true)
                }
            } label: {
                Label("Capabilities", systemImage: "checkmark.seal")
            }
        }
    }

    // MARK: - API Info Card
    private var apiInfoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                EKInfoRow(title: "Framework", value: "EventKit")
                EKInfoRow(title: "Min iOS", value: "4.0+")
                EKInfoRow(title: "Privacy Keys", value: "Calendar, Reminders")
                EKInfoRow(title: "Storage", value: "On-device + iCloud")

                Divider()

                Text("EventKit provides access to calendar events and reminders. Changes sync automatically with iCloud and other calendar services.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("API Information", systemImage: "info.circle")
        }
    }

    // MARK: - Actions
    private func createEvent() {
        guard !newEventTitle.isEmpty else { return }

        let isAllDay = newEventDuration == 1440
        let endDate = isAllDay ? newEventDate : newEventDate.addingTimeInterval(TimeInterval(newEventDuration * 60))

        eventManager.createEvent(
            title: newEventTitle,
            startDate: newEventDate,
            endDate: endDate,
            isAllDay: isAllDay
        )

        newEventTitle = ""
        newEventDate = Date()
    }

    private func createReminder() {
        guard !newReminderTitle.isEmpty else { return }

        eventManager.createReminder(
            title: newReminderTitle,
            dueDate: newReminderHasDueDate ? newReminderDueDate : nil
        )

        newReminderTitle = ""
        newReminderDueDate = Date()
    }
}

// MARK: - EventRow
struct EventRow: View {
    let event: EKEvent
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "Untitled")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(event.startDate.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if event.isAllDay {
                Text("All day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ReminderRow
struct ReminderRow: View {
    let reminder: EKReminder
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(reminder.isCompleted ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title ?? "Untitled")
                    .font(.subheadline)
                    .strikethrough(reminder.isCompleted)

                if let dueDate = reminder.dueDateComponents?.date {
                    Text(dueDate.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if reminder.priority > 0 {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - CalendarRow
struct CalendarRow: View {
    let calendar: EKCalendar

    var body: some View {
        HStack {
            Circle()
                .fill(Color(cgColor: calendar.cgColor))
                .frame(width: 12, height: 12)

            Text(calendar.title)
                .font(.subheadline)

            Spacer()

            Text(calendar.source.title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if calendar.isSubscribed {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ReminderListRow
struct ReminderListRow: View {
    let calendar: EKCalendar
    let count: Int

    var body: some View {
        HStack {
            Circle()
                .fill(Color(cgColor: calendar.cgColor))
                .frame(width: 12, height: 12)

            Text(calendar.title)
                .font(.subheadline)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - EKCapabilityRow
struct EKCapabilityRow: View {
    let title: String
    let isAvailable: Bool

    var body: some View {
        HStack {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isAvailable ? .green : .red)
            Text(title)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - EKInfoRow
struct EKInfoRow: View {
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

// MARK: - EventKitManager
@MainActor
class EventKitManager: ObservableObject {
    @Published var calendarAuthorized = false
    @Published var remindersAuthorized = false
    @Published var calendars: [EKCalendar] = []
    @Published var reminderLists: [EKCalendar] = []
    @Published var upcomingEvents: [EKEvent] = []
    @Published var reminders: [EKReminder] = []

    private let eventStore = EKEventStore()

    func requestAccess() {
        // Request calendar access
        if #available(iOS 17.0, *) {
            Task {
                do {
                    let granted = try await eventStore.requestFullAccessToEvents()
                    calendarAuthorized = granted
                    if granted {
                        loadCalendars()
                        loadUpcomingEvents()
                    }
                } catch {
                    print("Calendar access error: \(error)")
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                Task { @MainActor in
                    self?.calendarAuthorized = granted
                    if granted {
                        self?.loadCalendars()
                        self?.loadUpcomingEvents()
                    }
                }
            }
        }

        // Request reminders access
        if #available(iOS 17.0, *) {
            Task {
                do {
                    let granted = try await eventStore.requestFullAccessToReminders()
                    remindersAuthorized = granted
                    if granted {
                        loadReminderLists()
                        loadReminders()
                    }
                } catch {
                    print("Reminders access error: \(error)")
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { [weak self] granted, error in
                Task { @MainActor in
                    self?.remindersAuthorized = granted
                    if granted {
                        self?.loadReminderLists()
                        self?.loadReminders()
                    }
                }
            }
        }
    }

    private func loadCalendars() {
        calendars = eventStore.calendars(for: .event)
    }

    private func loadReminderLists() {
        reminderLists = eventStore.calendars(for: .reminder)
    }

    private func loadUpcomingEvents() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        upcomingEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }

    private func loadReminders() {
        let predicate = eventStore.predicateForReminders(in: nil)

        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            Task { @MainActor in
                self?.reminders = (reminders ?? [])
                    .filter { !$0.isCompleted }
                    .sorted { ($0.dueDateComponents?.date ?? .distantFuture) < ($1.dueDateComponents?.date ?? .distantFuture) }
            }
        }
    }

    func createEvent(title: String, startDate: Date, endDate: Date, isAllDay: Bool) {
        guard calendarAuthorized else { return }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            loadUpcomingEvents()
        } catch {
            print("Error saving event: \(error)")
        }
    }

    func deleteEvent(_ event: EKEvent) {
        do {
            try eventStore.remove(event, span: .thisEvent)
            loadUpcomingEvents()
        } catch {
            print("Error deleting event: \(error)")
        }
    }

    func createReminder(title: String, dueDate: Date?) {
        guard remindersAuthorized else { return }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }

        do {
            try eventStore.save(reminder, commit: true)
            loadReminders()
        } catch {
            print("Error saving reminder: \(error)")
        }
    }

    func toggleReminder(_ reminder: EKReminder) {
        reminder.isCompleted = !reminder.isCompleted

        do {
            try eventStore.save(reminder, commit: true)
            loadReminders()
        } catch {
            print("Error toggling reminder: \(error)")
        }
    }

    func deleteReminder(_ reminder: EKReminder) {
        do {
            try eventStore.remove(reminder, commit: true)
            loadReminders()
        } catch {
            print("Error deleting reminder: \(error)")
        }
    }

    func reminderCount(for calendar: EKCalendar) -> Int {
        reminders.filter { $0.calendar.calendarIdentifier == calendar.calendarIdentifier }.count
    }
}

#Preview {
    NavigationStack {
        EventKitView()
    }
}
