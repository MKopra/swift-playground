import SwiftUI
import VisionKit
import Vision

// MARK: - LiveTextView
/// A comprehensive live text and barcode scanning interface using VisionKit.
///
/// Features:
/// - Live camera text recognition
/// - Barcode and QR code scanning
/// - Multiple data type detection (text, URLs, emails, phone numbers)
/// - Copy to clipboard functionality
/// - Scan history with categorization
/// - Real-time overlay visualization
///
/// APIs Demonstrated:
/// - DataScannerViewController for live scanning
/// - VNRecognizedTextObservation for text detection
/// - Barcode symbology detection
/// - DataScannerViewController.RecognizedItem handling
///
/// Note: This API is NOT available in Flutter - requires native iOS 16+ implementation.
/// VisionKit's DataScanner provides system-level text recognition with privacy.
struct LiveTextView: View {
    @StateObject private var scanner = LiveTextScanner()
    @State private var selectedMode: ScanMode = .text
    @State private var showingHistory = false
    @State private var showingScanner = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.12, green: 0.12, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Mode selector
                Picker("Scan Mode", selection: $selectedMode) {
                    ForEach(ScanMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Scanner preview area
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(white: 0.15))
                        .frame(height: 300)

                    if showingScanner {
                        DataScannerRepresentable(
                            scanner: scanner,
                            mode: selectedMode
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: selectedMode.icon)
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)

                            Text("Tap Start to begin scanning")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if !scanner.isSupported {
                                Text("Live Text not supported on this device")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    // Scanning frame overlay
                    if showingScanner {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
                            .foregroundStyle(.cyan.opacity(0.5))
                            .padding(20)
                    }
                }
                .frame(height: 300)
                .padding(.horizontal)

                // Control buttons
                HStack(spacing: 16) {
                    Button(action: {
                        if showingScanner {
                            showingScanner = false
                            scanner.stopScanning()
                        } else {
                            showingScanner = true
                            scanner.startScanning(mode: selectedMode)
                        }
                    }) {
                        Label(
                            showingScanner ? "Stop" : "Start",
                            systemImage: showingScanner ? "stop.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(showingScanner ? Color.red : Color.cyan)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!scanner.isSupported)

                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

                // Recent scans
                if !scanner.recentItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Scans")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal)

                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(scanner.recentItems.prefix(5)) { item in
                                    ScannedItemRow(item: item) {
                                        UIPasteboard.general.string = item.content
                                        scanner.statusMessage = "Copied to clipboard!"
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .frame(maxHeight: 250)
                }

                Spacer()

                // Status message
                if !scanner.statusMessage.isEmpty {
                    Text(scanner.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.bottom)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Live Text")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: selectedMode) { _, newMode in
            if showingScanner {
                scanner.startScanning(mode: newMode)
            }
        }
        .sheet(isPresented: $showingHistory) {
            ScanHistoryView(items: scanner.recentItems)
        }
    }
}

// MARK: - ScanMode
/// Available scanning modes.
enum ScanMode: String, CaseIterable, Identifiable {
    case text = "Text"
    case barcode = "Barcode"
    case all = "All"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .text: return "text.viewfinder"
        case .barcode: return "barcode.viewfinder"
        case .all: return "viewfinder"
        }
    }
}

// MARK: - ScannedItemRow
/// Row displaying a scanned item.
struct ScannedItemRow: View {
    let item: ScannedItem
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundStyle(item.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(item.content)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.cyan)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - ScanHistoryView
/// Full scan history view.
struct ScanHistoryView: View {
    let items: [ScannedItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Scans",
                        systemImage: "text.viewfinder",
                        description: Text("Scanned items will appear here")
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: item.icon)
                                        .foregroundStyle(item.color)

                                    Text(item.type)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Text(item.content)
                                    .font(.subheadline)

                                if item.isActionable {
                                    Button(action: { openItem(item) }) {
                                        Text(item.actionLabel)
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                            .padding(.vertical, 4)
                            .contextMenu {
                                Button(action: {
                                    UIPasteboard.general.string = item.content
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }

                                if item.isActionable {
                                    Button(action: { openItem(item) }) {
                                        Label(item.actionLabel, systemImage: item.actionIcon)
                                    }
                                }
                            }
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

    private func openItem(_ item: ScannedItem) {
        guard let url = item.actionURL else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - DataScannerRepresentable
/// SwiftUI wrapper for DataScannerViewController.
struct DataScannerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var scanner: LiveTextScanner
    let mode: ScanMode

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>

        switch mode {
        case .text:
            recognizedDataTypes = [.text()]
        case .barcode:
            recognizedDataTypes = [.barcode()]
        case .all:
            recognizedDataTypes = [.text(), .barcode()]
        }

        let controller = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Update if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scanner: scanner)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let scanner: LiveTextScanner

        init(scanner: LiveTextScanner) {
            self.scanner = scanner
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            Task { @MainActor in
                switch item {
                case .text(let text):
                    scanner.addItem(content: text.transcript, type: .text)
                case .barcode(let barcode):
                    if let value = barcode.payloadStringValue {
                        scanner.addItem(content: value, type: .barcode(barcode.observation.symbology))
                    }
                @unknown default:
                    break
                }
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Items detected - could show count
            Task { @MainActor in
                scanner.statusMessage = "\(allItems.count) items detected"
            }
        }
    }
}

// MARK: - ScannedItem
/// Represents a scanned item.
struct ScannedItem: Identifiable {
    let id = UUID()
    let timestamp: Date
    let content: String
    let type: String
    let icon: String
    let color: Color
    let isActionable: Bool
    let actionLabel: String
    let actionIcon: String
    let actionURL: URL?
}

// MARK: - ScannedItemType
/// Type of scanned content.
enum ScannedItemType {
    case text
    case barcode(VNBarcodeSymbology)
    case url
    case email
    case phone
}

// MARK: - LiveTextScanner
/// Manages live text scanning operations.
///
/// This class provides:
/// - DataScannerViewController management
/// - Item detection and categorization
/// - History tracking
/// - Clipboard operations
@MainActor
class LiveTextScanner: ObservableObject {
    // MARK: Published Properties
    @Published var isScanning = false
    @Published var isSupported = false
    @Published var statusMessage = ""
    @Published var recentItems: [ScannedItem] = []

    // MARK: Private Properties
    private var scannerController: DataScannerViewController?

    // MARK: Initialization

    init() {
        isSupported = DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    // MARK: Public Methods

    /// Starts scanning with the specified mode.
    func startScanning(mode: ScanMode) {
        isScanning = true
        statusMessage = "Point camera at \(mode.rawValue.lowercased())..."
    }

    /// Stops the current scanning session.
    func stopScanning() {
        isScanning = false
        statusMessage = ""
    }

    /// Adds a recognized item to the history.
    func addItem(content: String, type: ScannedItemType) {
        let item = createItem(content: content, type: type)
        recentItems.insert(item, at: 0)
        if recentItems.count > 100 {
            recentItems.removeLast()
        }
        statusMessage = "Item added: \(item.type)"
    }

    // MARK: Private Methods

    private func createItem(content: String, type: ScannedItemType) -> ScannedItem {
        // Detect content type
        let detectedType = detectContentType(content)

        switch detectedType {
        case .url:
            return ScannedItem(
                timestamp: Date(),
                content: content,
                type: "URL",
                icon: "link",
                color: .blue,
                isActionable: true,
                actionLabel: "Open",
                actionIcon: "safari",
                actionURL: URL(string: content)
            )

        case .email:
            return ScannedItem(
                timestamp: Date(),
                content: content,
                type: "Email",
                icon: "envelope.fill",
                color: .orange,
                isActionable: true,
                actionLabel: "Email",
                actionIcon: "envelope",
                actionURL: URL(string: "mailto:\(content)")
            )

        case .phone:
            let cleaned = content.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            return ScannedItem(
                timestamp: Date(),
                content: content,
                type: "Phone",
                icon: "phone.fill",
                color: .green,
                isActionable: true,
                actionLabel: "Call",
                actionIcon: "phone",
                actionURL: URL(string: "tel:\(cleaned)")
            )

        case .barcode(let symbology):
            let symbologyName = symbologyDisplayName(symbology)
            return ScannedItem(
                timestamp: Date(),
                content: content,
                type: symbologyName,
                icon: "barcode",
                color: .purple,
                isActionable: content.hasPrefix("http"),
                actionLabel: "Open",
                actionIcon: "safari",
                actionURL: content.hasPrefix("http") ? URL(string: content) : nil
            )

        default:
            return ScannedItem(
                timestamp: Date(),
                content: content,
                type: "Text",
                icon: "text.alignleft",
                color: .cyan,
                isActionable: false,
                actionLabel: "",
                actionIcon: "",
                actionURL: nil
            )
        }
    }

    private func detectContentType(_ content: String) -> ScannedItemType {
        // URL detection
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return .url
        }

        // Email detection
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        if content.range(of: emailRegex, options: .regularExpression) != nil {
            return .email
        }

        // Phone detection
        let phoneRegex = "^[+]?[(]?[0-9]{1,4}[)]?[-\\s./0-9]{6,}$"
        if content.range(of: phoneRegex, options: .regularExpression) != nil {
            return .phone
        }

        return .text
    }

    private func symbologyDisplayName(_ symbology: VNBarcodeSymbology) -> String {
        switch symbology {
        case .qr: return "QR Code"
        case .ean8: return "EAN-8"
        case .ean13: return "EAN-13"
        case .upce: return "UPC-E"
        case .code39: return "Code 39"
        case .code128: return "Code 128"
        case .pdf417: return "PDF417"
        case .aztec: return "Aztec"
        case .dataMatrix: return "Data Matrix"
        default: return "Barcode"
        }
    }
}

#Preview {
    NavigationStack {
        LiveTextView()
    }
}
