import SwiftUI
import AVFoundation

// MARK: - TorchView
/// A comprehensive flashlight control interface with advanced features.
///
/// Features:
/// - Variable intensity control with smooth adjustment
/// - Multiple modes: constant, strobe, SOS
/// - Preset intensity levels
/// - Visual flashlight representation with glow effects
/// - Real-time intensity feedback
///
/// APIs Demonstrated:
/// - AVCaptureDevice for torch control
/// - Timer for strobe/SOS patterns
/// - Smooth intensity transitions
struct TorchView: View {
    @StateObject private var torch = TorchManager()
    @State private var rayRotation: Double = 0
    @State private var flickerOpacity: Double = 1.0
    @State private var selectedMode: TorchMode = .constant

    var body: some View {
        ZStack {
            // Dynamic background
            Color.black
                .ignoresSafeArea()

            // Light rays when on
            if torch.isOn && selectedMode == .constant {
                LightRays(intensity: torch.intensity)
                    .rotationEffect(.degrees(rayRotation))
                    .opacity(flickerOpacity)
            }

            VStack(spacing: 24) {
                Spacer()

                // Flashlight visualization
                ZStack {
                    // Glow effect
                    if torch.isOn {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .white.opacity(0.4 * torch.intensity),
                                        .yellow.opacity(0.2 * torch.intensity),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 180
                                )
                            )
                            .frame(width: 360, height: 360)
                            .blur(radius: 30)
                    }

                    // Flashlight body
                    FlashlightShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.4), Color(white: 0.2), Color(white: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 120, height: 200)
                        .shadow(color: .black.opacity(0.5), radius: 20)

                    // Lens
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: torch.isOn
                                    ? [.white, .yellow.opacity(0.8), .orange.opacity(0.3)]
                                    : [Color(white: 0.3), Color(white: 0.2)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .offset(y: -40)
                        .shadow(color: torch.isOn ? .yellow.opacity(0.8) : .clear, radius: torch.isOn ? 30 : 0)

                    // Lens reflections
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .offset(y: -40)

                    // Mode indicator
                    if torch.isOn && selectedMode != .constant {
                        Text(selectedMode.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.yellow)
                            .offset(y: -40)
                    }

                    // Power indicator
                    Circle()
                        .fill(torch.isOn ? Color.green : Color(white: 0.25))
                        .frame(width: 20, height: 20)
                        .offset(y: 50)
                        .shadow(color: torch.isOn ? .green : .clear, radius: 5)
                }

                // Status text
                VStack(spacing: 8) {
                    Text(torch.isOn ? "ON" : "OFF")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(torch.isOn ? .white : .gray)

                    if torch.isOn {
                        Text("\(Int(torch.intensity * 100))% Brightness")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                }

                // Mode selector
                Picker("Mode", selection: $selectedMode) {
                    ForEach(TorchMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                .onChange(of: selectedMode) { _, newMode in
                    torch.setMode(newMode)
                }

                // Intensity slider (only for constant mode)
                if selectedMode == .constant {
                    VStack(spacing: 12) {
                        Text("Intensity")
                            .font(.caption)
                            .foregroundStyle(.gray)

                        HStack(spacing: 16) {
                            Image(systemName: "sun.min")
                                .foregroundStyle(.gray)

                            Slider(value: $torch.intensity, in: 0.1...1.0) { editing in
                                if !editing && torch.isOn {
                                    torch.updateIntensity()
                                }
                            }
                            .tint(.yellow)
                            .disabled(!torch.isOn)

                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    .padding(.horizontal, 40)
                    .opacity(torch.isOn ? 1 : 0.5)

                    // Preset buttons
                    HStack(spacing: 16) {
                        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { level in
                            Button(action: {
                                torch.intensity = level
                                if torch.isOn {
                                    torch.updateIntensity()
                                }
                            }) {
                                Text("\(Int(level * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(width: 60, height: 36)
                                    .background(
                                        torch.intensity == level
                                            ? Color.yellow.opacity(0.3)
                                            : Color.white.opacity(0.1)
                                    )
                                    .foregroundStyle(torch.intensity == level ? .yellow : .white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(!torch.isOn)
                        }
                    }
                    .opacity(torch.isOn ? 1 : 0.5)
                } else {
                    // Mode description
                    VStack(spacing: 8) {
                        Text(selectedMode.description)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)

                        if selectedMode == .strobe {
                            HStack {
                                Text("Speed:")
                                Slider(value: $torch.strobeSpeed, in: 1...20, step: 1)
                                    .tint(.orange)
                                Text("\(Int(torch.strobeSpeed)) Hz")
                                    .monospacedDigit()
                            }
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()

                // Power button
                Button(action: {
                    if torch.isOn {
                        torch.turnOff()
                    } else {
                        torch.turnOn(mode: selectedMode)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(torch.isOn ? Color.red : Color.green)
                            .frame(width: 80, height: 80)
                            .shadow(color: (torch.isOn ? Color.red : Color.green).opacity(0.5), radius: 15)

                        Image(systemName: "power")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 40)

                if let error = torch.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Torch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            torch.turnOff()
        }
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            rayRotation = 360
        }
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            flickerOpacity = 0.95
        }
    }
}

// MARK: - TorchMode
/// Available torch operation modes.
enum TorchMode: String, CaseIterable, Identifiable {
    case constant = "Constant"
    case strobe = "Strobe"
    case sos = "SOS"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .constant: return "Steady light at selected intensity"
        case .strobe: return "Rapid flashing at adjustable speed"
        case .sos: return "International SOS Morse code pattern"
        }
    }
}

// MARK: - LightRays
/// Animated light ray effect for torch visualization.
struct LightRays: View {
    let intensity: Double

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.3 * intensity), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 8, height: 300)
                    .offset(y: -250)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
        .blur(radius: 10)
    }
}

// MARK: - FlashlightShape
/// Custom shape for flashlight body.
struct FlashlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let headWidth = rect.width
        let headHeight = rect.height * 0.35

        path.addRoundedRect(
            in: CGRect(x: 0, y: 0, width: headWidth, height: headHeight),
            cornerSize: CGSize(width: 10, height: 10)
        )

        let bodyWidth = rect.width * 0.7
        let bodyX = (rect.width - bodyWidth) / 2
        let bodyHeight = rect.height * 0.65

        path.addRoundedRect(
            in: CGRect(x: bodyX, y: headHeight - 5, width: bodyWidth, height: bodyHeight),
            cornerSize: CGSize(width: 8, height: 8)
        )

        return path
    }
}

// MARK: - TorchManager
/// Manages torch hardware and pattern playback.
///
/// This class provides:
/// - Basic on/off torch control
/// - Variable intensity adjustment
/// - Strobe mode with adjustable frequency
/// - SOS Morse code pattern
@MainActor
class TorchManager: ObservableObject {
    @Published var isOn = false
    @Published var intensity: Double = 1.0
    @Published var strobeSpeed: Double = 10.0
    @Published var error: String?

    private var device: AVCaptureDevice?
    private var strobeTimer: Timer?
    private var sosTimer: Timer?
    private var currentMode: TorchMode = .constant

    init() {
        device = AVCaptureDevice.default(for: .video)
    }

    /// Turns on the torch with the specified mode.
    func turnOn(mode: TorchMode = .constant) {
        currentMode = mode
        stopTimers()

        switch mode {
        case .constant:
            setTorch(on: true)
        case .strobe:
            startStrobe()
        case .sos:
            startSOS()
        }

        isOn = true
        error = nil
    }

    /// Turns off the torch.
    func turnOff() {
        stopTimers()
        setTorch(on: false)
        isOn = false
    }

    /// Sets the torch mode.
    func setMode(_ mode: TorchMode) {
        if isOn {
            turnOn(mode: mode)
        }
        currentMode = mode
    }

    /// Updates the torch intensity.
    func updateIntensity() {
        guard isOn, currentMode == .constant, let device = device else { return }

        do {
            try device.lockForConfiguration()
            try device.setTorchModeOn(level: Float(intensity))
            device.unlockForConfiguration()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: Private Methods

    private func setTorch(on: Bool) {
        guard let device = device, device.hasTorch else {
            error = "Torch not available"
            return
        }

        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: Float(intensity))
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func startStrobe() {
        let interval = 1.0 / strobeSpeed
        var isLit = false

        strobeTimer = Timer.scheduledTimer(withTimeInterval: interval / 2, repeats: true) { [weak self] _ in
            isLit.toggle()
            Task { @MainActor in
                self?.setTorch(on: isLit)
            }
        }
    }

    private func startSOS() {
        // SOS pattern: ... --- ...
        // . = short (0.2s), - = long (0.6s), gap between letters = 0.4s
        let pattern: [(Bool, TimeInterval)] = [
            // S: ...
            (true, 0.2), (false, 0.2),
            (true, 0.2), (false, 0.2),
            (true, 0.2), (false, 0.4),
            // O: ---
            (true, 0.6), (false, 0.2),
            (true, 0.6), (false, 0.2),
            (true, 0.6), (false, 0.4),
            // S: ...
            (true, 0.2), (false, 0.2),
            (true, 0.2), (false, 0.2),
            (true, 0.2), (false, 1.0) // Long pause before repeat
        ]

        var index = 0

        func playNext() {
            guard isOn else { return }
            let (on, duration) = pattern[index]
            setTorch(on: on)

            index = (index + 1) % pattern.count

            sosTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.playNextSOS()
                }
            }
        }

        playNext()
    }

    private func playNextSOS() {
        startSOS()
    }

    private func stopTimers() {
        strobeTimer?.invalidate()
        strobeTimer = nil
        sosTimer?.invalidate()
        sosTimer = nil
    }
}

#Preview {
    NavigationStack {
        TorchView()
    }
}
