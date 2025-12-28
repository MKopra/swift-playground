import SwiftUI
import VisionKit

// MARK: - DataScannerView
/// Comprehensive demonstration of VisionKit's DataScannerViewController.
///
/// Features:
/// - Text recognition (multiple languages)
/// - Barcode scanning (QR, EAN, UPC, Code128, etc.)
/// - Machine-readable codes
/// - Real-time scanning overlay
/// - Scan history with details
/// - Configurable recognition types
/// - Tap-to-focus and guidance
///
/// APIs Demonstrated:
/// - DataScannerViewController for camera-based scanning
/// - RecognizedItem for scanned content
/// - DataScannerViewController.RecognizedDataType
/// - VNBarcodeSymbology for barcode types
///
/// Note: Requires iOS 16+ and device with Neural Engine.
struct DataScannerDemoView: View {
    @StateObject private var scannerManager = DataScannerManager()
    @State private var isShowingScanner = false
    @State private var selectedDataTypes: Set<ScanDataType> = [.text, .barcode]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Card
                statusCard

                // Scan Configuration
                configurationCard

                // Scan Button
                scanButton

                // Scan Results
                if !scannerManager.scannedItems.isEmpty {
                    resultsCard
                }

                // Supported Barcodes
                supportedBarcodesCard

                // API Info
                apiInfoCard
            }
            .padding()
        }
        .navigationTitle("Data Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingScanner) {
            DataScannerSheet(
                manager: scannerManager,
                dataTypes: selectedDataTypes
            )
        }
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: scannerManager.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(scannerManager.isSupported ? .green : .red)
                    Text(scannerManager.isSupported ? "DataScanner Available" : "DataScanner Not Available")
                        .font(.headline)
                    Spacer()
                }

                if !scannerManager.isSupported {
                    Text("DataScanner requires iOS 16+ and a device with Neural Engine (A12 Bionic or later).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Scans")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(scannerManager.scannedItems.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Text Items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(scannerManager.scannedItems.filter { $0.type == .text }.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Barcodes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(scannerManager.scannedItems.filter { $0.type == .barcode }.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }
            }
        } label: {
            Label("Scanner Status", systemImage: "viewfinder")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                Text("Select what to scan:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(ScanDataType.allCases) { dataType in
                    Toggle(isOn: Binding(
                        get: { selectedDataTypes.contains(dataType) },
                        set: { isSelected in
                            if isSelected {
                                selectedDataTypes.insert(dataType)
                            } else if selectedDataTypes.count > 1 {
                                selectedDataTypes.remove(dataType)
                            }
                        }
                    )) {
                        HStack {
                            Image(systemName: dataType.icon)
                                .foregroundStyle(dataType.color)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text(dataType.title)
                                    .font(.subheadline)
                                Text(dataType.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                }
            }
        } label: {
            Label("Scan Configuration", systemImage: "gearshape")
        }
    }

    // MARK: - Scan Button
    private var scanButton: some View {
        Button(action: { isShowingScanner = true }) {
            HStack {
                Image(systemName: "camera.viewfinder")
                    .font(.title2)
                Text("Start Scanning")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(scannerManager.isSupported ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
        }
        .disabled(!scannerManager.isSupported)
    }

    // MARK: - Results Card
    private var resultsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Text("Scan History")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        scannerManager.clearItems()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }

                ForEach(scannerManager.scannedItems) { item in
                    DataScanResultRow(item: item)
                }
            }
        } label: {
            Label("Results", systemImage: "list.bullet.rectangle")
        }
    }

    // MARK: - Supported Barcodes Card
    private var supportedBarcodesCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Supported barcode symbologies:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(BarcodeType.allCases) { barcode in
                        HStack {
                            Image(systemName: "barcode")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(barcode.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } label: {
            Label("Barcode Types", systemImage: "barcode.viewfinder")
        }
    }

    // MARK: - API Info Card
    private var apiInfoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                DSAPIInfoRow(title: "Framework", value: "VisionKit")
                DSAPIInfoRow(title: "Min iOS", value: "16.0+")
                DSAPIInfoRow(title: "Hardware", value: "A12 Bionic+")
                DSAPIInfoRow(title: "Languages", value: "50+ supported")

                Divider()

                Text("DataScannerViewController uses the device camera with on-device ML to recognize text and barcodes in real-time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("API Information", systemImage: "info.circle")
        }
    }
}

