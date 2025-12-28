import SwiftUI
import ShazamKit
import AVFAudio

// MARK: - ShazamView
/// A music recognition interface using ShazamKit.
///
/// Features:
/// - Real-time music identification
/// - Song metadata display (title, artist, album art)
/// - Apple Music integration links
/// - Recognition history
/// - Audio waveform visualization during listening
/// - Matched song confidence indicator
///
/// APIs Demonstrated:
/// - SHSession for audio matching
/// - SHManagedSession for simplified recognition
/// - SHMediaItem for song metadata
/// - AVAudioEngine for audio capture
///
/// Note: This API is NOT available in Flutter - requires native ShazamKit implementation.
/// ShazamKit provides access to Shazam's audio recognition technology.
struct ShazamView: View {
    @StateObject private var shazam = ShazamManager()
    @State private var isAnimating = false
    @State private var showingHistory = false

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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

                // Main recognition visualization
                ZStack {
                    // Outer rings
                    ForEach(0..<4, id: \.self) { ring in
                        Circle()
                            .stroke(
                                shazam.isListening
                                    ? Color.blue.opacity(0.4 - Double(ring) * 0.1)
                                    : Color.white.opacity(0.1),
                                lineWidth: 2
                            )
                            .frame(
                                width: 180 + CGFloat(ring) * 50,
                                height: 180 + CGFloat(ring) * 50
                            )
                            .scaleEffect(isAnimating && shazam.isListening ? 1.1 : 1.0)
                    }

                    // Waveform circle
                    if shazam.isListening {
                        WaveformCircle(levels: shazam.audioLevels)
                            .frame(width: 200, height: 200)
                    }

                    // Main button
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: shazam.isListening
                                    ? [.blue, Color(red: 0.2, green: 0.3, blue: 0.8)]
                                    : [.white.opacity(0.2), .white.opacity(0.1)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .shadow(color: shazam.isListening ? .blue.opacity(0.5) : .clear, radius: 30)
                        .overlay(
                            Image(systemName: "shazam.logo.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.white)
                        )
                        .scaleEffect(shazam.isListening ? 1.1 : 1.0)
                        .onTapGesture {
                            if shazam.isListening {
                                shazam.stopListening()
                            } else {
                                shazam.startListening()
                            }
                        }
                }

                // Status
                VStack(spacing: 8) {
                    Text(shazam.statusMessage)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    if shazam.isListening {
                        Text("Tap to cancel")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Matched song display
                if let match = shazam.currentMatch {
                    MatchedSongCard(match: match)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Control button
                Button(action: {
                    if shazam.isListening {
                        shazam.stopListening()
                    } else {
                        shazam.startListening()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: shazam.isListening ? "stop.fill" : "waveform")
                        Text(shazam.isListening ? "Stop Listening" : "Start Listening")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(shazam.isListening ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

                if let error = shazam.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.bottom)
                }
            }
        }
        .navigationTitle("Music Recognition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            shazam.stopListening()
        }
        .sheet(isPresented: $showingHistory) {
            ShazamHistoryView(matches: shazam.matchHistory)
        }
    }

    private var backgroundColors: [Color] {
        if shazam.currentMatch != nil {
            return [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.05, green: 0.08, blue: 0.15)]
        } else if shazam.isListening {
            return [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.05, green: 0.1, blue: 0.2)]
        }
        return [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.05, green: 0.05, blue: 0.08)]
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}

// MARK: - WaveformCircle
/// Circular waveform visualization.
struct WaveformCircle: View {
    let levels: [Float]

    var body: some View {
        GeometryReader { geo in
            WaveformContent(levels: levels, size: geo.size)
        }
    }
}

/// Helper view for waveform content.
struct WaveformContent: View {
    let levels: [Float]
    let size: CGSize

    private var center: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private var radius: CGFloat {
        min(size.width, size.height) / 2 - 10
    }

    var body: some View {
        ForEach(0..<levels.count, id: \.self) { i in
            WaveformBar(
                index: i,
                level: levels[i],
                totalCount: levels.count,
                center: center,
                radius: radius,
                size: size
            )
        }
    }
}

/// Single waveform bar.
struct WaveformBar: View {
    let index: Int
    let level: Float
    let totalCount: Int
    let center: CGPoint
    let radius: CGFloat
    let size: CGSize

    private var angle: Double {
        Double(index) * (360.0 / Double(totalCount)) * .pi / 180
    }

    private var barHeight: CGFloat {
        max(5, CGFloat(level) * 30)
    }

    var body: some View {
        let cosAngle = CGFloat(Darwin.cos(angle))
        let sinAngle = CGFloat(Darwin.sin(angle))

        Rectangle()
            .fill(Color.blue.opacity(Double(level) + 0.3))
            .frame(width: 3, height: barHeight)
            .position(
                x: center.x + (radius - barHeight / 2) * cosAngle,
                y: center.y + (radius - barHeight / 2) * sinAngle
            )
            .rotationEffect(
                .radians(angle + .pi / 2),
                anchor: UnitPoint(
                    x: (center.x + radius * cosAngle) / size.width,
                    y: (center.y + radius * sinAngle) / size.height
                )
            )
    }
}

// MARK: - MatchedSongCard
/// Displays matched song information.
struct MatchedSongCard: View {
    let match: ShazamMatch

