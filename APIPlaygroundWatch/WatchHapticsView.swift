import SwiftUI
import WatchKit

struct WatchHapticsView: View {
    @State private var lastPlayed: String?

    private let hapticTypes: [(name: String, type: WKHapticType, icon: String, color: Color)] = [
        ("Notification", .notification, "bell.fill", .blue),
        ("Direction Up", .directionUp, "arrow.up", .green),
        ("Direction Down", .directionDown, "arrow.down", .green),
        ("Success", .success, "checkmark.circle.fill", .green),
        ("Failure", .failure, "xmark.circle.fill", .red),
        ("Retry", .retry, "arrow.clockwise", .orange),
        ("Start", .start, "play.fill", .cyan),
        ("Stop", .stop, "stop.fill", .pink),
        ("Click", .click, "hand.tap.fill", .purple),
        ("Navigation Left", .navigationLeftTurn, "arrow.turn.up.left", .indigo),
        ("Navigation Right", .navigationRightTurn, "arrow.turn.up.right", .indigo)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Tap to feel haptics")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach(hapticTypes, id: \.name) { haptic in
                    Button {
                        playHaptic(haptic.type, name: haptic.name)
                    } label: {
                        HStack {
                            Image(systemName: haptic.icon)
                                .foregroundStyle(haptic.color)
                                .frame(width: 24)

                            Text(haptic.name)
                                .font(.caption)
                                .foregroundStyle(.primary)

                            Spacer()

                            if lastPlayed == haptic.name {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color(.darkGray).opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                // Play all button
                Button {
                    playAllHaptics()
                } label: {
                    HStack {
                        Image(systemName: "waveform")
                        Text("Play All")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.top, 8)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Haptics")
    }

    private func playHaptic(_ type: WKHapticType, name: String) {
        WKInterfaceDevice.current().play(type)
        withAnimation {
            lastPlayed = name
        }

        // Reset after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if lastPlayed == name {
                withAnimation {
                    lastPlayed = nil
                }
            }
        }
    }

    private func playAllHaptics() {
        for (index, haptic) in hapticTypes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                playHaptic(haptic.type, name: haptic.name)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WatchHapticsView()
    }
}
