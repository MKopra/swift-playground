import AppIntents
import SwiftUI
import UIKit
import CoreMotion
import CoreLocation
import CoreImage.CIFilterBuiltins
import ActivityKit
import Darwin

// MARK: - Workout Live Activity Intent

/// Intent to log a completed set from the Live Activity
@available(iOS 16.2, *)
struct LogWorkoutSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Log Set"
    static var description = IntentDescription("Mark the current set as complete")

    func perform() async throws -> some IntentResult {
        if #available(iOS 16.1, *) {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                let currentState = activity.content.state
                let useRestTimer = activity.attributes.useRestTimer

                if !useRestTimer {
                    // No rest timer - just increment set
                    let newSet = currentState.currentSet + 1
                    if newSet > currentState.totalSets {
                        let finalState = WorkoutActivityAttributes.ContentState(
                            secondsRemaining: 0,
                            totalSeconds: currentState.totalSeconds,
                            currentSet: currentState.totalSets,
                            totalSets: currentState.totalSets,
                            exerciseName: currentState.exerciseName,
                            weight: currentState.weight,
                            reps: currentState.reps,
                            isResting: false,
                            restEndTime: nil
                        )
                        await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
                    } else {
                        let updatedState = WorkoutActivityAttributes.ContentState(
                            secondsRemaining: 0,
                            totalSeconds: currentState.totalSeconds,
                            currentSet: newSet,
                            totalSets: currentState.totalSets,
                            exerciseName: currentState.exerciseName,
                            weight: currentState.weight,
                            reps: currentState.reps,
                            isResting: false,
                            restEndTime: nil
                        )
                        await activity.update(ActivityContent(state: updatedState, staleDate: nil))
                    }
                } else if currentState.isResting {
                    // Currently resting - end rest, move to next set
                    let newSet = currentState.currentSet + 1
                    if newSet > currentState.totalSets {
                        let finalState = WorkoutActivityAttributes.ContentState(
                            secondsRemaining: 0,
                            totalSeconds: currentState.totalSeconds,
                            currentSet: currentState.totalSets,
                            totalSets: currentState.totalSets,
                            exerciseName: currentState.exerciseName,
                            weight: currentState.weight,
                            reps: currentState.reps,
                            isResting: false,
                            restEndTime: nil
                        )
                        await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
                    } else {
                        let updatedState = WorkoutActivityAttributes.ContentState(
                            secondsRemaining: 0,
                            totalSeconds: currentState.totalSeconds,
                            currentSet: newSet,
                            totalSets: currentState.totalSets,
                            exerciseName: currentState.exerciseName,
                            weight: currentState.weight,
                            reps: currentState.reps,
                            isResting: false,
                            restEndTime: nil
                        )
                        await activity.update(ActivityContent(state: updatedState, staleDate: nil))
                    }
                } else {
                    // Not resting - start rest timer
                    let restEndTime = Date().addingTimeInterval(TimeInterval(currentState.totalSeconds))
                    let updatedState = WorkoutActivityAttributes.ContentState(
                        secondsRemaining: currentState.totalSeconds,
                        totalSeconds: currentState.totalSeconds,
                        currentSet: currentState.currentSet,
                        totalSets: currentState.totalSets,
                        exerciseName: currentState.exerciseName,
                        weight: currentState.weight,
                        reps: currentState.reps,
                        isResting: true,
                        restEndTime: restEndTime
                    )
                    await activity.update(ActivityContent(state: updatedState, staleDate: nil))
                }
                break
            }
        }
        return .result()
    }
}

