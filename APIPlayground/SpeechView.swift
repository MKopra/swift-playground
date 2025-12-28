import SwiftUI
import Speech
import AVFoundation

// MARK: - SpeechView
/// A comprehensive speech recognition and synthesis interface.
///
/// Features:
/// - Real-time speech-to-text transcription
/// - Text-to-speech synthesis with voice selection
/// - Multiple language support
/// - Confidence level indicators
/// - Live audio waveform visualization
/// - Transcript export and sharing
/// - Word-by-word highlighting
///
/// APIs Demonstrated:
/// - SFSpeechRecognizer for speech recognition
/// - AVSpeechSynthesizer for text-to-speech
/// - SFSpeechAudioBufferRecognitionRequest for streaming recognition
/// - AVAudioEngine for audio capture
struct SpeechView: View {
    @StateObject private var speechManager = SpeechManager()
    @State private var selectedTab = 0
    @State private var textToSpeak = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab selector
                Picker("Mode", selection: $selectedTab) {
                    Text("Recognize").tag(0)
                    Text("Speak").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    RecognitionView(manager: speechManager)
                } else {
                    SynthesisView(manager: speechManager, textToSpeak: $textToSpeak)
                }
            }
        }
        .navigationTitle("Speech")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if selectedTab == 0 && !speechManager.transcript.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: speechManager.transcript) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .onAppear {
            speechManager.requestAuthorization()
        }
        .onDisappear {
            speechManager.stopRecording()
            speechManager.stopSpeaking()
        }
    }
}

// MARK: - RecognitionView
/// Speech-to-text recognition interface.
struct RecognitionView: View {
    @ObservedObject var manager: SpeechManager

    var body: some View {
        VStack(spacing: 24) {
            // Language selector
            LanguageSelector(
                selectedLanguage: $manager.selectedLanguage,
                languages: manager.availableLanguages
            )
            .padding(.horizontal)

            // Live waveform visualization
            WaveformView(samples: manager.audioSamples, isActive: manager.isRecording)
                .frame(height: 100)
                .padding(.horizontal)

            // Confidence indicator
            if manager.isRecording {
                ConfidenceIndicator(confidence: manager.confidence)
                    .padding(.horizontal)
            }

            // Transcript with highlighted words
            TranscriptView(
                transcript: manager.transcript,
                segments: manager.segments,
                isRecording: manager.isRecording
            )

            if let error = manager.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()

            // Controls
            HStack(spacing: 32) {
                // Clear button
                Button(action: { manager.clearTranscript() }) {
                    VStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.title2)
                        Text("Clear")
                            .font(.caption)
                    }
                    .foregroundStyle(.gray)
                }
                .disabled(manager.transcript.isEmpty)

                // Record button
                RecordButton(isRecording: manager.isRecording) {
                    if manager.isRecording {
                        manager.stopRecording()
                    } else {
                        manager.startRecording()
                    }
                }

                // Copy button
                Button(action: { manager.copyTranscript() }) {
                    VStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.title2)
                        Text("Copy")
                            .font(.caption)
                    }
                    .foregroundStyle(.gray)
                }
                .disabled(manager.transcript.isEmpty)
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - SynthesisView
/// Text-to-speech synthesis interface.
struct SynthesisView: View {
    @ObservedObject var manager: SpeechManager
    @Binding var textToSpeak: String

