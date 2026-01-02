import SwiftUI
import CloudKit

struct WatchCloudKitView: View {
    @State private var notes: [CloudNote] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastSyncTime: Date?
    @State private var showingAddNote = false
    @State private var newNoteText = ""

    private let container = CKContainer(identifier: "iCloud.com.apiplayground")

    struct CloudNote: Identifiable {
        let id: String
        let text: String
        let timestamp: Date
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Sync status
                syncStatusSection

                // Notes list
                if notes.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    notesListSection
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
        .navigationTitle("CloudKit")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddNote = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddNote) {
            addNoteSheet
        }
        .onAppear {
            fetchNotes()
        }
    }

    // MARK: - Sync Status Section

    private var syncStatusSection: some View {
        HStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "icloud.fill")
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(isLoading ? "Syncing..." : "Synced")
                    .font(.caption2)
                    .fontWeight(.medium)

                if let lastSync = lastSyncTime {
                    Text(lastSync.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                fetchNotes()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(8)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No notes yet")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Add a note from iPhone or tap +")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Notes List

    private var notesListSection: some View {
        VStack(spacing: 6) {
            ForEach(notes) { note in
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.text)
                        .font(.caption)
                        .lineLimit(2)
                    Text(note.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(.darkGray).opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Add Note Sheet

    private var addNoteSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("Note", text: $newNoteText)
                    .textFieldStyle(.plain)

                Button("Save") {
                    saveNote()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newNoteText.isEmpty)
            }
            .padding()
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddNote = false
                        newNoteText = ""
                    }
                }
            }
        }
    }

    // MARK: - CloudKit Functions

    private func fetchNotes() {
        isLoading = true
        errorMessage = nil

        let database = container.privateCloudDatabase
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: ["text", "timestamp"], resultsLimit: 10) { result in
            DispatchQueue.main.async {
                isLoading = false
                lastSyncTime = Date()

                switch result {
                case .success(let (matchResults, _)):
                    notes = matchResults.compactMap { recordID, result in
                        guard case .success(let record) = result,
                              let text = record["text"] as? String,
                              let timestamp = record["timestamp"] as? Date else {
                            return nil
                        }
                        return CloudNote(id: recordID.recordName, text: text, timestamp: timestamp)
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func saveNote() {
        guard !newNoteText.isEmpty else { return }

        isLoading = true

        let record = CKRecord(recordType: "Note")
        record["text"] = newNoteText
        record["timestamp"] = Date()

        container.privateCloudDatabase.save(record) { _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    showingAddNote = false
                    newNoteText = ""
                    fetchNotes()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WatchCloudKitView()
    }
}