// MARK: - App Shortcuts Provider
/// Provides shortcuts that appear in the Shortcuts app
struct APIPlaygroundShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetSystemInfoIntent(),
            phrases: [
                "System info with \(.applicationName)",
                "CPU usage in \(.applicationName)",
                "RAM usage in \(.applicationName)",
                "Check system with \(.applicationName)"
            ],
            shortTitle: "System Info",
            systemImageName: "cpu"
        )

        AppShortcut(
            intent: GetDeviceStatusIntent(),
            phrases: [
                "Get device status with \(.applicationName)",
                "Check my device with \(.applicationName)",
                "Device info from \(.applicationName)"
            ],
            shortTitle: "Device Status",
            systemImageName: "iphone"
        )

        AppShortcut(
            intent: PlayHapticIntent(),
            phrases: [
                "Play haptic with \(.applicationName)",
                "Vibrate with \(.applicationName)",
                "Haptic feedback from \(.applicationName)"
            ],
            shortTitle: "Play Haptic",
            systemImageName: "waveform"
        )

        AppShortcut(
            intent: GenerateQRCodeIntent(),
            phrases: [
                "Generate QR code with \(.applicationName)",
                "Create QR code using \(.applicationName)",
                "Make QR code in \(.applicationName)"
            ],
            shortTitle: "Generate QR Code",
            systemImageName: "qrcode"
        )

        AppShortcut(
            intent: GetAltitudeIntent(),
            phrases: [
                "What's my altitude with \(.applicationName)",
                "Check altitude using \(.applicationName)",
                "Get elevation from \(.applicationName)"
            ],
            shortTitle: "Get Altitude",
            systemImageName: "mountain.2"
        )

        AppShortcut(
            intent: GenerateRandomColorIntent(),
            phrases: [
                "Generate random color with \(.applicationName)",
                "Random color from \(.applicationName)",
                "Pick a color using \(.applicationName)"
            ],
            shortTitle: "Random Color",
            systemImageName: "paintpalette"
        )

        AppShortcut(
            intent: ToggleTorchIntent(),
            phrases: [
                "Toggle flashlight with \(.applicationName)",
                "Turn on torch using \(.applicationName)",
                "Flashlight from \(.applicationName)"
            ],
            shortTitle: "Toggle Torch",
            systemImageName: "flashlight.on.fill"
        )

        AppShortcut(
            intent: CheckServicesStatusIntent(),
            phrases: [
                "3rd party status with \(.applicationName)",
                "Check services in \(.applicationName)",
                "Are my services up with \(.applicationName)"
            ],
            shortTitle: "3rd Party Status",
            systemImageName: "network"
        )
    }
}

// MARK: - Device Status Intent
/// Returns current device status including battery, storage, and network
struct GetDeviceStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Device Status"
    static var description = IntentDescription("Get current device battery, storage, and network status")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // Battery info
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = Int(UIDevice.current.batteryLevel * 100)
        let batteryState: String
        switch UIDevice.current.batteryState {
        case .charging: batteryState = "Charging"
        case .full: batteryState = "Full"
        case .unplugged: batteryState = "Unplugged"
        default: batteryState = "Unknown"
        }

        // Storage info
        let fileManager = FileManager.default
        var freeSpace = "Unknown"
        var totalSpace = "Unknown"
        if let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            if let free = attrs[.systemFreeSize] as? Int64 {
                freeSpace = ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
            }
            if let total = attrs[.systemSize] as? Int64 {
                totalSpace = ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
            }
        }

        // Device info
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion

        let status = """
        📱 \(deviceModel) (iOS \(systemVersion))
        🔋 Battery: \(batteryLevel)% (\(batteryState))
        💾 Storage: \(freeSpace) free of \(totalSpace)
        """

        return .result(
            value: status,
            dialog: IntentDialog(stringLiteral: status)
        )
    }
}

// MARK: - System Info Intent
/// Returns current CPU and RAM usage
struct GetSystemInfoIntent: AppIntent {
    static var title: LocalizedStringResource = "System Info"
    static var description = IntentDescription("Get current CPU and RAM usage")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
        let cpuUsage = Self.getCPUUsage()
        let (memUsed, memTotal) = Self.getMemoryUsage()

        let cpuPercent = Int(cpuUsage * 100)
        let memPercent = memTotal > 0 ? Int((Double(memUsed) / Double(memTotal)) * 100) : 0
        let memUsedGB = String(format: "%.1f", Double(memUsed) / 1_073_741_824)
        let memTotalGB = String(format: "%.0f", Double(memTotal) / 1_073_741_824)

        let status = "CPU: \(cpuPercent)% • RAM: \(memPercent)%"

