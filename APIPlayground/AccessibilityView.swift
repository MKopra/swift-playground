import SwiftUI
import UIKit

struct AccessibilityView: View {
    @State private var accessibilitySettings = AccessibilitySettings()
    @State private var timer: Timer?

    var body: some View {
        List {
            Section("Visual") {
                AccessibilityRow(
                    icon: "eye",
                    label: "VoiceOver",
                    isEnabled: accessibilitySettings.isVoiceOverRunning,
                    description: "Screen reader for blind users"
                )

                AccessibilityRow(
                    icon: "bold",
                    label: "Bold Text",
                    isEnabled: accessibilitySettings.isBoldTextEnabled,
                    description: "Shows text in bold throughout the system"
                )

                AccessibilityRow(
                    icon: "circle.lefthalf.filled",
                    label: "Grayscale",
                    isEnabled: accessibilitySettings.isGrayscaleEnabled,
                    description: "Displays screen in grayscale"
                )

                AccessibilityRow(
                    icon: "textformat.size",
                    label: "Larger Text",
                    isEnabled: accessibilitySettings.isLargerTextEnabled,
                    description: "Uses larger accessibility text sizes"
                )

                AccessibilityRow(
                    icon: "rectangle.inset.filled",
                    label: "Button Shapes",
                    isEnabled: accessibilitySettings.isButtonShapesEnabled,
                    description: "Shows shapes under buttons"
                )

                AccessibilityRow(
                    icon: "circle.circle",
                    label: "Differentiate Without Color",
                    isEnabled: accessibilitySettings.isDifferentiateWithoutColorEnabled,
                    description: "Uses shapes in addition to color"
                )
            }

            Section("Motion") {
                AccessibilityRow(
                    icon: "figure.walk",
                    label: "Reduce Motion",
                    isEnabled: accessibilitySettings.isReduceMotionEnabled,
                    description: "Reduces screen movement"
                )

                AccessibilityRow(
                    icon: "sparkles",
                    label: "Prefer Cross-Fade",
                    isEnabled: accessibilitySettings.prefersCrossFadeTransitions,
                    description: "Uses cross-fade instead of slide transitions"
                )

                AccessibilityRow(
                    icon: "video",
                    label: "Auto-Play Video Previews",
                    isEnabled: accessibilitySettings.isVideoAutoplayEnabled,
                    description: "Automatically plays video previews"
                )
            }

            Section("Audio & Captions") {
                AccessibilityRow(
                    icon: "speaker.wave.2",
                    label: "Mono Audio",
                    isEnabled: accessibilitySettings.isMonoAudioEnabled,
                    description: "Combines audio channels"
                )

                AccessibilityRow(
                    icon: "captions.bubble",
                    label: "Closed Captions",
                    isEnabled: accessibilitySettings.isClosedCaptioningEnabled,
                    description: "Shows closed captions when available"
                )
            }

            Section("Interaction") {
                AccessibilityRow(
                    icon: "hand.tap",
                    label: "Switch Control",
                    isEnabled: accessibilitySettings.isSwitchControlRunning,
                    description: "Control device with external switches"
                )

                AccessibilityRow(
                    icon: "lock.display",
                    label: "Guided Access",
                    isEnabled: accessibilitySettings.isGuidedAccessEnabled,
                    description: "Restricts device to single app"
                )

                AccessibilityRow(
                    icon: "hand.raised",
                    label: "Shake to Undo",
                    isEnabled: accessibilitySettings.isShakeToUndoEnabled,
                    description: "Shake device to undo actions"
                )

                AccessibilityRow(
                    icon: "cursorarrow.click.2",
                    label: "Assistive Touch",
                    isEnabled: accessibilitySettings.isAssistiveTouchRunning,
                    description: "On-screen touch shortcuts"
                )
            }

            Section("Display") {
                AccessibilityRow(
                    icon: "circle.lefthalf.striped.horizontal.inverse",
                    label: "Invert Colors",
                    isEnabled: accessibilitySettings.isInvertColorsEnabled,
                    description: "Inverts display colors"
                )

                AccessibilityRow(
                    icon: "sun.max",
                    label: "Reduce Transparency",
                    isEnabled: accessibilitySettings.isReduceTransparencyEnabled,
                    description: "Reduces transparency effects"
                )

                AccessibilityRow(
                    icon: "moon",
                    label: "Darker System Colors",
                    isEnabled: accessibilitySettings.darkerSystemColorsEnabled,
                    description: "Uses darker colors throughout system"
                )
            }

            Section("Framework") {
                AccessibilityInfoRow(label: "Framework", value: "UIKit (UIAccessibility)")
                AccessibilityInfoRow(label: "Permissions", value: "None Required")
                AccessibilityInfoRow(label: "Updates", value: "Real-time via NotificationCenter")
            }
        }
        .navigationTitle("Accessibility")
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        accessibilitySettings = AccessibilitySettings()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            accessibilitySettings = AccessibilitySettings()
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}

struct AccessibilityRow: View {
    let icon: String
    let label: String
    let isEnabled: Bool
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isEnabled ? .green : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isEnabled ? .green : .secondary)
        }
    }
}

struct AccessibilityInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct AccessibilitySettings {
    // Visual
    let isVoiceOverRunning: Bool
    let isBoldTextEnabled: Bool
    let isGrayscaleEnabled: Bool
    let isLargerTextEnabled: Bool
    let isButtonShapesEnabled: Bool
    let isDifferentiateWithoutColorEnabled: Bool

    // Motion
    let isReduceMotionEnabled: Bool
    let prefersCrossFadeTransitions: Bool
    let isVideoAutoplayEnabled: Bool

    // Audio
    let isMonoAudioEnabled: Bool
    let isClosedCaptioningEnabled: Bool

    // Interaction
    let isSwitchControlRunning: Bool
    let isGuidedAccessEnabled: Bool
    let isShakeToUndoEnabled: Bool
    let isAssistiveTouchRunning: Bool

    // Display
    let isInvertColorsEnabled: Bool
    let isReduceTransparencyEnabled: Bool
    let darkerSystemColorsEnabled: Bool

    init() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        isGrayscaleEnabled = UIAccessibility.isGrayscaleEnabled
        // Check if current content size category is accessibility category
        let currentCategory = UIApplication.shared.preferredContentSizeCategory
        isLargerTextEnabled = currentCategory.isAccessibilityCategory
        isButtonShapesEnabled = UIAccessibility.buttonShapesEnabled
        isDifferentiateWithoutColorEnabled = UIAccessibility.shouldDifferentiateWithoutColor

        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        prefersCrossFadeTransitions = UIAccessibility.prefersCrossFadeTransitions
        isVideoAutoplayEnabled = UIAccessibility.isVideoAutoplayEnabled

        isMonoAudioEnabled = UIAccessibility.isMonoAudioEnabled
        isClosedCaptioningEnabled = UIAccessibility.isClosedCaptioningEnabled

        isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
        isGuidedAccessEnabled = UIAccessibility.isGuidedAccessEnabled
        isShakeToUndoEnabled = UIAccessibility.isShakeToUndoEnabled
        isAssistiveTouchRunning = UIAccessibility.isAssistiveTouchRunning

        isInvertColorsEnabled = UIAccessibility.isInvertColorsEnabled
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        darkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    }
}

#Preview {
    NavigationStack {
        AccessibilityView()
    }
}
