import SwiftUI
import BackgroundTasks

// MARK: - Background Tasks Demo View

struct BackgroundTasksView: View {
    @StateObject private var taskManager = BackgroundTaskManager.shared
    @State private var showDebugInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Overview
                statusOverview

                // App Refresh Task Card
                taskCard(
                    title: "App Refresh Task",
                    icon: "arrow.clockwise.circle.fill",
                    color: .blue,
                    description: "30-second window to refresh content",
                    taskType: .refresh,
                    isScheduled: taskManager.refreshTaskScheduled,
                    lastRun: taskManager.lastRefreshRun
                )

                // Processing Task Card
                taskCard(
                    title: "Processing Task",
                    icon: "gearshape.2.fill",
                    color: .orange,
                    description: "Extended time for heavy work (1+ min)",
                    taskType: .processing,
                    isScheduled: taskManager.processingTaskScheduled,
                    lastRun: taskManager.lastProcessingRun
                )

                // Execution Log
                executionLogSection

                // Requirements Section
                requirementsSection

                // Debug Commands
                debugCommandsSection

                // How It Works
                howItWorksSection
            }
            .padding()
        }
        .navigationTitle("Background Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDebugInfo.toggle()
                } label: {
                    Image(systemName: "terminal")
                }
            }
        }
        .sheet(isPresented: $showDebugInfo) {
            debugSheet
        }
        .onAppear {
            taskManager.loadState()
        }
    }

    // MARK: - Status Overview

    private var statusOverview: some View {
        HStack(spacing: 16) {
            statusCard(
                title: "Battery",
                value: "\(Int(taskManager.batteryLevel * 100))%",
                icon: batteryIcon,
                color: batteryColor
            )

            statusCard(
                title: "Charging",
                value: taskManager.isCharging ? "Yes" : "No",
                icon: taskManager.isCharging ? "bolt.fill" : "bolt.slash",
                color: taskManager.isCharging ? .green : .secondary
            )

            statusCard(
                title: "Tasks Run",
                value: "\(taskManager.executionLog.count)",
                icon: "checkmark.circle.fill",
                color: .blue
            )
        }
    }

    private var batteryIcon: String {
        let level = taskManager.batteryLevel
        if taskManager.isCharging {
            return "battery.100.bolt"
        } else if level > 0.75 {
            return "battery.100"
        } else if level > 0.5 {
            return "battery.75"
        } else if level > 0.25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }

    private var batteryColor: Color {
        let level = taskManager.batteryLevel
        if taskManager.isCharging { return .green }
        if level > 0.5 { return .green }
        if level > 0.2 { return .yellow }
        return .red
    }

    private func statusCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Task Card

    enum TaskType {
        case refresh, processing
    }

    private func taskCard(
        title: String,
        icon: String,
        color: Color,
        description: String,
        taskType: TaskType,
        isScheduled: Bool,
        lastRun: Date?
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(isScheduled ? .green : .secondary)
                        .frame(width: 8, height: 8)
                    Text(isScheduled ? "Scheduled" : "Not Scheduled")
                        .font(.caption)
                        .foregroundStyle(isScheduled ? .green : .secondary)
                }
            }

            // Last run info
            if let lastRun = lastRun {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Last run: \(lastRun.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            // Task-specific requirements
            if taskType == .processing {
                HStack(spacing: 16) {
                    requirementBadge(
                        icon: "bolt.fill",
                        text: "Power",
                        met: taskManager.isCharging
                    )
                    requirementBadge(
                        icon: "wifi",
                        text: "Network",
                        met: true // Always show as available for demo
                    )
                    requirementBadge(
                        icon: "moon.fill",
                        text: "Idle",
                        met: false // Device needs to be idle
                    )
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    if taskType == .refresh {
                        taskManager.scheduleRefreshTask()
                    } else {
                        taskManager.scheduleProcessingTask()
                    }
                } label: {
                    Text("Schedule")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(color.opacity(0.2))
                        .foregroundStyle(color)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    if taskType == .refresh {
                        taskManager.cancelRefreshTask()
                    } else {
                        taskManager.cancelProcessingTask()
                    }
                } label: {
                    Text("Cancel")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.secondary.opacity(0.2))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!isScheduled)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func requirementBadge(icon: String, text: String, met: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
            Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle")
                .font(.caption2)
        }
        .foregroundStyle(met ? .green : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(met ? .green.opacity(0.1) : .secondary.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Execution Log Section

    private var executionLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Execution Log")
                    .font(.headline)
                Spacer()
                if !taskManager.executionLog.isEmpty {
                    Button("Clear") {
                        taskManager.clearLog()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
            }

            if taskManager.executionLog.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No tasks have run yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
            } else {
                ForEach(taskManager.executionLog.reversed()) { entry in
                    logEntryRow(entry)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func logEntryRow(_ entry: BackgroundTaskManager.LogEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(entry.success ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.taskType)
                    .font(.subheadline.weight(.medium))
                Text(entry.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Requirements Section

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Requirements")
                .font(.headline)

            VStack(spacing: 8) {
                requirementRow(
                    task: "App Refresh",
                    requirements: "• 30 seconds max\n• Can run anytime\n• May be deferred by system"
                )

                Divider()

                requirementRow(
                    task: "Processing",
                    requirements: "• Minutes of runtime\n• Requires charging\n• Requires idle device\n• Optional: network"
                )
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func requirementRow(task: String, requirements: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task)
                .font(.subheadline.weight(.semibold))
            Text(requirements)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Debug Commands Section

    private var debugCommandsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "terminal.fill")
                Text("Debug Commands")
                    .font(.headline)
            }

            Text("Use these LLDB commands to test background tasks in Xcode:")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                debugCommandRow(
                    title: "Simulate Refresh Task",
                    command: "e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@\"\(BackgroundTaskManager.refreshTaskIdentifier)\"]"
                )

                debugCommandRow(
                    title: "Simulate Processing Task",
                    command: "e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@\"\(BackgroundTaskManager.processingTaskIdentifier)\"]"
                )

                debugCommandRow(
                    title: "Simulate Expiration",
                    command: "e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@\"\(BackgroundTaskManager.refreshTaskIdentifier)\"]"
                )
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func debugCommandRow(title: String, command: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))

            HStack {
                Text(command)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer()

                Button {
                    UIPasteboard.general.string = command
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How Background Tasks Work")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                howItWorksRow(
                    number: 1,
                    title: "Register Task Identifiers",
                    description: "Add identifiers to Info.plist before app launch completes"
                )
                howItWorksRow(
                    number: 2,
                    title: "Schedule Tasks",
                    description: "Use BGTaskScheduler to request task execution"
                )
                howItWorksRow(
                    number: 3,
                    title: "System Decides When",
                    description: "iOS chooses optimal time based on usage patterns"
                )
                howItWorksRow(
                    number: 4,
                    title: "Handle Launch",
                    description: "App woken up, task handler called with BGTask"
                )
                howItWorksRow(
                    number: 5,
                    title: "Complete or Reschedule",
                    description: "Mark task complete and schedule next if needed"
                )
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func howItWorksRow(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Debug Sheet

    private var debugSheet: some View {
        NavigationStack {
            List {
                Section("Registered Task Identifiers") {
                    Text(BackgroundTaskManager.refreshTaskIdentifier)
                        .font(.system(.caption, design: .monospaced))
                    Text(BackgroundTaskManager.processingTaskIdentifier)
                        .font(.system(.caption, design: .monospaced))
                }

                Section("Info.plist Entry Required") {
                    Text("""
                    <key>BGTaskSchedulerPermittedIdentifiers</key>
                    <array>
                        <string>\(BackgroundTaskManager.refreshTaskIdentifier)</string>
                        <string>\(BackgroundTaskManager.processingTaskIdentifier)</string>
                    </array>
                    """)
                    .font(.system(.caption2, design: .monospaced))
                }

                Section("Registration Code") {
                    Text("""
                    BGTaskScheduler.shared.register(
                        forTaskWithIdentifier: identifier,
                        using: nil
                    ) { task in
                        self.handleTask(task)
                    }
                    """)
                    .font(.system(.caption2, design: .monospaced))
                }

                Section("Scheduling Code") {
                    Text("""
                    let request = BGAppRefreshTaskRequest(
                        identifier: identifier
                    )
                    request.earliestBeginDate = Date(
                        timeIntervalSinceNow: 15 * 60
                    )
                    try BGTaskScheduler.shared.submit(request)
                    """)
                    .font(.system(.caption2, design: .monospaced))
                }
            }
            .navigationTitle("Debug Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showDebugInfo = false
                    }
                }
            }
        }
    }
}

// MARK: - Background Task Manager

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()

    static let refreshTaskIdentifier = "com.apiplayground.refresh"
    static let processingTaskIdentifier = "com.apiplayground.processing"

    @Published var refreshTaskScheduled = false
    @Published var processingTaskScheduled = false
    @Published var lastRefreshRun: Date?
    @Published var lastProcessingRun: Date?
    @Published var executionLog: [LogEntry] = []
    @Published var batteryLevel: Float = 1.0
    @Published var isCharging = false

    struct LogEntry: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let taskType: String
        let message: String
        let success: Bool

        init(taskType: String, message: String, success: Bool) {
            self.id = UUID()
            self.timestamp = Date()
            self.taskType = taskType
            self.message = message
            self.success = success
        }
    }

    init() {
        setupBatteryMonitoring()
    }

    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.batteryLevel = UIDevice.current.batteryLevel
        }

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        }
    }

    // MARK: - Task Registration (call from AppDelegate)

    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleRefreshTask(task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { task in
            self.handleProcessingTask(task as! BGProcessingTask)
        }
    }

    // MARK: - Task Handlers

    private func handleRefreshTask(_ task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleRefreshTask()

        let entry = LogEntry(
            taskType: "App Refresh",
            message: "Refresh task started",
            success: true
        )

        DispatchQueue.main.async {
            self.executionLog.append(entry)
            self.lastRefreshRun = Date()
            self.saveState()
        }

        // Simulate some work
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            let completionEntry = LogEntry(
                taskType: "App Refresh",
                message: "Refresh completed successfully",
                success: true
            )

            await MainActor.run {
                self.executionLog.append(completionEntry)
                self.saveState()
            }

            task.setTaskCompleted(success: true)
        }

        // Handle expiration
        task.expirationHandler = {
            let expirationEntry = LogEntry(
                taskType: "App Refresh",
                message: "Task expired before completion",
                success: false
            )

            DispatchQueue.main.async {
                self.executionLog.append(expirationEntry)
                self.saveState()
            }
        }
    }

    private func handleProcessingTask(_ task: BGProcessingTask) {
        // Schedule next processing
        scheduleProcessingTask()

        let entry = LogEntry(
            taskType: "Processing",
            message: "Processing task started",
            success: true
        )

        DispatchQueue.main.async {
            self.executionLog.append(entry)
            self.lastProcessingRun = Date()
            self.saveState()
        }

        // Simulate heavy work
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

            let completionEntry = LogEntry(
                taskType: "Processing",
                message: "Processing completed successfully",
                success: true
            )

            await MainActor.run {
                self.executionLog.append(completionEntry)
                self.saveState()
            }

            task.setTaskCompleted(success: true)
        }

        // Handle expiration
        task.expirationHandler = {
            let expirationEntry = LogEntry(
                taskType: "Processing",
                message: "Task expired - device may have woken up",
                success: false
            )

            DispatchQueue.main.async {
                self.executionLog.append(expirationEntry)
                self.saveState()
            }
        }
    }

    // MARK: - Scheduling

    func scheduleRefreshTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            DispatchQueue.main.async {
                self.refreshTaskScheduled = true
                self.executionLog.append(LogEntry(
                    taskType: "App Refresh",
                    message: "Scheduled for ~15 minutes",
                    success: true
                ))
                self.saveState()
            }
        } catch {
            DispatchQueue.main.async {
                self.executionLog.append(LogEntry(
                    taskType: "App Refresh",
                    message: "Failed to schedule: \(error.localizedDescription)",
                    success: false
                ))
                self.saveState()
            }
        }
    }

    func scheduleProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: Self.processingTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true

        do {
            try BGTaskScheduler.shared.submit(request)
            DispatchQueue.main.async {
                self.processingTaskScheduled = true
                self.executionLog.append(LogEntry(
                    taskType: "Processing",
                    message: "Scheduled (requires charging)",
                    success: true
                ))
                self.saveState()
            }
        } catch {
            DispatchQueue.main.async {
                self.executionLog.append(LogEntry(
                    taskType: "Processing",
                    message: "Failed to schedule: \(error.localizedDescription)",
                    success: false
                ))
                self.saveState()
            }
        }
    }

    func cancelRefreshTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
        DispatchQueue.main.async {
            self.refreshTaskScheduled = false
            self.executionLog.append(LogEntry(
                taskType: "App Refresh",
                message: "Task cancelled",
                success: true
            ))
            self.saveState()
        }
    }

    func cancelProcessingTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.processingTaskIdentifier)
        DispatchQueue.main.async {
            self.processingTaskScheduled = false
            self.executionLog.append(LogEntry(
                taskType: "Processing",
                message: "Task cancelled",
                success: true
            ))
            self.saveState()
        }
    }

    func clearLog() {
        executionLog = []
        saveState()
    }

    // MARK: - Persistence

    func saveState() {
        let state = SavedState(
            refreshScheduled: refreshTaskScheduled,
            processingScheduled: processingTaskScheduled,
            lastRefresh: lastRefreshRun,
            lastProcessing: lastProcessingRun,
            log: executionLog
        )

        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: "backgroundTaskState")
        }
    }

    func loadState() {
        if let data = UserDefaults.standard.data(forKey: "backgroundTaskState"),
           let state = try? JSONDecoder().decode(SavedState.self, from: data) {
            refreshTaskScheduled = state.refreshScheduled
            processingTaskScheduled = state.processingScheduled
            lastRefreshRun = state.lastRefresh
            lastProcessingRun = state.lastProcessing
            executionLog = state.log
        }
    }

    struct SavedState: Codable {
        let refreshScheduled: Bool
        let processingScheduled: Bool
        let lastRefresh: Date?
        let lastProcessing: Date?
        let log: [LogEntry]
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BackgroundTasksView()
    }
}