        return .result(
            value: status,
            dialog: IntentDialog(stringLiteral: status),
            view: SystemInfoSnippetView(
                cpuPercent: cpuPercent,
                memPercent: memPercent,
                memUsedGB: memUsedGB,
                memTotalGB: memTotalGB
            )
        )
    }

    private static func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let err = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCpuInfo
        )

        guard err == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return 0.0
        }

        var totalUsage: Double = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
            let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)])
            let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])

            let total = user + system + nice + idle
            let used = user + system + nice

            if total > 0 {
                totalUsage += used / total
            }
        }

        let cpuInfoSize = vm_size_t(MemoryLayout<integer_t>.stride * Int(numCpuInfo))
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), cpuInfoSize)

        return totalUsage / Double(numCPUs)
    }

    private static func getMemoryUsage() -> (used: UInt64, total: UInt64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        let total = ProcessInfo.processInfo.physicalMemory

        guard result == KERN_SUCCESS else {
            return (0, total)
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize

        let used = active + wired + compressed

        return (used, total)
    }
}

// MARK: - Play Haptic Intent
/// Plays a haptic feedback pattern
struct PlayHapticIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Haptic"
    static var description = IntentDescription("Play a haptic feedback pattern on your device")

    @Parameter(title: "Pattern", default: .success)
    var pattern: HapticPattern

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let generator: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
        generator.prepare()

        await MainActor.run {
            switch pattern {
            case .success:
                generator.notificationOccurred(.success)
            case .warning:
                generator.notificationOccurred(.warning)
            case .error:
                generator.notificationOccurred(.error)
            case .light:
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            case .medium:
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            case .heavy:
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
        }

        return .result(dialog: "Played \(pattern.rawValue) haptic")
    }
}

enum HapticPattern: String, AppEnum {
    case success = "Success"
    case warning = "Warning"
    case error = "Error"
    case light = "Light Impact"
    case medium = "Medium Impact"
    case heavy = "Heavy Impact"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Haptic Pattern"

    static var caseDisplayRepresentations: [HapticPattern: DisplayRepresentation] = [
        .success: DisplayRepresentation(title: "Success", subtitle: "Positive feedback", image: .init(systemName: "checkmark.circle")),
        .warning: DisplayRepresentation(title: "Warning", subtitle: "Caution feedback", image: .init(systemName: "exclamationmark.triangle")),
        .error: DisplayRepresentation(title: "Error", subtitle: "Negative feedback", image: .init(systemName: "xmark.circle")),
        .light: DisplayRepresentation(title: "Light Impact", subtitle: "Subtle tap", image: .init(systemName: "hand.tap")),
        .medium: DisplayRepresentation(title: "Medium Impact", subtitle: "Standard tap", image: .init(systemName: "hand.tap.fill")),
        .heavy: DisplayRepresentation(title: "Heavy Impact", subtitle: "Strong tap", image: .init(systemName: "hand.point.up.left.fill")),
    ]
}

// MARK: - Generate QR Code Intent
/// Generates a QR code from text input
struct GenerateQRCodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Generate QR Code"
    static var description = IntentDescription("Create a QR code from text or URL")

    @Parameter(title: "Content")
    var content: String

    @Parameter(title: "Size", default: 256)
    var size: Int

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> & ProvidesDialog {
        guard let data = content.data(using: .utf8) else {
            throw GenerateQRError.invalidInput
        }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else {
            throw GenerateQRError.generationFailed
        }

        // Scale up the QR code
        let scale = CGFloat(size) / ciImage.extent.width
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            throw GenerateQRError.generationFailed
        }

        let uiImage = UIImage(cgImage: cgImage)

        guard let pngData = uiImage.pngData() else {
            throw GenerateQRError.generationFailed
        }

        let file = IntentFile(data: pngData, filename: "qrcode.png", type: .png)

        return .result(
            value: file,
            dialog: "Generated QR code for: \(content.prefix(30))\(content.count > 30 ? "..." : "")"
        )
    }
}

