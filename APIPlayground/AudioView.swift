import SwiftUI
import AVFoundation
import Accelerate

// MARK: - AudioView
/// A comprehensive audio monitoring, recording, and playback interface.
///
/// Features:
/// - Real-time audio level monitoring with circular spectrum
/// - Audio recording with waveform visualization
/// - Playback of recorded audio
/// - Recording management (save, delete, rename)
/// - Peak level tracking
/// - dB level display with descriptive labels
/// - Frequency band visualization (simulated)
///
/// APIs Demonstrated:
/// - AVAudioRecorder for audio recording
/// - AVAudioPlayer for audio playback
/// - AVAudioSession for audio configuration
/// - Audio metering for level monitoring
struct AudioView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var pulseScale: CGFloat = 1.0
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Dark gradient background
            RadialGradient(
                colors: [Color(white: 0.15), .black],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab selector
                Picker("Mode", selection: $selectedTab) {
                    Text("Monitor").tag(0)
                    Text("Record").tag(1)
                    Text("Library").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case 0:
                    MonitorView(manager: audioManager, pulseScale: $pulseScale)
                case 1:
                    RecorderView(manager: audioManager)
                case 2:
                    RecordingsLibraryView(manager: audioManager)
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle("Audio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            startPulseAnimation()
        }
        .onDisappear {
            audioManager.stop()
            audioManager.stopPlayback()
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }
}

// MARK: - MonitorView
/// Real-time audio level monitoring with spectrum visualization.
struct MonitorView: View {
    @ObservedObject var manager: AudioManager
    @Binding var pulseScale: CGFloat

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Circular spectrum analyzer
            ZStack {
                // Pulsing background rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(levelColor.opacity(0.1), lineWidth: 2)
                        .frame(width: 220 + CGFloat(ring) * 40, height: 220 + CGFloat(ring) * 40)
                        .scaleEffect(manager.isMonitoring ? (1.0 + manager.level * 0.1) : 1.0)
                        .animation(.easeOut(duration: 0.1), value: manager.level)
                }

                // Spectrum bars in a circle
                ForEach(0..<32, id: \.self) { i in
                    let barHeight = barHeightFor(index: i)
                    SpectrumBar(height: barHeight, color: barColorFor(height: barHeight))
                        .rotationEffect(.degrees(Double(i) * (360.0 / 32.0)))
                }

                // Inner glow circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [levelColor.opacity(0.3), levelColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseScale)

                // Center hub
                ZStack {
                    Circle()
                        .fill(Color(white: 0.1))
                        .frame(width: 100, height: 100)
                        .shadow(color: levelColor.opacity(0.5), radius: 20)

                    Circle()
                        .stroke(levelColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 100, height: 100)

                    // dB display
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f", manager.decibels))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text("dB")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .frame(height: 320)

            // Level description
            Text(levelDescription)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(levelColor)

            // Horizontal level meter
            LevelMeter(level: manager.level)
                .frame(height: 24)
                .padding(.horizontal, 32)

            // Peak level indicator
            HStack {
                Text("Peak:")
                    .foregroundStyle(.gray)
                Text(String(format: "%.1f dB", manager.peakDecibels))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Spacer()
                Button("Reset") {
                    manager.resetPeak()
                }
                .font(.caption)
                .foregroundStyle(.gray)
            }
            .font(.caption)
            .padding(.horizontal, 32)

            Spacer()

            // Control button
            Button(action: {
                if manager.isMonitoring {
                    manager.stop()
                } else {
                    manager.startMonitoring()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: manager.isMonitoring ? "stop.fill" : "mic.fill")
                        .font(.title2)
                    Text(manager.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(manager.isMonitoring ? Color.red : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            if let error = manager.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    private func barHeightFor(index: Int) -> CGFloat {
        guard manager.isMonitoring else { return 10 }
        let bandIndex = index % manager.frequencyBands.count
        return 10 + manager.frequencyBands[bandIndex] * 70
    }

    private func barColorFor(height: CGFloat) -> Color {
        let normalized = (height - 10) / 70
        if normalized > 0.7 { return .red }
        if normalized > 0.4 { return .orange }
        return .cyan
    }

    private var levelColor: Color {
        if manager.level > 0.8 { return .red }
        if manager.level > 0.5 { return .orange }
        if manager.level > 0.2 { return .yellow }
        return .green
    }

    private var levelDescription: String {
        if manager.decibels > -10 { return "VERY LOUD" }
        if manager.decibels > -25 { return "Loud" }
        if manager.decibels > -40 { return "Normal" }
        if manager.decibels > -55 { return "Quiet" }
        return "Silent"
    }
}

// MARK: - RecorderView
/// Audio recording interface with waveform display.
struct RecorderView: View {
    @ObservedObject var manager: AudioManager
    @State private var recordingName = ""
    @State private var showingSaveDialog = false

    var body: some View {
        VStack(spacing: 24) {
            // Recording indicator
            if manager.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .opacity(manager.isRecording ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: manager.isRecording)

                    Text("Recording")
                        .foregroundStyle(.red)
                        .fontWeight(.medium)

                    Spacer()

                    Text(manager.formattedDuration)
                        .font(.system(.title2, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding()
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            // Waveform visualization
            RecordingWaveform(samples: manager.recordingSamples, isRecording: manager.isRecording)
                .frame(height: 150)
                .padding(.horizontal)

            // Level indicator during recording
            if manager.isRecording {
                VStack(spacing: 8) {
                    LevelMeter(level: manager.level)
                        .frame(height: 20)

                    Text(String(format: "%.1f dB", manager.decibels))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // Playback controls (if recording exists)
            if manager.hasRecording && !manager.isRecording {
                VStack(spacing: 16) {
                    Text("Recording Complete")
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack(spacing: 24) {
                        // Play/Stop button
                        Button(action: {
                            if manager.isPlaying {
                                manager.stopPlayback()
                            } else {
                                manager.playRecording()
                            }
                        }) {
                            Image(systemName: manager.isPlaying ? "stop.fill" : "play.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(manager.isPlaying ? Color.red : Color.green, in: Circle())
                        }

                        // Save button
                        Button(action: { showingSaveDialog = true }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue, in: Circle())
                        }

                        // Delete button
                        Button(action: { manager.deleteCurrentRecording() }) {
                            Image(systemName: "trash")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.gray, in: Circle())
                        }
                    }

                    // Playback progress
                    if manager.isPlaying {
                        ProgressView(value: manager.playbackProgress)
                            .tint(.green)
                            .padding(.horizontal, 32)
                    }
                }
            }

            Spacer()

            // Record button
            Button(action: {
                if manager.isRecording {
                    manager.stopRecording()
                } else {
                    manager.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(manager.isRecording ? Color.white : Color.red)
                        .frame(width: 80, height: 80)

                    if manager.isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                    } else {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .shadow(color: .red.opacity(0.5), radius: 10)
            }
            .padding(.bottom, 32)

            if let error = manager.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .alert("Save Recording", isPresented: $showingSaveDialog) {
            TextField("Recording name", text: $recordingName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                manager.saveRecording(name: recordingName.isEmpty ? nil : recordingName)
                recordingName = ""
            }
        } message: {
            Text("Enter a name for your recording")
        }
    }
}

// MARK: - RecordingWaveform
/// Waveform visualization for recorded audio.
struct RecordingWaveform: View {
    let samples: [CGFloat]
    let isRecording: Bool

    var body: some View {
        GeometryReader { geo in
            let barWidth: CGFloat = 2
            let spacing: CGFloat = 1
            let maxBars = Int(geo.size.width / (barWidth + spacing))
            let displaySamples = samples.suffix(maxBars)

            HStack(spacing: spacing) {
                ForEach(Array(displaySamples.enumerated()), id: \.offset) { _, sample in
                    RoundedRectangle(cornerRadius: barWidth / 2)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .cyan],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: barWidth, height: max(2, sample * geo.size.height))
                }

                if samples.count < maxBars {
                    ForEach(0..<(maxBars - samples.count), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: barWidth / 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: barWidth, height: 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - RecordingsLibraryView
/// Library of saved recordings.
struct RecordingsLibraryView: View {
    @ObservedObject var manager: AudioManager

    var body: some View {
        VStack {
            if manager.savedRecordings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)
                    Text("No Recordings")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    Text("Record audio and save it to see it here")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(manager.savedRecordings) { recording in
                        RecordingRow(recording: recording, manager: manager)
                    }
                    .onDelete { indices in
                        indices.forEach { manager.deleteRecording(at: $0) }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}

// MARK: - RecordingRow
/// Row displaying a saved recording.
struct RecordingRow: View {
    let recording: SavedRecording
    @ObservedObject var manager: AudioManager

    var body: some View {
        HStack(spacing: 12) {
            // Play button
            Button(action: {
                if manager.playingRecordingId == recording.id {
                    manager.stopPlayback()
                } else {
                    manager.playSavedRecording(recording)
                }
            }) {
                Image(systemName: manager.playingRecordingId == recording.id ? "stop.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(manager.playingRecordingId == recording.id ? Color.red : Color.blue, in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.name)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Text(recording.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Text(recording.formattedDuration)
                .font(.caption)
                .foregroundStyle(.gray)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.white.opacity(0.05))
    }
}

// MARK: - LevelMeter
/// Horizontal audio level meter with gradient.
struct LevelMeter: View {
    let level: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))

                // Level fill with gradient
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * level)

                // Segment markers
                HStack(spacing: 0) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 1)
                        Spacer()
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - SpectrumBar
/// Individual bar in the circular spectrum analyzer.
struct SpectrumBar: View {
    let height: CGFloat
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.6), color],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 6, height: height)
            .offset(y: -85 - height / 2)
    }
}

// MARK: - SavedRecording
/// Represents a saved audio recording.
struct SavedRecording: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let duration: TimeInterval
    let date: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AudioManager
/// Manages audio monitoring, recording, and playback.
///
/// This class provides:
/// - Real-time audio level monitoring
/// - Audio recording with level visualization
/// - Playback of recorded audio
/// - Recording library management
/// - Frequency band simulation for visualization
@MainActor
class AudioManager: ObservableObject {
    // MARK: Monitoring Properties
    @Published var level: CGFloat = 0
    @Published var decibels: Float = -160
    @Published var peakDecibels: Float = -160
    @Published var isMonitoring = false
    @Published var frequencyBands: [CGFloat] = Array(repeating: 0, count: 8)

    // MARK: Recording Properties
    @Published var isRecording = false
    @Published var recordingSamples: [CGFloat] = []
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasRecording = false

    // MARK: Playback Properties
    @Published var isPlaying = false
    @Published var playbackProgress: Double = 0
    @Published var playingRecordingId: UUID?

    // MARK: Library Properties
    @Published var savedRecordings: [SavedRecording] = []

    // MARK: Error Handling
    @Published var error: String?

    // MARK: Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var recordingStartTime: Date?
    private var currentRecordingURL: URL?

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {
        loadSavedRecordings()
    }

    // MARK: Monitoring Methods

    /// Starts audio level monitoring.
    func startMonitoring() {
        configureAudioSession(forRecording: false)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("monitor.caf")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isMonitoring = true
            peakDecibels = -160

            startMeteringTimer()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Stops audio monitoring.
    func stop() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isMonitoring = false
        level = 0
        decibels = -160
        frequencyBands = Array(repeating: 0, count: 8)
    }

    /// Resets peak level tracking.
    func resetPeak() {
        peakDecibels = decibels
    }

    // MARK: Recording Methods

    /// Starts audio recording.
    func startRecording() {
        configureAudioSession(forRecording: true)

        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        currentRecordingURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: currentRecordingURL!, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            hasRecording = false
            recordingSamples = []
            recordingStartTime = Date()

            startMeteringTimer()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Stops recording.
    func stopRecording() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        hasRecording = currentRecordingURL != nil
        recordingDuration = Date().timeIntervalSince(recordingStartTime ?? Date())
    }

    /// Deletes the current unsaved recording.
    func deleteCurrentRecording() {
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        currentRecordingURL = nil
        hasRecording = false
        recordingSamples = []
    }

    /// Saves the current recording to the library.
    func saveRecording(name: String?) {
        guard let sourceURL = currentRecordingURL else { return }

        let recordingName = name ?? "Recording \(savedRecordings.count + 1)"
        let fileName = "\(UUID().uuidString).m4a"
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsDir.appendingPathComponent(fileName)

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            let recording = SavedRecording(
                name: recordingName,
                url: destinationURL,
                duration: recordingDuration,
                date: Date()
            )
            savedRecordings.insert(recording, at: 0)
            saveRecordingsMetadata()

            deleteCurrentRecording()
        } catch {
            self.error = "Failed to save recording"
        }
    }

    // MARK: Playback Methods

    /// Plays the current unsaved recording.
    func playRecording() {
        guard let url = currentRecordingURL else { return }
        playAudio(from: url, recordingId: nil)
    }

    /// Plays a saved recording from the library.
    func playSavedRecording(_ recording: SavedRecording) {
        playAudio(from: recording.url, recordingId: recording.id)
    }

    /// Stops audio playback.
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackProgress = 0
        playingRecordingId = nil
        timer?.invalidate()
    }

    /// Deletes a recording from the library.
    func deleteRecording(at index: Int) {
        let recording = savedRecordings[index]
        try? FileManager.default.removeItem(at: recording.url)
        savedRecordings.remove(at: index)
        saveRecordingsMetadata()
    }

    // MARK: Private Methods

    private func configureAudioSession(forRecording: Bool) {
        let session = AVAudioSession.sharedInstance()
        do {
            if forRecording {
                try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            } else {
                try session.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
            }
            try session.setActive(true)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func startMeteringTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMeters()
            }
        }
    }

    private func updateMeters() {
        audioRecorder?.updateMeters()
        let db = audioRecorder?.averagePower(forChannel: 0) ?? -160
        decibels = db

        if db > peakDecibels {
            peakDecibels = db
        }

        let minDb: Float = -60
        let clampedDb = max(minDb, min(db, 0))
        let normalized = (clampedDb - minDb) / (0 - minDb)
        level = CGFloat(normalized)

        // Update frequency bands (simulated)
        for i in 0..<8 {
            let baseValue = normalized * Float.random(in: 0.5...1.5)
            let smoothed = baseValue * 0.7 + Float(frequencyBands[i]) * 0.3
            frequencyBands[i] = CGFloat(min(1.0, max(0, smoothed)))
        }

        // Recording waveform samples
        if isRecording {
            recordingSamples.append(CGFloat(normalized))
            recordingDuration = Date().timeIntervalSince(recordingStartTime ?? Date())
        }
    }

    private func playAudio(from url: URL, recordingId: UUID?) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
            playingRecordingId = recordingId

            // Update playback progress
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self, let player = self.audioPlayer else {
                    timer.invalidate()
                    return
                }

                Task { @MainActor in
                    if player.isPlaying {
                        self.playbackProgress = player.currentTime / player.duration
                    } else {
                        self.stopPlayback()
                    }
                }
            }
        } catch {
            self.error = "Playback failed"
        }
    }

    private func loadSavedRecordings() {
        // In a real app, you'd load from persistent storage
        // For now, scan documents directory
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: [.creationDateKey])
            savedRecordings = files
                .filter { $0.pathExtension == "m4a" }
                .compactMap { url -> SavedRecording? in
                    guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                          let date = attrs[.creationDate] as? Date else { return nil }

                    // Get duration
                    let player = try? AVAudioPlayer(contentsOf: url)
                    let duration = player?.duration ?? 0

                    return SavedRecording(
                        name: url.deletingPathExtension().lastPathComponent,
                        url: url,
                        duration: duration,
                        date: date
                    )
                }
                .sorted { $0.date > $1.date }
        } catch {
            // Ignore errors
        }
    }

    private func saveRecordingsMetadata() {
        // In a production app, save metadata to UserDefaults or Core Data
    }
}

#Preview {
    NavigationStack {
        AudioView()
    }
}
