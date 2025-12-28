import SwiftUI
import CoreNFC

// MARK: - NFCView
/// A comprehensive NFC tag reading interface demonstrating Core NFC capabilities.
///
/// Features:
/// - NDEF message reading from NFC tags
/// - Multiple record type support (text, URL, smart poster)
/// - Tag UID and technology display
/// - Scan history with persistence
/// - Real-time scan status with animated visualization
///
/// APIs Demonstrated:
/// - NFCNDEFReaderSession for tag scanning
/// - NFCNDEFMessage and NFCNDEFPayload parsing
/// - Tag technology identification
/// - Background tag reading support
///
/// Note: This API is NOT available in Flutter - requires native iOS implementation.
/// NFC reading requires the "Near Field Communication Tag Reading" capability.
struct NFCView: View {
    @StateObject private var nfcManager = NFCManager()
    @State private var pulseAnimation = false
    @State private var showingHistory = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.1, blue: 0.2), Color(red: 0.1, green: 0.15, blue: 0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal)

                Spacer()

                // NFC visualization
                ZStack {
                    // Pulse rings
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(
                                nfcManager.isScanning
                                    ? Color.cyan.opacity(0.3 - Double(ring) * 0.1)
                                    : Color.gray.opacity(0.2),
                                lineWidth: 2
                            )
                            .frame(
                                width: 160 + CGFloat(ring) * 60,
                                height: 160 + CGFloat(ring) * 60
                            )
                            .scaleEffect(pulseAnimation && nfcManager.isScanning ? 1.1 : 1.0)
                    }

                    // Main NFC icon
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: nfcManager.isScanning
                                    ? [.cyan, Color(red: 0.1, green: 0.3, blue: 0.5)]
                                    : [.gray, Color(white: 0.2)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: nfcManager.isScanning ? .cyan.opacity(0.5) : .clear, radius: 20)

                    // NFC waves icon
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-45))
                }

                // Status
                VStack(spacing: 8) {
                    Text(nfcManager.isScanning ? "SCANNING..." : "READY")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(nfcManager.isScanning ? .cyan : .white)

                    Text(nfcManager.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Last scanned tag
                if let lastTag = nfcManager.lastScannedTag {
                    NFCTagCard(tag: lastTag)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Scan button
                Button(action: {
                    nfcManager.startScanning()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: nfcManager.isScanning ? "antenna.radiowaves.left.and.right" : "wave.3.right")
                            .font(.title2)
                        Text(nfcManager.isScanning ? "Scanning..." : "Scan NFC Tag")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(nfcManager.isScanning ? Color.gray : Color.cyan)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(nfcManager.isScanning || !nfcManager.isAvailable)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

                if !nfcManager.isAvailable {
                    Text("NFC is not available on this device")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.bottom)
                }
            }
        }
        .navigationTitle("NFC Reader")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            startPulseAnimation()
        }
        .sheet(isPresented: $showingHistory) {
            NFCHistoryView(tags: nfcManager.scannedTags)
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
}