enum GenerateQRError: Error, CustomLocalizedStringResourceConvertible {
    case invalidInput
    case generationFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidInput: return "Invalid input text"
        case .generationFailed: return "Failed to generate QR code"
        }
    }
}

// MARK: - Get Altitude Intent
/// Returns current altitude using barometric pressure
struct GetAltitudeIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Altitude"
    static var description = IntentDescription("Get your current altitude and barometric pressure")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            throw AltitudeError.notAvailable
        }

        // Note: Getting real-time altitude requires the app to be running
        // For the shortcut, we report that the altimeter is available
        let result = """
        🏔️ Altimeter Available: Yes
        📍 To get real-time altitude readings, open the Altimeter demo in the app.
        """

        return .result(value: result, dialog: IntentDialog(stringLiteral: result))
    }
}

enum AltitudeError: Error, CustomLocalizedStringResourceConvertible {
    case notAvailable
    case noData

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAvailable: return "Altimeter not available on this device"
        case .noData: return "Could not read altitude data"
        }
    }
}

// MARK: - Generate Random Color Intent
/// Generates a random color with hex code
struct GenerateRandomColorIntent: AppIntent {
    static var title: LocalizedStringResource = "Generate Random Color"
    static var description = IntentDescription("Generate a random color and get its hex code")

    @Parameter(title: "Copy to Clipboard", default: true)
    var copyToClipboard: Bool

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let red = Int.random(in: 0...255)
        let green = Int.random(in: 0...255)
        let blue = Int.random(in: 0...255)

        let hex = String(format: "#%02X%02X%02X", red, green, blue)
        let rgb = "RGB(\(red), \(green), \(blue))"

        // Calculate relative luminance to determine if text should be light or dark
        let luminance = (0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)) / 255

        let colorName: String
        if luminance > 0.7 {
            colorName = "Light"
        } else if luminance < 0.3 {
            colorName = "Dark"
        } else {
            colorName = "Medium"
        }

        if copyToClipboard {
            await MainActor.run {
                UIPasteboard.general.string = hex
            }
        }

        let result = "🎨 \(hex)\n\(rgb)\n(\(colorName) color)"

        return .result(
            value: hex,
            dialog: IntentDialog(stringLiteral: copyToClipboard ? "\(result)\n\nCopied to clipboard!" : result)
        )
    }
}

// MARK: - Toggle Torch Intent
/// Toggles the device flashlight
struct ToggleTorchIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Torch"
    static var description = IntentDescription("Turn the device flashlight on or off")

    @Parameter(title: "State", default: .toggle)
    var state: TorchState

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            throw TorchError.notAvailable
        }

        do {
            try device.lockForConfiguration()

            let newState: Bool
            switch state {
            case .on:
                newState = true
            case .off:
                newState = false
            case .toggle:
                newState = !device.isTorchActive
            }

            if newState {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }

            device.unlockForConfiguration()

            return .result(dialog: "Torch is now \(newState ? "on 🔦" : "off")")
        } catch {
            throw TorchError.failed
        }
    }
}

import AVFoundation

enum TorchState: String, AppEnum {
    case on = "On"
    case off = "Off"
    case toggle = "Toggle"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Torch State"

    static var caseDisplayRepresentations: [TorchState: DisplayRepresentation] = [
        .on: DisplayRepresentation(title: "On", image: .init(systemName: "flashlight.on.fill")),
        .off: DisplayRepresentation(title: "Off", image: .init(systemName: "flashlight.off.fill")),
        .toggle: DisplayRepresentation(title: "Toggle", image: .init(systemName: "flashlight.on.fill")),
    ]
}

enum TorchError: Error, CustomLocalizedStringResourceConvertible {
    case notAvailable
    case failed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAvailable: return "Torch not available on this device"
        case .failed: return "Failed to control torch"
        }
    }
}