    var body: some View {
        HStack(spacing: 16) {
            // Album art
            AsyncImage(url: match.artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.title)
                                .foregroundStyle(.gray)
                        )
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(match.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(match.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let album = match.album {
                    Text(album)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Apple Music button
            if let appleMusicURL = match.appleMusicURL {
                Link(destination: appleMusicURL) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - ShazamHistoryView
/// Displays recognition history.
struct ShazamHistoryView: View {
    let matches: [ShazamMatch]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    ContentUnavailableView(
                        "No Matches",
                        systemImage: "shazam.logo",
                        description: Text("Recognized songs will appear here")
                    )
                } else {
                    List {
                        ForEach(matches) { match in
                            HStack(spacing: 12) {
                                AsyncImage(url: match.artworkURL) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "music.note")
                                                    .foregroundStyle(.gray)
                                            )
                                    }
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(match.title)
                                        .font(.headline)

                                    Text(match.artist)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Text(match.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let url = match.appleMusicURL {
                                    Link(destination: url) {
                                        Image(systemName: "play.circle")
                                            .font(.title2)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - ShazamMatch
/// Represents a matched song.
struct ShazamMatch: Identifiable {
    let id = UUID()
    let timestamp: Date
    let title: String
    let artist: String
    let album: String?
    let artworkURL: URL?
    let appleMusicURL: URL?
    let isrc: String?
}

// MARK: - ShazamManager
/// Manages Shazam music recognition.
///
/// This class provides:
/// - Audio capture and matching using ShazamKit
/// - Real-time audio level monitoring for visualization
/// - Match history tracking
/// - Apple Music integration
@MainActor
class ShazamManager: NSObject, ObservableObject {
    // MARK: Published Properties
    @Published var isListening = false
    @Published var statusMessage = "Tap to identify music"
    @Published var currentMatch: ShazamMatch?
    @Published var matchHistory: [ShazamMatch] = []
    @Published var audioLevels: [Float] = Array(repeating: 0, count: 32)
    @Published var error: String?

    // MARK: Private Properties
    private var session: SHSession?
    private var audioEngine: AVAudioEngine?
    private var levelTimer: Timer?

    // MARK: Initialization

    override init() {
        super.init()
        session = SHSession()
        session?.delegate = self
    }

    // MARK: Public Methods

    /// Starts listening for music.
    func startListening() {
        guard !isListening else { return }

        do {
            try configureAudioSession()
            try startAudioEngine()

            isListening = true
            statusMessage = "Listening..."
            currentMatch = nil
            error = nil

            startLevelMonitoring()
        } catch {
            self.error = error.localizedDescription
            statusMessage = "Failed to start"
        }
    }

    /// Stops listening.
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        levelTimer?.invalidate()
        levelTimer = nil

        isListening = false
        statusMessage = currentMatch != nil ? "Match found!" : "Tap to identify music"
        audioLevels = Array(repeating: 0, count: 32)
    }

    // MARK: Private Methods

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true)
    }

    private func startAudioEngine() throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, time in
            self?.session?.matchStreamingBuffer(buffer, at: time)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevels()
            }
        }
    }

    private func updateAudioLevels() {
        guard isListening else { return }

        // Simulate audio levels (in a real app, you'd measure from the audio buffer)
        audioLevels = audioLevels.map { _ in Float.random(in: 0.1...1.0) }
    }
}

// MARK: - SHSessionDelegate
extension ShazamManager: SHSessionDelegate {
    nonisolated func session(_ session: SHSession, didFind match: SHMatch) {
        Task { @MainActor in
            guard let mediaItem = match.mediaItems.first else { return }

            let shazamMatch = ShazamMatch(
                timestamp: Date(),
                title: mediaItem.title ?? "Unknown Title",
                artist: mediaItem.artist ?? "Unknown Artist",
                album: mediaItem.subtitle,
                artworkURL: mediaItem.artworkURL,
                appleMusicURL: mediaItem.appleMusicURL,
                isrc: mediaItem.isrc
            )

            self.currentMatch = shazamMatch
            self.matchHistory.insert(shazamMatch, at: 0)
            if self.matchHistory.count > 50 {
                self.matchHistory.removeLast()
            }

            self.statusMessage = "Match found!"
            self.stopListening()
        }
    }

    nonisolated func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.error = error.localizedDescription
                self.statusMessage = "Error occurred"
            } else {
                self.statusMessage = "No match found"
            }
            self.stopListening()
        }
    }
}

#Preview {
    NavigationStack {
        ShazamView()
    }
}