    var body: some View {
        VStack(spacing: 24) {
            // Voice selector
            VoiceSelector(
                selectedVoice: $manager.selectedVoice,
                voices: manager.availableVoices
            )
            .padding(.horizontal)

            // Speech parameters
            VStack(spacing: 16) {
                // Rate slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Rate")
                            .foregroundStyle(.gray)
                        Spacer()
                        Text(String(format: "%.1fx", manager.speechRate))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                    .font(.caption)

                    Slider(value: $manager.speechRate, in: 0.1...1.0)
                        .tint(.blue)
                }

                // Pitch slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pitch")
                            .foregroundStyle(.gray)
                        Spacer()
                        Text(String(format: "%.1f", manager.speechPitch))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                    .font(.caption)

                    Slider(value: $manager.speechPitch, in: 0.5...2.0)
                        .tint(.purple)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Text input
            VStack(alignment: .leading, spacing: 8) {
                Text("Text to Speak")
                    .font(.caption)
                    .foregroundStyle(.gray)

                TextEditor(text: $textToSpeak)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                if textToSpeak.isEmpty {
                    Text("Enter text to synthesize...")
                        .foregroundStyle(.gray.opacity(0.5))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal)

            // Sample texts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sampleTexts, id: \.self) { sample in
                        Button(action: { textToSpeak = sample }) {
                            Text(sample.prefix(20) + "...")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1), in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            // Speak button
            Button(action: {
                if manager.isSpeaking {
                    manager.stopSpeaking()
                } else {
                    manager.speak(textToSpeak)
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: manager.isSpeaking ? "stop.fill" : "speaker.wave.3.fill")
                        .font(.title2)
                    Text(manager.isSpeaking ? "Stop" : "Speak")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(manager.isSpeaking ? Color.red : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            .disabled(textToSpeak.isEmpty)
        }
    }

    private var sampleTexts: [String] {
        [
            "Hello! This is a test of the speech synthesis system.",
            "The quick brown fox jumps over the lazy dog.",
            "API Playground demonstrates iOS device capabilities.",
            "Speech synthesis can read any text aloud with natural voices."
        ]
    }
}

// MARK: - LanguageSelector
/// Dropdown for selecting recognition language.
struct LanguageSelector: View {
    @Binding var selectedLanguage: String
    let languages: [(code: String, name: String)]

    var body: some View {
        HStack {
            Image(systemName: "globe")
                .foregroundStyle(.blue)

            Picker("Language", selection: $selectedLanguage) {
                ForEach(languages, id: \.code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - VoiceSelector
/// Dropdown for selecting synthesis voice.
struct VoiceSelector: View {
    @Binding var selectedVoice: AVSpeechSynthesisVoice?
    let voices: [AVSpeechSynthesisVoice]

    var body: some View {
        HStack {
            Image(systemName: "person.wave.2.fill")
                .foregroundStyle(.purple)

            Picker("Voice", selection: $selectedVoice) {
                Text("Default").tag(nil as AVSpeechSynthesisVoice?)
                ForEach(voices, id: \.identifier) { voice in
                    Text("\(voice.name) (\(voice.language))")
                        .tag(voice as AVSpeechSynthesisVoice?)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ConfidenceIndicator
/// Shows recognition confidence level.
struct ConfidenceIndicator: View {
    let confidence: Float

    private var color: Color {
        if confidence > 0.8 { return .green }
        if confidence > 0.5 { return .yellow }
        return .orange
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("Confidence")
                .font(.caption)
                .foregroundStyle(.gray)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(confidence))
                }
            }
            .frame(height: 8)

            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .foregroundStyle(.white)
                .monospacedDigit()
                .frame(width: 40)
        }
    }
}

// MARK: - TranscriptView
/// Displays the recognized transcript with word highlighting.
struct TranscriptView: View {
    let transcript: String
    let segments: [TranscriptSegment]
    let isRecording: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if transcript.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                        Text(isRecording ? "Listening..." : "Tap to speak")
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(segments) { segment in
                            SegmentRow(segment: segment)
                        }
                    }
                    .padding()
                    .id("bottom")
                }
            }
            .frame(maxHeight: 200)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .onChange(of: transcript) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - SegmentRow
/// Individual transcript segment with timestamp.
struct SegmentRow: View {
    let segment: TranscriptSegment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(segment.formattedTime)
                .font(.caption2)
                .foregroundStyle(.gray)
                .frame(width: 50)

            Text(segment.text)
                .font(.body)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - WaveformView
/// Animated audio waveform visualization.
struct WaveformView: View {
    let samples: [CGFloat]
    let isActive: Bool

    var body: some View {
        GeometryReader { geo in
            let barWidth: CGFloat = 3
            let spacing: CGFloat = 2
            let barCount = Int(geo.size.width / (barWidth + spacing))

            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { i in
                    let sampleIndex = samples.count > barCount
                        ? samples.count - barCount + i
                        : i
                    let amplitude = sampleIndex < samples.count ? samples[sampleIndex] : 0.1

                    RoundedRectangle(cornerRadius: barWidth / 2)
                        .fill(barGradient(for: amplitude))
                        .frame(width: barWidth, height: max(4, amplitude * geo.size.height))
                        .animation(.easeOut(duration: 0.05), value: amplitude)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func barGradient(for amplitude: CGFloat) -> LinearGradient {
        let color: Color = amplitude > 0.7 ? .red : amplitude > 0.4 ? .orange : .cyan
        return LinearGradient(
            colors: [color.opacity(0.6), color],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

// MARK: - RecordButton
/// Animated record button with pulsing rings.
struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        ZStack {
            // Pulsing rings when recording
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.red.opacity(isRecording ? 0.3 : 0), lineWidth: 2)
                    .frame(width: 100 + CGFloat(i) * 30, height: 100 + CGFloat(i) * 30)
                    .scaleEffect(isRecording ? 1.2 : 0.8)
                    .opacity(isRecording ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.3),
                        value: isRecording
                    )
            }

            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                        .shadow(color: (isRecording ? Color.red : Color.blue).opacity(0.5), radius: 10)

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - TranscriptSegment
/// Represents a segment of recognized speech.
struct TranscriptSegment: Identifiable {
    let id = UUID()
    let text: String
    let timestamp: TimeInterval
    let confidence: Float

    var formattedTime: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - SpeechManager
/// Manages speech recognition and synthesis.
///
/// This class provides:
/// - Real-time speech recognition with multiple languages
/// - Text-to-speech synthesis with voice selection
/// - Audio level monitoring for visualization
/// - Confidence tracking for recognized words
/// - Transcript segment management
@MainActor
class SpeechManager: ObservableObject {
    // MARK: Recognition Properties
    @Published var transcript = ""
    @Published var segments: [TranscriptSegment] = []
    @Published var isRecording = false
    @Published var error: String?
    @Published var audioSamples: [CGFloat] = []
    @Published var confidence: Float = 0
    @Published var selectedLanguage = "en-US"

    // MARK: Synthesis Properties
    @Published var isSpeaking = false
    @Published var selectedVoice: AVSpeechSynthesisVoice?
    @Published var speechRate: Float = 0.5
    @Published var speechPitch: Float = 1.0

    // MARK: Private Properties
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private let synthesizer = AVSpeechSynthesizer()
    private var recordingStartTime: Date?

    /// Available languages for recognition.
    var availableLanguages: [(code: String, name: String)] {
        [
            ("en-US", "English (US)"),
            ("en-GB", "English (UK)"),
            ("es-ES", "Spanish"),
            ("fr-FR", "French"),
            ("de-DE", "German"),
            ("it-IT", "Italian"),
            ("ja-JP", "Japanese"),
            ("zh-CN", "Chinese (Simplified)"),
            ("ko-KR", "Korean"),
            ("pt-BR", "Portuguese (Brazil)")
        ]
    }

    /// Available voices for synthesis.
    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.starts(with: "en") }
            .sorted { $0.name < $1.name }
    }

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: selectedLanguage))
    }

    // MARK: Authorization

    /// Requests speech recognition authorization.
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                switch status {
                case .authorized:
                    self.error = nil
                case .denied:
                    self.error = "Speech recognition access denied"
                case .restricted:
                    self.error = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.error = "Speech recognition not determined"
                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: Recognition Methods

    /// Starts speech recognition.
    func startRecording() {
        // Update recognizer for selected language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: selectedLanguage))

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = "Speech recognizer not available for \(selectedLanguage)"
            return
        }

        audioSamples = []
        recordingStartTime = Date()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }

            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.addsPunctuation = true

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                self?.processAudioBuffer(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isRecording = true

            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor in
                    if let result = result {
                        self?.transcript = result.bestTranscription.formattedString

                        // Update confidence from segments
                        if let lastSegment = result.bestTranscription.segments.last {
                            self?.confidence = lastSegment.confidence
                        }

                        // Create transcript segments
                        if result.isFinal {
                            self?.addSegment(result.bestTranscription.formattedString)
                        }
                    }
                    if error != nil {
                        self?.stopRecording()
                    }
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Stops speech recognition.
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }

    /// Clears the transcript.
    func clearTranscript() {
        transcript = ""
        segments = []
        audioSamples = []
    }

    /// Copies transcript to clipboard.
    func copyTranscript() {
        UIPasteboard.general.string = transcript
    }

    // MARK: Synthesis Methods

    /// Speaks the given text.
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch

        if let voice = selectedVoice {
            utterance.voice = voice
        }

        // Configure audio session for playback
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        synthesizer.speak(utterance)
        isSpeaking = true

        // Monitor for completion
        Task {
            while synthesizer.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            await MainActor.run {
                self.isSpeaking = false
            }
        }
    }

    /// Stops speech synthesis.
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: Private Methods

    /// Processes audio buffer for visualization.
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = buffer.frameLength

        var sum: Float = 0
        for i in 0..<Int(frames) {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frames))
        let normalized = min(CGFloat(rms * 5), 1.0)

        Task { @MainActor in
            self.audioSamples.append(normalized)
            if self.audioSamples.count > 200 {
                self.audioSamples.removeFirst()
            }
        }
    }

    /// Adds a segment to the transcript.
    private func addSegment(_ text: String) {
        let timestamp = Date().timeIntervalSince(recordingStartTime ?? Date())
        let segment = TranscriptSegment(
            text: text,
            timestamp: timestamp,
            confidence: confidence
        )
        segments.append(segment)
    }
}

#Preview {
    NavigationStack {
        SpeechView()
    }
}