// MARK: - 3rd Party Status Intent
/// Checks the operational status of business services
struct CheckServicesStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "3rd Party Status"
    static var description = IntentDescription("Check status of business services like Mixpanel, Sentry, OpenAI, etc.")

    static var openAppWhenRun: Bool = false

    // Atlassian Statuspage services (base URL without endpoint)
    private static let statuspageServices: [(name: String, baseURL: String)] = [
        ("Mixpanel", "https://www.mixpanelstatus.com"),
        ("Sentry", "https://status.sentry.io"),
        ("OpenAI", "https://status.openai.com"),
        ("Claude", "https://status.anthropic.com"),
        ("RevenueCat", "https://status.revenuecat.com"),
        ("GitHub", "https://www.githubstatus.com")
    ]

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
        var serviceStatuses: [ServiceStatusData] = []

        // Fetch all services concurrently
        await withTaskGroup(of: (Int, ServiceStatusData).self) { group in
            for (index, service) in Self.statuspageServices.enumerated() {
                group.addTask {
                    let data = await self.fetchServiceData(name: service.name, baseURL: service.baseURL)
                    return (index, data)
                }
            }

            var indexedResults: [(Int, ServiceStatusData)] = []
            for await result in group {
                indexedResults.append(result)
            }
            serviceStatuses = indexedResults.sorted { $0.0 < $1.0 }.map { $0.1 }
        }

        // Add Postmark
        let postmarkData = await fetchPostmarkData()
        serviceStatuses.append(postmarkData)

        // Add Descope
        let descopeData = await fetchDescopeData()
        serviceStatuses.append(descopeData)

        let allOperational = serviceStatuses.allSatisfy { $0.currentStatus == .operational }
        let dialogText = allOperational ? "All systems operational" : "Some services have issues"

        return .result(
            value: dialogText,
            dialog: IntentDialog(stringLiteral: dialogText),
            view: ServiceStatusSnippetView(services: serviceStatuses)
        )
    }

    private func fetchServiceData(name: String, baseURL: String) async -> ServiceStatusData {
        let statusURL = "\(baseURL)/api/v2/status.json"
        let incidentsURL = "\(baseURL)/api/v2/incidents.json"

        // Fetch current status
        var currentStatus: ServiceStatus = .unknown
        if let url = URL(string: statusURL) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? [String: Any],
                   let indicator = status["indicator"] as? String {
                    currentStatus = ServiceStatus.from(indicator: indicator)
                }
            } catch {}
        }

        // Fetch incidents for last 30 days
        var dailyStatus = Array(repeating: ServiceStatus.operational, count: 30)
        if let url = URL(string: incidentsURL) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let incidents = json["incidents"] as? [[String: Any]] {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())

                    for incident in incidents {
                        guard let createdAt = incident["created_at"] as? String,
                              let impact = incident["impact"] as? String,
                              let date = ISO8601DateFormatter().date(from: createdAt) else { continue }

                        let incidentDay = calendar.startOfDay(for: date)
                        let daysAgo = calendar.dateComponents([.day], from: incidentDay, to: today).day ?? 0

                        if daysAgo >= 0 && daysAgo < 30 {
                            let index = 29 - daysAgo // 0 = 29 days ago, 29 = today
                            let incidentStatus = ServiceStatus.from(impact: impact)
                            // Keep the worst status for each day
                            if incidentStatus.severity > dailyStatus[index].severity {
                                dailyStatus[index] = incidentStatus
                            }
                        }
                    }
                }
            } catch {}
        }

        return ServiceStatusData(name: name, currentStatus: currentStatus, dailyStatus: dailyStatus)
    }

    private func fetchPostmarkData() async -> ServiceStatusData {
        var currentStatus: ServiceStatus = .unknown
        let dailyStatus = Array(repeating: ServiceStatus.operational, count: 30) // Postmark doesn't expose incident history easily

        if let url = URL(string: "https://status.postmarkapp.com/api/v1/status") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let page = json["page"] as? [String: Any],
                   let state = page["state"] as? String {
                    switch state.lowercased() {
                    case "operational": currentStatus = .operational
                    case "degraded": currentStatus = .minor
                    case "down": currentStatus = .critical
                    default: currentStatus = .unknown
                    }
                }
            } catch {}
        }

        return ServiceStatusData(name: "Postmark", currentStatus: currentStatus, dailyStatus: dailyStatus)
    }

    private func fetchDescopeData() async -> ServiceStatusData {
        var currentStatus: ServiceStatus = .unknown
        let dailyStatus = Array(repeating: ServiceStatus.operational, count: 30) // Instatus doesn't expose history in summary

        if let url = URL(string: "https://descope.instatus.com/summary.json") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let page = json["page"] as? [String: Any],
                   let status = page["status"] as? String {
                    switch status.uppercased() {
                    case "UP": currentStatus = .operational
                    case "HASISSUES": currentStatus = .major
                    case "UNDERMAINTENANCE": currentStatus = .minor
                    default: currentStatus = .unknown
                    }
                }
            } catch {}
        }

        return ServiceStatusData(name: "Descope", currentStatus: currentStatus, dailyStatus: dailyStatus)
    }
}