// MARK: - ScanDataType
enum ScanDataType: String, CaseIterable, Identifiable {
    case text
    case barcode

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: return "Text"
        case .barcode: return "Barcodes"
        }
    }

    var description: String {
        switch self {
        case .text: return "Recognize printed and handwritten text"
        case .barcode: return "Scan QR codes, barcodes, and more"
        }
    }

    var icon: String {
        switch self {
        case .text: return "text.viewfinder"
        case .barcode: return "barcode.viewfinder"
        }
    }

    var color: Color {
        switch self {
        case .text: return .blue
        case .barcode: return .orange
        }
    }
}

// MARK: - BarcodeType
enum BarcodeType: String, CaseIterable, Identifiable {
    case qr = "QR Code"
    case ean13 = "EAN-13"
    case ean8 = "EAN-8"
    case upce = "UPC-E"
    case code39 = "Code 39"
    case code128 = "Code 128"
    case pdf417 = "PDF417"
    case aztec = "Aztec"
    case dataMatrix = "Data Matrix"
    case itf14 = "ITF-14"

    var id: String { rawValue }
}

// MARK: - DataScanResult
struct DataScanResult: Identifiable {
    let id = UUID()
    let type: ScanDataType
    let content: String
    let timestamp: Date
    let barcodeType: String?

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

// MARK: - DataScanResultRow
struct DataScanResultRow: View {
    let item: DataScanResult

    var body: some View {
        HStack {
            Image(systemName: item.type == .text ? "text.viewfinder" : "barcode")
                .foregroundStyle(item.type == .text ? .blue : .orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack {
                    Text(item.formattedTime)
                    if let barcodeType = item.barcodeType {
                        Text("(\(barcodeType))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {
                UIPasteboard.general.string = item.content
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - DSAPIInfoRow
struct DSAPIInfoRow: View {
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

// MARK: - DataScannerSheet
struct DataScannerSheet: View {
    @ObservedObject var manager: DataScannerManager
    let dataTypes: Set<ScanDataType>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                if manager.isSupported {
                    DSScannerRepresentable(
                        manager: manager,
                        recognizesText: dataTypes.contains(.text),
                        recognizesBarcodes: dataTypes.contains(.barcode)
                    )
                    .ignoresSafeArea()

                    // Scan overlay
                    VStack {
                        Spacer()

                        // Last scanned item
                        if let lastItem = manager.scannedItems.last {
                            HStack {
                                Image(systemName: lastItem.type == .text ? "text.viewfinder" : "barcode")
                                Text(lastItem.content)
                                    .lineLimit(1)
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding()
                        }

                        Text("Point camera at text or barcodes")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(.bottom, 40)
                    }
                } else {
                    ContentUnavailableView(
                        "Scanner Not Available",
                        systemImage: "viewfinder.trianglebadge.exclamationmark",
                        description: Text("This device does not support DataScanner")
                    )
                }
            }
            .navigationTitle("Scanning...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - DSScannerRepresentable
@available(iOS 16.0, *)
struct DSScannerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var manager: DataScannerManager
    let recognizesText: Bool
    let recognizesBarcodes: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        var recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> = []

        if recognizesText {
            recognizedDataTypes.insert(.text())
        }
        if recognizesBarcodes {
            recognizedDataTypes.insert(.barcode())
        }

        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        scanner.delegate = context.coordinator

        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(manager: manager)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let manager: DataScannerManager

        init(manager: DataScannerManager) {
            self.manager = manager
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            processItem(item)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                processItem(item)
            }
        }

        private func processItem(_ item: RecognizedItem) {
            Task { @MainActor in
                switch item {
                case .text(let text):
                    let result = DataScanResult(
                        type: .text,
                        content: text.transcript,
                        timestamp: Date(),
                        barcodeType: nil
                    )
                    // Avoid duplicates
                    if !manager.scannedItems.contains(where: { $0.content == result.content }) {
                        manager.scannedItems.insert(result, at: 0)
                    }

                case .barcode(let barcode):
                    if let payload = barcode.payloadStringValue {
                        let result = DataScanResult(
                            type: .barcode,
                            content: payload,
                            timestamp: Date(),
                            barcodeType: barcode.observation.symbology.rawValue
                        )
                        if !manager.scannedItems.contains(where: { $0.content == result.content }) {
                            manager.scannedItems.insert(result, at: 0)
                        }
                    }

                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - DataScannerManager
@MainActor
class DataScannerManager: ObservableObject {
    @Published var scannedItems: [DataScanResult] = []
    @Published var isSupported: Bool = false

    init() {
        checkSupport()
    }

    private func checkSupport() {
        if #available(iOS 16.0, *) {
            isSupported = DataScannerViewController.isSupported && DataScannerViewController.isAvailable
        } else {
            isSupported = false
        }
    }

    func clearItems() {
        scannedItems.removeAll()
    }
}

#Preview {
    NavigationStack {
        DataScannerDemoView()
    }
}
