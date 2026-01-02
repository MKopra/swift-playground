import SwiftUI
import CloudKit

// MARK: - CloudKit Sync Demo View

struct CloudKitView: View {
    @StateObject private var cloudManager = CloudKitManager()
    @State private var showAddNote = false
    @State private var newNoteTitle = ""
    @State private var newNoteContent = ""
    @State private var editingNote: SyncedNote?
    @State private var showSyncStatus = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sync Status Card
                syncStatusCard

                // Account Status
                accountStatusSection

                // Quick Actions
                quickActionsSection

                // Notes List
                notesSection

                // Sync Log
                syncLogSection

                // How It Works
                howItWorksSection
            }
            .padding()
        }
        .navigationTitle("CloudKit Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddNote = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddNote) {
            addNoteSheet
        }
        .sheet(item: $editingNote) { note in
            editNoteSheet(note: note)
        }
        .refreshable {
            await cloudManager.fetchNotes()
        }
        .task {
            await cloudManager.checkAccountStatus()
            await cloudManager.fetchNotes()
            cloudManager.subscribeToChanges()
        }
    }

    // MARK: - Sync Status Card

    private var syncStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: cloudManager.syncStatus.icon)
                    .font(.title)
                    .foregroundStyle(cloudManager.syncStatus.color)
                    .symbolEffect(.pulse, isActive: cloudManager.isSyncing)

                VStack(alignment: .leading, spacing: 4) {
                    Text(cloudManager.syncStatus.title)
                        .font(.headline)
                    Text(cloudManager.syncStatus.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if cloudManager.isSyncing {
                    ProgressView()
                }
            }

            // Last synced
            if let lastSync = cloudManager.lastSyncTime {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Last synced: \(lastSync.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }

            // Sync metrics
            HStack(spacing: 20) {
                syncMetric(
                    title: "Notes",
                    value: "\(cloudManager.notes.count)",
                    icon: "note.text"
                )
                syncMetric(
                    title: "Pending",
                    value: "\(cloudManager.pendingChanges)",
                    icon: "arrow.up.circle"
                )
                syncMetric(
                    title: "Conflicts",
                    value: "\(cloudManager.conflictCount)",
                    icon: "exclamationmark.triangle"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func syncMetric(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Account Status Section

    private var accountStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("iCloud Account")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: cloudManager.accountStatus == .available ? "checkmark.icloud.fill" : "xmark.icloud")
                    .font(.title2)
                    .foregroundStyle(cloudManager.accountStatus == .available ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(cloudManager.accountStatus.displayName)
                        .font(.subheadline.weight(.medium))
                    Text(cloudManager.accountStatus.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if cloudManager.accountStatus != .available {
                    Button("Settings") {
                        openICloudSettings()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            HStack(spacing: 12) {
                Button {
                    Task {
                        await cloudManager.fetchNotes()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    Task {
                        await cloudManager.addSampleNotes()
                    }
                } label: {
                    Label("Add Samples", systemImage: "plus.rectangle.on.folder")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        await cloudManager.deleteAllNotes()
                    }
                } label: {
                    Label("Delete All", systemImage: "trash")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    showSyncStatus.toggle()
                } label: {
                    Label("Debug", systemImage: "ladybug")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.opacity(0.1))
                        .foregroundStyle(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Synced Notes")
                    .font(.headline)
                Spacer()
                Text("\(cloudManager.notes.count) notes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if cloudManager.notes.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "note.text",
                    description: Text("Create notes that sync across all your devices")
                )
                .frame(height: 150)
            } else {
                ForEach(cloudManager.notes) { note in
                    noteRow(note)
                }
            }
        }
    }

    private func noteRow(_ note: SyncedNote) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.title)
                        .font(.subheadline.weight(.medium))

                    if note.hasConflict {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Text(note.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // Sync status
                    HStack(spacing: 4) {
                        Image(systemName: note.syncStatus.icon)
                            .font(.caption2)
                        Text(note.syncStatus.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(note.syncStatus.color)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(note.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Edit button
            Button {
                editingNote = note
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.blue)
            }

            // Delete button
            Button {
                Task {
                    await cloudManager.deleteNote(note)
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Sync Log Section

    private var syncLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sync Log")
                    .font(.headline)
                Spacer()
                if !cloudManager.syncLog.isEmpty {
                    Button("Clear") {
                        cloudManager.syncLog = []
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            if cloudManager.syncLog.isEmpty {
                Text("Sync events will appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(cloudManager.syncLog.suffix(5).reversed()) { entry in
                    HStack(spacing: 8) {
                        Image(systemName: entry.icon)
                            .foregroundStyle(entry.color)
                            .font(.caption)

                        Text(entry.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How CloudKit Sync Works")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                howItWorksRow(
                    icon: "icloud.fill",
                    title: "CKContainer",
                    description: "Your app's iCloud container for data storage"
                )
                howItWorksRow(
                    icon: "externaldrive.fill.badge.icloud",
                    title: "CKDatabase",
                    description: "Private, public, or shared databases"
                )
                howItWorksRow(
                    icon: "doc.fill",
                    title: "CKRecord",
                    description: "Individual data records with fields"
                )
                howItWorksRow(
                    icon: "bell.badge.fill",
                    title: "CKSubscription",
                    description: "Push notifications when data changes"
                )
                howItWorksRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "NSPersistentCloudKitContainer",
                    description: "Automatic Core Data + CloudKit sync"
                )
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Limitations
            VStack(alignment: .leading, spacing: 8) {
                Label("Limitations", systemImage: "exclamationmark.triangle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)

                Text("• 1MB max record size\n• Rate limiting on heavy usage\n• watchOS simulator doesn't support CloudKit\n• Requires iCloud account signed in\n• Delta sync with CKServerChangeToken")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Multi-device note
            VStack(alignment: .leading, spacing: 8) {
                Label("Multi-Device Sync", systemImage: "macbook.and.iphone")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)

                Text("Run this app on multiple devices (iPhone, iPad, Mac, Apple Watch) signed into the same iCloud account to see real-time sync in action!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func howItWorksRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Add Note Sheet

    private var addNoteSheet: some View {
        NavigationStack {
            Form {
                Section("Note Details") {
                    TextField("Title", text: $newNoteTitle)
                    TextEditor(text: $newNoteContent)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        newNoteTitle = ""
                        newNoteContent = ""
                        showAddNote = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            await cloudManager.createNote(
                                title: newNoteTitle,
                                content: newNoteContent
                            )
                            newNoteTitle = ""
                            newNoteContent = ""
                            showAddNote = false
                        }
                    }
                    .disabled(newNoteTitle.isEmpty)
                }
            }
        }
    }

    // MARK: - Edit Note Sheet

    private func editNoteSheet(note: SyncedNote) -> some View {
        NavigationStack {
            EditNoteView(
                note: note,
                onSave: { updatedNote in
                    Task {
                        await cloudManager.updateNote(updatedNote)
                        editingNote = nil
                    }
                },
                onCancel: {
                    editingNote = nil
                }
            )
        }
    }

    // MARK: - Helpers

    private func openICloudSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Edit Note View

struct EditNoteView: View {
    let note: SyncedNote
    let onSave: (SyncedNote) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var content: String

    init(note: SyncedNote, onSave: @escaping (SyncedNote) -> Void, onCancel: @escaping () -> Void) {
        self.note = note
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
    }

    var body: some View {
        Form {
            Section("Note Details") {
                TextField("Title", text: $title)
                TextEditor(text: $content)
                    .frame(minHeight: 100)
            }

            Section("Sync Info") {
                LabeledContent("Created", value: note.createdAt.formatted())
                LabeledContent("Modified", value: note.modifiedAt.formatted())
                LabeledContent("Status", value: note.syncStatus.rawValue)
            }
        }
        .navigationTitle("Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    var updatedNote = note
                    updatedNote.title = title
                    updatedNote.content = content
                    updatedNote.modifiedAt = Date()
                    onSave(updatedNote)
                }
                .disabled(title.isEmpty)
            }
        }
    }
}

// MARK: - Synced Note Model

struct SyncedNote: Identifiable, Equatable {
    let id: String
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var syncStatus: SyncStatus
    var hasConflict: Bool
    var recordID: CKRecord.ID?

    enum SyncStatus: String {
        case synced = "Synced"
        case pending = "Pending"
        case error = "Error"

        var icon: String {
            switch self {
            case .synced: return "checkmark.icloud.fill"
            case .pending: return "arrow.clockwise.icloud"
            case .error: return "exclamationmark.icloud"
            }
        }

        var color: Color {
            switch self {
            case .synced: return .green
            case .pending: return .orange
            case .error: return .red
            }
        }
    }

    init(id: String = UUID().uuidString, title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.syncStatus = .pending
        self.hasConflict = false
        self.recordID = nil
    }

    init(from record: CKRecord) {
        self.id = record.recordID.recordName
        self.title = record["title"] as? String ?? ""
        self.content = record["content"] as? String ?? ""
        self.createdAt = record.creationDate ?? Date()
        self.modifiedAt = record.modificationDate ?? Date()
        self.syncStatus = .synced
        self.hasConflict = false
        self.recordID = record.recordID
    }

    func toRecord() -> CKRecord {
        let recordID = self.recordID ?? CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: "Note", recordID: recordID)
        record["title"] = title
        record["content"] = content
        return record
    }
}

// MARK: - CloudKit Manager

@MainActor
class CloudKitManager: ObservableObject {
    @Published var notes: [SyncedNote] = []
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var syncStatus: CloudSyncStatus = .idle
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var pendingChanges = 0
    @Published var conflictCount = 0
    @Published var syncLog: [SyncLogEntry] = []

    private let container = CKContainer(identifier: "iCloud.com.apiplayground")
    private var privateDatabase: CKDatabase { container.privateCloudDatabase }

    enum CloudSyncStatus {
        case idle
        case syncing
        case synced
        case error(String)

        var icon: String {
            switch self {
            case .idle: return "icloud"
            case .syncing: return "arrow.clockwise.icloud"
            case .synced: return "checkmark.icloud.fill"
            case .error: return "exclamationmark.icloud"
            }
        }

        var color: Color {
            switch self {
            case .idle: return .secondary
            case .syncing: return .blue
            case .synced: return .green
            case .error: return .red
            }
        }

        var title: String {
            switch self {
            case .idle: return "Ready to Sync"
            case .syncing: return "Syncing..."
            case .synced: return "All Synced"
            case .error(let message): return "Error: \(message)"
            }
        }

        var description: String {
            switch self {
            case .idle: return "Waiting for changes"
            case .syncing: return "Uploading and downloading"
            case .synced: return "All changes saved to iCloud"
            case .error: return "Check connection and try again"
            }
        }
    }

    struct SyncLogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let type: LogType

        enum LogType {
            case info, success, error
        }

        var icon: String {
            switch type {
            case .info: return "info.circle"
            case .success: return "checkmark.circle"
            case .error: return "xmark.circle"
            }
        }

        var color: Color {
            switch type {
            case .info: return .blue
            case .success: return .green
            case .error: return .red
            }
        }
    }

    // MARK: - Account Status

    func checkAccountStatus() async {
        do {
            accountStatus = try await container.accountStatus()
            addLog("Account status: \(accountStatus.displayName)", type: .info)
        } catch {
            accountStatus = .couldNotDetermine
            addLog("Failed to check account: \(error.localizedDescription)", type: .error)
        }
    }

    // MARK: - CRUD Operations

    func fetchNotes() async {
        guard accountStatus == .available else {
            addLog("Cannot fetch: iCloud not available", type: .error)
            return
        }

        isSyncing = true
        syncStatus = .syncing
        addLog("Fetching notes from iCloud...", type: .info)

        do {
            let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]

            let (results, _) = try await privateDatabase.records(matching: query)

            var fetchedNotes: [SyncedNote] = []
            for (_, result) in results {
                if case .success(let record) = result {
                    fetchedNotes.append(SyncedNote(from: record))
                }
            }

            notes = fetchedNotes
            lastSyncTime = Date()
            syncStatus = .synced
            addLog("Fetched \(fetchedNotes.count) notes", type: .success)
        } catch {
            syncStatus = .error(error.localizedDescription)
            addLog("Fetch failed: \(error.localizedDescription)", type: .error)
        }

        isSyncing = false
    }

    func createNote(title: String, content: String) async {
        var note = SyncedNote(title: title, content: content)
        notes.insert(note, at: 0)
        pendingChanges += 1

        addLog("Creating note: \(title)", type: .info)

        do {
            let record = note.toRecord()
            let savedRecord = try await privateDatabase.save(record)

            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index] = SyncedNote(from: savedRecord)
            }

            pendingChanges = max(0, pendingChanges - 1)
            addLog("Note created and synced", type: .success)
        } catch {
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index].syncStatus = .error
            }
            addLog("Failed to create note: \(error.localizedDescription)", type: .error)
        }
    }

    func updateNote(_ note: SyncedNote) async {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.syncStatus = .pending
            notes[index] = updatedNote
        }

        pendingChanges += 1
        addLog("Updating note: \(note.title)", type: .info)

        do {
            let record = note.toRecord()
            let savedRecord = try await privateDatabase.save(record)

            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index] = SyncedNote(from: savedRecord)
            }

            pendingChanges = max(0, pendingChanges - 1)
            addLog("Note updated and synced", type: .success)
        } catch {
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index].syncStatus = .error
            }
            addLog("Failed to update note: \(error.localizedDescription)", type: .error)
        }
    }

    func deleteNote(_ note: SyncedNote) async {
        notes.removeAll { $0.id == note.id }
        addLog("Deleting note: \(note.title)", type: .info)

        guard let recordID = note.recordID else {
            addLog("Note was never synced, removed locally", type: .info)
            return
        }

        do {
            try await privateDatabase.deleteRecord(withID: recordID)
            addLog("Note deleted from iCloud", type: .success)
        } catch {
            addLog("Failed to delete from iCloud: \(error.localizedDescription)", type: .error)
        }
    }

    func deleteAllNotes() async {
        let notesCopy = notes
        notes = []
        addLog("Deleting all notes...", type: .info)

        for note in notesCopy {
            if let recordID = note.recordID {
                do {
                    try await privateDatabase.deleteRecord(withID: recordID)
                } catch {
                    addLog("Failed to delete: \(note.title)", type: .error)
                }
            }
        }

        addLog("All notes deleted", type: .success)
    }

    func addSampleNotes() async {
        let samples = [
            ("Welcome to CloudKit", "This note syncs across all your devices signed into the same iCloud account."),
            ("Shopping List", "Milk, Eggs, Bread, Butter, Cheese"),
            ("Meeting Notes", "Discussed Q4 roadmap. Action items: Review specs, Schedule design review."),
            ("Ideas", "Build an app that uses every Apple API. Make it beautiful and educational.")
        ]

        for (title, content) in samples {
            await createNote(title: title, content: content)
        }
    }

    // MARK: - Subscriptions

    func subscribeToChanges() {
        let subscription = CKQuerySubscription(
            recordType: "Note",
            predicate: NSPredicate(value: true),
            subscriptionID: "note-changes",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification

        privateDatabase.save(subscription) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.addLog("Subscription failed: \(error.localizedDescription)", type: .error)
                } else {
                    self?.addLog("Subscribed to changes", type: .success)
                }
            }
        }
    }

    // MARK: - Helpers

    private func addLog(_ message: String, type: SyncLogEntry.LogType) {
        let entry = SyncLogEntry(timestamp: Date(), message: message, type: type)
        syncLog.append(entry)

        // Keep only last 50 entries
        if syncLog.count > 50 {
            syncLog.removeFirst()
        }
    }
}

// MARK: - CKAccountStatus Extension

extension CKAccountStatus {
    var displayName: String {
        switch self {
        case .available: return "Signed In"
        case .noAccount: return "No Account"
        case .restricted: return "Restricted"
        case .couldNotDetermine: return "Unknown"
        case .temporarilyUnavailable: return "Temporarily Unavailable"
        @unknown default: return "Unknown"
        }
    }

    var description: String {
        switch self {
        case .available: return "iCloud is ready for syncing"
        case .noAccount: return "Sign in to iCloud in Settings"
        case .restricted: return "iCloud access is restricted"
        case .couldNotDetermine: return "Unable to determine status"
        case .temporarilyUnavailable: return "iCloud is temporarily unavailable"
        @unknown default: return "Unknown status"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CloudKitView()
    }
}
