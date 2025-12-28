import AppIntents
import UIKit
import CoreMotion
import CoreLocation
import CoreImage.CIFilterBuiltins
import ActivityKit

// MARK: - Workout Live Activity Intent

/// Intent to log a completed set from the Live Activity
@available(iOS 16.2, *)
struct LogWorkoutSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Log Set"
    static var description = IntentDescription("Mark the current set as complete")

    func perform() async throws -> some IntentResult {
        // Find the active workout activity and update it
        if #available(iOS 16.1, *) {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                let currentState = activity.content.state
                let useRestTimer = activity.attributes.useRestTimer

                // Calculate new state
                let newSet = currentState.currentSet + (useRestTimer ? 0 : 1)
                let isResting = useRestTimer

                // Check if workout should end
                if newSet > currentState.totalSets && !useRestTimer {
                    // End the workout
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
                    await activity.end(
                        ActivityContent(state: finalState, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                } else {
                    // Calculate rest end time for auto-updating timer
                    let restEndTime: Date? = useRestTimer ? Date().addingTimeInterval(TimeInterval(currentState.totalSeconds)) : nil

                    // Update to resting or next set
                    let updatedState = WorkoutActivityAttributes.ContentState(
                        secondsRemaining: useRestTimer ? currentState.totalSeconds : 0,
                        totalSeconds: currentState.totalSeconds,
                        currentSet: useRestTimer ? currentState.currentSet : newSet,
                        totalSets: currentState.totalSets,
                        exerciseName: currentState.exerciseName,
                        weight: currentState.weight,
                        reps: currentState.reps,
                        isResting: isResting,
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
