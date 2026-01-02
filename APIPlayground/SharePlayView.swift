import SwiftUI
import GroupActivities
import Combine

// MARK: - SharePlay Demo View

struct SharePlayView: View {
    @StateObject private var sharePlayManager = SharePlayManager()
    @State private var selectedDemo: SharePlayDemo = .counter

    enum SharePlayDemo: String, CaseIterable {
        case counter = "Synced Counter"
        case drawing = "Collaborative Drawing"
        case emoji = "Emoji Reactions"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session Status
                sessionStatusCard

                // Demo Picker
                demoPicker

                // Demo Content
                switch selectedDemo {
                case .counter:
                    counterDemo
                case .drawing:
                    drawingDemo
                case .emoji:
                    emojiDemo
                }

                // Participants
                if sharePlayManager.isInSession {
                    participantsSection
                }

                // Message Log
                messageLogSection

                // How It Works
                howItWorksSection
            }
            .padding()
        }
        .navigationTitle("SharePlay")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await sharePlayManager.startObserving()
        }
    }

    // MARK: - Session Status Card

    private var sessionStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: sharePlayManager.isInSession ? "shareplay" : "shareplay.slash")
                    .font(.title)
                    .foregroundStyle(sharePlayManager.isInSession ? .green : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(sharePlayManager.isInSession ? "SharePlay Active" : "Not in SharePlay")
                        .font(.headline)
                    Text(sharePlayManager.isInSession ? "\(sharePlayManager.participantCount) participant(s)" : "Start a FaceTime call to use SharePlay")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if sharePlayManager.isInSession {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(.green.opacity(0.3), lineWidth: 4)
                        )
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                if !sharePlayManager.isInSession {
                    Button {
                        Task {
                            await sharePlayManager.startActivity()
                        }
                    } label: {
                        Label("Start SharePlay", systemImage: "shareplay")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                } else {
                    Button {
                        sharePlayManager.endSession()
                    } label: {
                        Label("End Session", systemImage: "xmark.circle")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            if !sharePlayManager.isInSession {
                Text("Note: SharePlay requires an active FaceTime call or Messages conversation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Demo Picker

    private var demoPicker: some View {
        Picker("Demo", selection: $selectedDemo) {
            ForEach(SharePlayDemo.allCases, id: \.self) { demo in
                Text(demo.rawValue).tag(demo)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Counter Demo

    private var counterDemo: some View {
        VStack(spacing: 24) {
            Text("Synced Counter")
                .font(.headline)

            Text("\(sharePlayManager.counterValue)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: sharePlayManager.counterValue)

            HStack(spacing: 20) {
                Button {
                    sharePlayManager.decrementCounter()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                }

                Button {
                    sharePlayManager.resetCounter()
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }

                Button {
                    sharePlayManager.incrementCounter()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                }
            }

            Text("All participants see the same number in real-time")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Drawing Demo

    private var drawingDemo: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Collaborative Canvas")
                    .font(.headline)
                Spacer()
                Button {
                    sharePlayManager.clearCanvas()
                } label: {
                    Text("Clear")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }

            // Color picker
            HStack(spacing: 12) {
                ForEach([Color.red, .orange, .yellow, .green, .blue, .purple, .black], id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(.primary, lineWidth: sharePlayManager.selectedColor == color ? 3 : 0)
                        )
                        .onTapGesture {
                            sharePlayManager.selectedColor = color
                        }
                }
            }

            // Canvas
            ZStack {
                Rectangle()
                    .fill(Color(.systemBackground))
                    .frame(height: 250)

                Canvas { context, size in
                    for stroke in sharePlayManager.canvasStrokes {
                        var path = Path()
                        guard let first = stroke.points.first else { continue }
                        path.move(to: first)
                        for point in stroke.points.dropFirst() {
                            path.addLine(to: point)
                        }
                        context.stroke(path, with: .color(stroke.color), lineWidth: 3)
                    }

                    // Current stroke
                    if !sharePlayManager.currentStroke.isEmpty {
                        var path = Path()
                        path.move(to: sharePlayManager.currentStroke[0])
                        for point in sharePlayManager.currentStroke.dropFirst() {
                            path.addLine(to: point)
                        }
                        context.stroke(path, with: .color(sharePlayManager.selectedColor), lineWidth: 3)
                    }
                }
                .frame(height: 250)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            sharePlayManager.currentStroke.append(value.location)
                        }
                        .onEnded { _ in
                            sharePlayManager.finishStroke()
                        }
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            )

            Text("Draw together in real-time")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Emoji Demo

    private var emojiDemo: some View {
        VStack(spacing: 16) {
            Text("Emoji Reactions")
                .font(.headline)

            // Floating emojis display
            ZStack {
                ForEach(sharePlayManager.floatingEmojis) { emoji in
                    Text(emoji.emoji)
                        .font(.system(size: 40))
                        .offset(x: emoji.x, y: emoji.y)
                        .opacity(emoji.opacity)
                }
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Emoji buttons
            HStack(spacing: 16) {
                ForEach(["❤️", "👍", "🎉", "😂", "🔥", "👏"], id: \.self) { emoji in
                    Button {
                        sharePlayManager.sendEmoji(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 35))
                    }
                }
            }

            Text("Send reactions that everyone sees")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Participants Section

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.headline)

            ForEach(sharePlayManager.participants, id: \.self) { participant in
                HStack(spacing: 12) {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(participant.prefix(1)))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        )

                    Text(participant)
                        .font(.subheadline)

                    Spacer()

                    if participant == sharePlayManager.participants.first {
                        Text("You")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Message Log Section

    private var messageLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sync Messages")
                    .font(.headline)
                Spacer()
                if !sharePlayManager.messageLog.isEmpty {
                    Button("Clear") {
                        sharePlayManager.messageLog = []
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            if sharePlayManager.messageLog.isEmpty {
                Text("Messages will appear here when syncing with other participants")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(sharePlayManager.messageLog.suffix(5).reversed(), id: \.id) { message in
                    HStack(spacing: 8) {
                        Image(systemName: message.isOutgoing ? "arrow.up.circle" : "arrow.down.circle")
                            .foregroundStyle(message.isOutgoing ? .blue : .green)

                        Text(message.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How SharePlay Works")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                howItWorksRow(
                    icon: "shareplay",
                    title: "GroupActivity Protocol",
                    description: "Define activities that can be shared during FaceTime"
                )
                howItWorksRow(
                    icon: "person.2.fill",
                    title: "GroupSession",
                    description: "Represents active session with participants"
                )
                howItWorksRow(
                    icon: "message.fill",
                    title: "GroupSessionMessenger",
                    description: "Send/receive messages between all participants"
                )
                howItWorksRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "State Sync",
                    description: "Keep all participants in sync with shared state"
                )
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Requirements
            VStack(alignment: .leading, spacing: 8) {
                Label("Requirements", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)

                Text("• Active FaceTime call or Messages conversation\n• All participants need app installed\n• iOS 15+ / macOS 12+\n• Works across Apple devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func howItWorksRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - SharePlay Activity Definition

struct APIPlaygroundActivity: GroupActivity {
    static let activityIdentifier = "com.apiplayground.shareplay"

    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = "API Playground Demo"
        metadata.subtitle = "Explore APIs together"
        metadata.type = .generic
        return metadata
    }
}

// MARK: - SharePlay Messages

struct CounterMessage: Codable, Sendable {
    let value: Int
    let action: String
}

struct StrokeMessage: Codable, Sendable {
    let points: [[CGFloat]]
    let colorComponents: [CGFloat]
}

struct EmojiMessage: Codable, Sendable {
    let emoji: String
}

struct ClearMessage: Codable, Sendable {
    let clear: Bool
}

// MARK: - SharePlay Manager

@MainActor
class SharePlayManager: ObservableObject {
    @Published var isInSession = false
    @Published var participantCount = 0
    @Published var participants: [String] = []
    @Published var counterValue = 0
    @Published var canvasStrokes: [CanvasStroke] = []
    @Published var currentStroke: [CGPoint] = []
    @Published var selectedColor: Color = .black
    @Published var floatingEmojis: [FloatingEmoji] = []
    @Published var messageLog: [SyncMessage] = []

    private var groupSession: GroupSession<APIPlaygroundActivity>?
    private var messenger: GroupSessionMessenger?
    private var tasks = Set<Task<Void, Never>>()
    private var subscriptions = Set<AnyCancellable>()

    struct CanvasStroke: Identifiable {
        let id = UUID()
        let points: [CGPoint]
        let color: Color
    }

    struct FloatingEmoji: Identifiable {
        let id = UUID()
        let emoji: String
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
    }

    struct SyncMessage: Identifiable {
        let id = UUID()
        let content: String
        let timestamp: Date
        let isOutgoing: Bool
    }

    func startObserving() async {
        for await session in APIPlaygroundActivity.sessions() {
            configureSession(session)
        }
    }

    func startActivity() async {
        let activity = APIPlaygroundActivity()

        switch await activity.prepareForActivation() {
        case .activationDisabled:
            addMessage("SharePlay is disabled", outgoing: false)
        case .activationPreferred:
            do {
                _ = try await activity.activate()
                addMessage("Activity activated", outgoing: true)
            } catch {
                addMessage("Activation failed: \(error.localizedDescription)", outgoing: false)
            }
        case .cancelled:
            addMessage("Activation cancelled", outgoing: false)
        @unknown default:
            break
        }
    }

    private func configureSession(_ session: GroupSession<APIPlaygroundActivity>) {
        groupSession = session
        messenger = GroupSessionMessenger(session: session)

        session.$state
            .sink { [weak self] state in
                switch state {
                case .joined:
                    self?.isInSession = true
                    self?.addMessage("Joined session", outgoing: false)
                case .waiting:
                    self?.addMessage("Waiting for participants", outgoing: false)
                case .invalidated:
                    self?.isInSession = false
                    self?.addMessage("Session ended", outgoing: false)
                @unknown default:
                    break
                }
            }
            .store(in: &subscriptions)

        session.$activeParticipants
            .sink { [weak self] participants in
                self?.participantCount = participants.count
                self?.participants = participants.map { "Participant \($0.id.hashValue % 1000)" }
            }
            .store(in: &subscriptions)

        // Listen for messages
        let counterTask = Task {
            guard let messenger = messenger else { return }
            for await (message, _) in messenger.messages(of: CounterMessage.self) {
                await MainActor.run {
                    self.counterValue = message.value
                    self.addMessage("Counter: \(message.action) -> \(message.value)", outgoing: false)
                }
            }
        }
        tasks.insert(counterTask)

        let strokeTask = Task {
            guard let messenger = messenger else { return }
            for await (message, _) in messenger.messages(of: StrokeMessage.self) {
                await MainActor.run {
                    let points = message.points.map { CGPoint(x: $0[0], y: $0[1]) }
                    let color = Color(
                        red: message.colorComponents[0],
                        green: message.colorComponents[1],
                        blue: message.colorComponents[2]
                    )
                    self.canvasStrokes.append(CanvasStroke(points: points, color: color))
                    self.addMessage("Received stroke", outgoing: false)
                }
            }
        }
        tasks.insert(strokeTask)

        let emojiTask = Task {
            guard let messenger = messenger else { return }
            for await (message, _) in messenger.messages(of: EmojiMessage.self) {
                await MainActor.run {
                    self.showFloatingEmoji(message.emoji)
                    self.addMessage("Emoji: \(message.emoji)", outgoing: false)
                }
            }
        }
        tasks.insert(emojiTask)

        let clearTask = Task {
            guard let messenger = messenger else { return }
            for await (_, _) in messenger.messages(of: ClearMessage.self) {
                await MainActor.run {
                    self.canvasStrokes = []
                    self.addMessage("Canvas cleared", outgoing: false)
                }
            }
        }
        tasks.insert(clearTask)

        session.join()
    }

    func endSession() {
        groupSession?.end()
        groupSession = nil
        messenger = nil
        isInSession = false
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }

    // MARK: - Counter Actions

    func incrementCounter() {
        counterValue += 1
        sendCounterUpdate(action: "increment")
    }

    func decrementCounter() {
        counterValue -= 1
        sendCounterUpdate(action: "decrement")
    }

    func resetCounter() {
        counterValue = 0
        sendCounterUpdate(action: "reset")
    }

    private func sendCounterUpdate(action: String) {
        guard let messenger = messenger else { return }

        let message = CounterMessage(value: counterValue, action: action)
        addMessage("Counter: \(action) -> \(counterValue)", outgoing: true)

        Task {
            try? await messenger.send(message)
        }
    }

    // MARK: - Canvas Actions

    func finishStroke() {
        guard !currentStroke.isEmpty else { return }

        let stroke = CanvasStroke(points: currentStroke, color: selectedColor)
        canvasStrokes.append(stroke)

        // Send to others
        guard let messenger = messenger else {
            currentStroke = []
            return
        }

        // Convert color to components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        UIColor(selectedColor).getRed(&red, green: &green, blue: &blue, alpha: nil)

        let message = StrokeMessage(
            points: currentStroke.map { [$0.x, $0.y] },
            colorComponents: [red, green, blue]
        )

        addMessage("Sent stroke", outgoing: true)

        Task {
            try? await messenger.send(message)
        }

        currentStroke = []
    }

    func clearCanvas() {
        canvasStrokes = []

        guard let messenger = messenger else { return }

        addMessage("Clear canvas", outgoing: true)

        Task {
            try? await messenger.send(ClearMessage(clear: true))
        }
    }

    // MARK: - Emoji Actions

    func sendEmoji(_ emoji: String) {
        showFloatingEmoji(emoji)

        guard let messenger = messenger else { return }

        addMessage("Emoji: \(emoji)", outgoing: true)

        Task {
            try? await messenger.send(EmojiMessage(emoji: emoji))
        }
    }

    private func showFloatingEmoji(_ emoji: String) {
        let x = CGFloat.random(in: -100...100)
        var floatingEmoji = FloatingEmoji(emoji: emoji, x: x, y: 0, opacity: 1)
        floatingEmojis.append(floatingEmoji)

        // Animate up and fade
        withAnimation(.easeOut(duration: 2)) {
            if let index = floatingEmojis.firstIndex(where: { $0.id == floatingEmoji.id }) {
                floatingEmojis[index].y = -100
                floatingEmojis[index].opacity = 0
            }
        }

        // Remove after animation
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                floatingEmojis.removeAll { $0.id == floatingEmoji.id }
            }
        }
    }

    // MARK: - Message Log

    private func addMessage(_ content: String, outgoing: Bool) {
        let message = SyncMessage(content: content, timestamp: Date(), isOutgoing: outgoing)
        messageLog.append(message)

        // Keep only last 20 messages
        if messageLog.count > 20 {
            messageLog.removeFirst()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SharePlayView()
    }
}
