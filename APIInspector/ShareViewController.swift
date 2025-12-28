import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Share Extension that inspects shared content
/// Uses UIViewController-based approach required for extensions
class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create SwiftUI view with extension context
        let contentView = ShareExtensionView(
            extensionContext: extensionContext,
            dismiss: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        )

        // Embed SwiftUI view
        let hostingController = UIHostingController(rootView: contentView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
}

// MARK: - SwiftUI View

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext?
    let dismiss: () -> Void

    @State private var sharedItems: [SharedItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Analyzing content...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if sharedItems.isEmpty {
                    ContentUnavailableView(
                        "No Content",
                        systemImage: "doc.questionmark",
                        description: Text("No inspectable content found")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(sharedItems) { item in
                                SharedItemCard(item: item)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("API Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadSharedContent()
        }
    }

    private func loadSharedContent() async {
        guard let extensionContext = extensionContext else {
            // For development/preview, show demo content
            await MainActor.run {
                sharedItems = [SharedItem.demoURL, SharedItem.demoText]
                isLoading = false
            }
            return
        }

        guard let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            await MainActor.run {
                errorMessage = "No input items found"
                isLoading = false
            }
            return
        }

        var items: [SharedItem] = []

        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }

            for attachment in attachments {
                if let item = await processAttachment(attachment) {
                    items.append(item)
                }
            }
        }

        await MainActor.run {
            sharedItems = items
            isLoading = false
        }
    }

    private func processAttachment(_ attachment: NSItemProvider) async -> SharedItem? {
        // Check for URL
        if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            do {
                let url = try await attachment.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL
                if let url = url {
                    return await inspectURL(url)
                }
            } catch {
                print("URL load error: \(error)")
            }
        }

        // Check for plain text
        if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            do {
                let text = try await attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String
                if let text = text {
                    return inspectText(text)
                }
            } catch {
                print("Text load error: \(error)")
            }
        }

        // Check for image
        if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            do {
                if let data = try await attachment.loadItem(forTypeIdentifier: UTType.image.identifier) as? Data,
                   let image = UIImage(data: data) {
                    return inspectImage(image, data: data)
                } else if let url = try await attachment.loadItem(forTypeIdentifier: UTType.image.identifier) as? URL,
                          let data = try? Data(contentsOf: url),
                          let image = UIImage(data: data) {
                    return inspectImage(image, data: data)
                }
            } catch {
                print("Image load error: \(error)")
            }
        }

        return nil
    }

    private func inspectURL(_ url: URL) async -> SharedItem {
        var details: [InspectionDetail] = [
            InspectionDetail(key: "URL", value: url.absoluteString),
            InspectionDetail(key: "Scheme", value: url.scheme ?? "None"),
            InspectionDetail(key: "Host", value: url.host ?? "None"),
            InspectionDetail(key: "Path", value: url.path.isEmpty ? "/" : url.path),
        ]

        if let query = url.query {
            details.append(InspectionDetail(key: "Query", value: query))

            // Parse query parameters
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                for item in queryItems.prefix(5) {
                    details.append(InspectionDetail(
                        key: "  \(item.name)",
                        value: item.value ?? "(empty)"
                    ))
                }
            }
        }

        // Try to fetch headers
        if url.scheme == "http" || url.scheme == "https" {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 5

                let startTime = Date()
                let (_, response) = try await URLSession.shared.data(for: request)
                let elapsed = Date().timeIntervalSince(startTime)

                if let httpResponse = response as? HTTPURLResponse {
                    details.append(InspectionDetail(key: "Status Code", value: "\(httpResponse.statusCode)"))
                    details.append(InspectionDetail(key: "Response Time", value: String(format: "%.0f ms", elapsed * 1000)))

                    if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                        details.append(InspectionDetail(key: "Content-Type", value: contentType))
                    }
                    if let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length") {
                        let bytes = Int(contentLength) ?? 0
                        details.append(InspectionDetail(key: "Content-Length", value: formatBytes(bytes)))
                    }
                    if let server = httpResponse.value(forHTTPHeaderField: "Server") {
                        details.append(InspectionDetail(key: "Server", value: server))
                    }
                }
            } catch {
                details.append(InspectionDetail(key: "Fetch Error", value: error.localizedDescription))
            }
        }

        return SharedItem(
            type: .url,
            title: url.host ?? "URL",
            icon: "link",
            details: details
        )
    }

    private func inspectText(_ text: String) -> SharedItem {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }

        // Estimate reading time (average 200 words per minute)
        let readingMinutes = Double(words.count) / 200.0
        let readingTime: String
        if readingMinutes < 1 {
            readingTime = "< 1 min"
        } else {
            readingTime = "\(Int(ceil(readingMinutes))) min"
        }

        // Detect if it might be code
        let codeIndicators = ["{", "}", "func ", "class ", "import ", "var ", "let ", "def ", "function"]
        let mightBeCode = codeIndicators.contains { text.contains($0) }

        // Check for URLs in text
        let urlPattern = try? NSRegularExpression(pattern: "https?://[^\\s]+", options: [])
        let urlMatches = urlPattern?.numberOfMatches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) ?? 0

        // Check for emails
        let emailPattern = try? NSRegularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: [.caseInsensitive])
        let emailMatches = emailPattern?.numberOfMatches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) ?? 0

        var details: [InspectionDetail] = [
            InspectionDetail(key: "Characters", value: "\(text.count)"),
            InspectionDetail(key: "Words", value: "\(words.count)"),
            InspectionDetail(key: "Sentences", value: "\(sentences.count)"),
            InspectionDetail(key: "Paragraphs", value: "\(paragraphs.count)"),
            InspectionDetail(key: "Reading Time", value: readingTime),
        ]

        if urlMatches > 0 {
            details.append(InspectionDetail(key: "URLs Found", value: "\(urlMatches)"))
        }
        if emailMatches > 0 {
            details.append(InspectionDetail(key: "Emails Found", value: "\(emailMatches)"))
        }
        if mightBeCode {
            details.append(InspectionDetail(key: "Type", value: "Likely Code"))
        }

        // Preview
        let preview = String(text.prefix(100)) + (text.count > 100 ? "..." : "")
        details.append(InspectionDetail(key: "Preview", value: preview))

        return SharedItem(
            type: .text,
            title: "Text (\(words.count) words)",
            icon: "doc.text",
            details: details
        )
    }

    private func inspectImage(_ image: UIImage, data: Data) -> SharedItem {
        var details: [InspectionDetail] = [
            InspectionDetail(key: "Dimensions", value: "\(Int(image.size.width)) x \(Int(image.size.height)) px"),
            InspectionDetail(key: "File Size", value: formatBytes(data.count)),
            InspectionDetail(key: "Scale", value: "\(Int(image.scale))x"),
        ]

        // Detect format from data
        let format: String
        if data.starts(with: [0xFF, 0xD8, 0xFF]) {
            format = "JPEG"
        } else if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            format = "PNG"
        } else if data.starts(with: [0x47, 0x49, 0x46]) {
            format = "GIF"
        } else if data.starts(with: [0x52, 0x49, 0x46, 0x46]) {
            format = "WebP"
        } else {
            format = "Unknown"
        }
        details.append(InspectionDetail(key: "Format", value: format))

        // Orientation
        let orientation: String
        switch image.imageOrientation {
        case .up: orientation = "Up (Normal)"
        case .down: orientation = "Down (180°)"
        case .left: orientation = "Left (90° CCW)"
        case .right: orientation = "Right (90° CW)"
        default: orientation = "Other"
        }
        details.append(InspectionDetail(key: "Orientation", value: orientation))

        // Megapixels
        let megapixels = (image.size.width * image.size.height) / 1_000_000
        details.append(InspectionDetail(key: "Megapixels", value: String(format: "%.1f MP", megapixels)))

        // Aspect ratio
        let gcd = greatestCommonDivisor(Int(image.size.width), Int(image.size.height))
        let aspectW = Int(image.size.width) / gcd
        let aspectH = Int(image.size.height) / gcd
        details.append(InspectionDetail(key: "Aspect Ratio", value: "\(aspectW):\(aspectH)"))

        return SharedItem(
            type: .image,
            title: "Image (\(format))",
            icon: "photo",
            details: details,
            thumbnail: image
        )
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        return b == 0 ? a : greatestCommonDivisor(b, a % b)
    }
}