// MARK: - Service Status Data Models

enum ServiceStatus: Sendable {
    case operational
    case minor
    case major
    case critical
    case unknown

    var severity: Int {
        switch self {
        case .operational: return 0
        case .minor: return 1
        case .major: return 2
        case .critical: return 3
        case .unknown: return -1
        }
    }

    var color: Color {
        switch self {
        case .operational: return .green
        case .minor: return .yellow
        case .major: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
    }

    var label: String {
        switch self {
        case .operational: return "OK"
        case .minor: return "Minor"
        case .major: return "Major"
        case .critical: return "Down"
        case .unknown: return "?"
        }
    }

    static func from(indicator: String) -> ServiceStatus {
        switch indicator.lowercased() {
        case "none", "operational": return .operational
        case "minor", "degraded_performance": return .minor
        case "major", "partial_outage": return .major
        case "critical", "major_outage": return .critical
        default: return .unknown
        }
    }

    static func from(impact: String) -> ServiceStatus {
        switch impact.lowercased() {
        case "none": return .operational
        case "minor": return .minor
        case "major": return .major
        case "critical": return .critical
        default: return .minor
        }
    }
}

struct ServiceStatusData: Sendable {
    let name: String
    let currentStatus: ServiceStatus
    let dailyStatus: [ServiceStatus] // 30 days, index 0 = oldest, 29 = today
}

// MARK: - Service Status Snippet View

struct ServiceStatusSnippetView: View {
    let services: [ServiceStatusData]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(services, id: \.name) { service in
                ServiceStatusRow(service: service)
            }
        }
        .padding()
    }
}

struct ServiceStatusRow: View {
    let service: ServiceStatusData

    var body: some View {
        HStack(spacing: 8) {
            // Service name
            Text(service.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)

            // 30-day uptime bars
            HStack(spacing: 1) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(service.dailyStatus[index].color)
                        .frame(width: 4, height: 16)
                }
            }

            // Current status indicator with text
            HStack(spacing: 4) {
                Circle()
                    .fill(service.currentStatus.color)
                    .frame(width: 8, height: 8)
                Text(service.currentStatus.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(service.currentStatus.color)
            }
            .frame(width: 55, alignment: .leading)
        }
    }
}

// MARK: - System Info Snippet View

struct SystemInfoSnippetView: View {
    let cpuPercent: Int
    let memPercent: Int
    let memUsedGB: String
    let memTotalGB: String

    var body: some View {
        VStack(spacing: 16) {
            // CPU Row
            SystemMetricRow(
                icon: "cpu",
                label: "CPU",
                percent: cpuPercent,
                detail: "\(cpuPercent)%",
                color: cpuColor
            )

            // RAM Row
            SystemMetricRow(
                icon: "memorychip",
                label: "RAM",
                percent: memPercent,
                detail: "\(memUsedGB) / \(memTotalGB) GB",
                color: memColor
            )
        }
        .padding()
    }

    private var cpuColor: Color {
        if cpuPercent < 50 { return .green }
        if cpuPercent < 80 { return .yellow }
        return .red
    }

    private var memColor: Color {
        if memPercent < 60 { return .green }
        if memPercent < 85 { return .yellow }
        return .red
    }
}

struct SystemMetricRow: View {
    let icon: String
    let label: String
    let percent: Int
    let detail: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percent) / 100, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