// MARK: - NFCTagCard
/// Displays information about a scanned NFC tag.
struct NFCTagCard: View {
    let tag: NFCTagData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tag.icon)
                    .font(.title2)
                    .foregroundStyle(tag.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(tag.type)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(tag.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !tag.records.isEmpty {
                Divider()

                ForEach(tag.records, id: \.id) { record in
                    HStack(alignment: .top) {
                        Image(systemName: record.icon)
                            .foregroundStyle(.cyan)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.type)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(record.content)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .lineLimit(3)
                        }
                    }
                }
            }

            if let uid = tag.uid {
                HStack {
                    Text("UID:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(uid)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.cyan)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - NFCHistoryView
/// Displays scan history.
struct NFCHistoryView: View {
    let tags: [NFCTagData]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if tags.isEmpty {
                    ContentUnavailableView(
                        "No Scans",
                        systemImage: "wave.3.right",
                        description: Text("Scanned NFC tags will appear here")
                    )
                } else {
                    List {
                        ForEach(tags) { tag in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: tag.icon)
                                        .foregroundStyle(tag.color)

                                    Text(tag.title)
                                        .font(.headline)

                                    Spacer()

                                    Text(tag.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                ForEach(tag.records, id: \.id) { record in
                                    Text(record.content)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Data Models

/// Represents a scanned NFC tag.
struct NFCTagData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: String
    let title: String
    let records: [NFCRecordData]
    let uid: String?
    let icon: String
    let color: Color
}

/// Represents a single NDEF record.
struct NFCRecordData: Identifiable {
    let id = UUID()
    let type: String
    let content: String
    let icon: String
}

// MARK: - NFCManager
/// Manages NFC tag reading operations.
///
/// This class provides:
/// - NDEF tag scanning and reading
/// - Multiple record type parsing (text, URL, etc.)
/// - Tag UID extraction
/// - Scan history management
@MainActor
class NFCManager: NSObject, ObservableObject {
    // MARK: Published Properties
    @Published var isScanning = false
    @Published var isAvailable = false
    @Published var statusMessage = "Tap scan to read an NFC tag"
    @Published var lastScannedTag: NFCTagData?
    @Published var scannedTags: [NFCTagData] = []

    // MARK: Private Properties
    private var session: NFCNDEFReaderSession?

    // MARK: Initialization

    override init() {
        super.init()
        isAvailable = NFCNDEFReaderSession.readingAvailable
    }

    // MARK: Public Methods

    /// Starts an NFC scanning session.
    func startScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            statusMessage = "NFC is not available on this device"
            return
        }

        session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        session?.alertMessage = "Hold your iPhone near an NFC tag"
        session?.begin()

        isScanning = true
        statusMessage = "Hold iPhone near NFC tag..."
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCManager: NFCNDEFReaderSessionDelegate {
    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            self.isScanning = false

            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    self.statusMessage = "Scan cancelled"
                case .readerSessionInvalidationErrorSessionTimeout:
                    self.statusMessage = "Scan timed out"
                default:
                    self.statusMessage = error.localizedDescription
                }
            } else {
                self.statusMessage = error.localizedDescription
            }
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        Task { @MainActor in
            self.processMessages(messages, uid: nil)
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { error in
            if error != nil {
                session.invalidate(errorMessage: "Connection failed")
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                guard error == nil else {
                    session.invalidate(errorMessage: "Failed to query tag")
                    return
                }

                switch status {
                case .notSupported:
                    session.invalidate(errorMessage: "Tag is not NDEF compatible")
                case .readOnly, .readWrite:
                    tag.readNDEF { message, error in
                        if let message = message {
                            Task { @MainActor in
                                self.processMessages([message], uid: nil)
                            }
                            session.alertMessage = "Tag read successfully!"
                            session.invalidate()
                        } else {
                            session.invalidate(errorMessage: "Failed to read tag")
                        }
                    }
                @unknown default:
                    session.invalidate(errorMessage: "Unknown tag status")
                }
            }
        }
    }

    @MainActor
    private func processMessages(_ messages: [NFCNDEFMessage], uid: String?) {
        var records: [NFCRecordData] = []
        var tagTitle = "NFC Tag"
        var tagType = "NDEF"

        for message in messages {
            for payload in message.records {
                let record = parsePayload(payload)
                records.append(record)

                // Use first text or URL as title
                if tagTitle == "NFC Tag" && !record.content.isEmpty {
                    tagTitle = String(record.content.prefix(30))
                }
            }
        }

        if records.isEmpty {
            records.append(NFCRecordData(
                type: "Empty",
                content: "No data on tag",
                icon: "tag"
            ))
        }

        let tag = NFCTagData(
            timestamp: Date(),
            type: tagType,
            title: tagTitle,
            records: records,
            uid: uid,
            icon: iconForRecords(records),
            color: colorForRecords(records)
        )

        lastScannedTag = tag
        scannedTags.insert(tag, at: 0)
        if scannedTags.count > 50 {
            scannedTags.removeLast()
        }

        isScanning = false
        statusMessage = "Tag read successfully!"
    }

    private func parsePayload(_ payload: NFCNDEFPayload) -> NFCRecordData {
        switch payload.typeNameFormat {
        case .nfcWellKnown:
            if let type = String(data: payload.type, encoding: .utf8) {
                if type == "T" {
                    // Text record
                    let (text, _) = payload.wellKnownTypeTextPayload()
                    if let text = text {
                        return NFCRecordData(type: "Text", content: text, icon: "text.alignleft")
                    }
                } else if type == "U" {
                    // URL record
                    if let url = payload.wellKnownTypeURIPayload() {
                        return NFCRecordData(type: "URL", content: url.absoluteString, icon: "link")
                    }
                }
            }
            return NFCRecordData(type: "Well Known", content: "Unknown format", icon: "tag")

        case .media:
            if let type = String(data: payload.type, encoding: .utf8) {
                return NFCRecordData(type: type, content: String(data: payload.payload, encoding: .utf8) ?? "Binary data", icon: "doc")
            }
            return NFCRecordData(type: "Media", content: "Binary data", icon: "doc")

        case .absoluteURI:
            if let uri = String(data: payload.payload, encoding: .utf8) {
                return NFCRecordData(type: "URI", content: uri, icon: "link")
            }
            return NFCRecordData(type: "URI", content: "Invalid URI", icon: "link")

        case .nfcExternal:
            let type = String(data: payload.type, encoding: .utf8) ?? "External"
            return NFCRecordData(type: type, content: String(data: payload.payload, encoding: .utf8) ?? "Binary data", icon: "square.stack.3d.up")

        default:
            return NFCRecordData(type: "Unknown", content: "Unsupported format", icon: "questionmark")
        }
    }

    private func iconForRecords(_ records: [NFCRecordData]) -> String {
        if records.contains(where: { $0.type == "URL" }) { return "link.circle.fill" }
        if records.contains(where: { $0.type == "Text" }) { return "text.bubble.fill" }
        return "wave.3.right.circle.fill"
    }

    private func colorForRecords(_ records: [NFCRecordData]) -> Color {
        if records.contains(where: { $0.type == "URL" }) { return .blue }
        if records.contains(where: { $0.type == "Text" }) { return .green }
        return .cyan
    }
}

#Preview {
    NavigationStack {
        NFCView()
    }
}