// MARK: - Models

enum SharedItemType {
    case url, text, image
}

struct SharedItem: Identifiable {
    let id = UUID()
    let type: SharedItemType
    let title: String
    let icon: String
    let details: [InspectionDetail]
    var thumbnail: UIImage?

    static var demoURL: SharedItem {
        SharedItem(
            type: .url,
            title: "apple.com",
            icon: "link",
            details: [
                InspectionDetail(key: "URL", value: "https://www.apple.com"),
                InspectionDetail(key: "Scheme", value: "https"),
                InspectionDetail(key: "Host", value: "www.apple.com"),
                InspectionDetail(key: "Status Code", value: "200"),
                InspectionDetail(key: "Content-Type", value: "text/html"),
            ]
        )
    }

    static var demoText: SharedItem {
        SharedItem(
            type: .text,
            title: "Text (42 words)",
            icon: "doc.text",
            details: [
                InspectionDetail(key: "Characters", value: "256"),
                InspectionDetail(key: "Words", value: "42"),
                InspectionDetail(key: "Reading Time", value: "< 1 min"),
            ]
        )
    }
}

struct InspectionDetail: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

// MARK: - Views

struct SharedItemCard: View {
    let item: SharedItem

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 40)

                    Text(item.title)
                        .font(.headline)

                    Spacer()

                    // Type badge
                    Text(item.type == .url ? "URL" : item.type == .text ? "TEXT" : "IMAGE")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                }

                // Thumbnail for images
                if let thumbnail = item.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity)
                }

                Divider()

                // Details
                ForEach(item.details) { detail in
                    HStack(alignment: .top) {
                        Text(detail.key)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 100, alignment: .leading)

                        Text(detail.value)
                            .font(.subheadline)
                            .textSelection(.enabled)

                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Extension helpers

extension Data {
    func starts(with bytes: [UInt8]) -> Bool {
        guard count >= bytes.count else { return false }
        return prefix(bytes.count).elementsEqual(bytes)
    }
}

#Preview {
    ShareExtensionView(extensionContext: nil, dismiss: {})
}
