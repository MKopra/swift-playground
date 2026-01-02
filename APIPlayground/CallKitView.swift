import SwiftUI
import CallKit
import AVFoundation

// MARK: - CallKit Demo View

struct CallKitView: View {
    @StateObject private var callManager = CallManager()
    @State private var phoneNumber = "+1 555 123 4567"
    @State private var callerName = "John Appleseed"
    @State private var showBlockedNumbers = false
    @State private var showIdentifiedNumbers = false
    @State private var newBlockedNumber = ""
    @State private var newIdentifiedNumber = ""
    @State private var newIdentifiedName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Call Status Card
                callStatusCard

                // Incoming Call Demo
                incomingCallSection

                // Outgoing Call Demo
                outgoingCallSection

                // Call Directory
                callDirectorySection

                // Call History
                callHistorySection

                // How It Works
                howItWorksSection
            }
            .padding()
        }
        .navigationTitle("CallKit")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBlockedNumbers) {
            blockedNumbersSheet
        }
        .sheet(isPresented: $showIdentifiedNumbers) {
            identifiedNumbersSheet
        }
        .onAppear {
            callManager.requestMicrophonePermission()
        }
    }

    // MARK: - Call Status Card

    private var callStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: callManager.isOnCall ? "phone.fill" : "phone")
                    .font(.title)
                    .foregroundStyle(callManager.isOnCall ? .green : .secondary)
                    .symbolEffect(.pulse, isActive: callManager.isOnCall)

                VStack(alignment: .leading, spacing: 4) {
                    Text(callManager.isOnCall ? "Call Active" : "No Active Call")
                        .font(.headline)

                    if callManager.isOnCall {
                        Text(callManager.currentCallerName ?? "Unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(formatDuration(callManager.callDuration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if callManager.isOnCall {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Connected")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            if callManager.isOnCall {
                HStack(spacing: 16) {
                    // Mute button
                    Button {
                        callManager.toggleMute()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: callManager.isMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.title2)
                            Text("Mute")
                                .font(.caption)
                        }
                        .frame(width: 70, height: 60)
                        .background(callManager.isMuted ? .red.opacity(0.2) : .secondary.opacity(0.2))
                        .foregroundStyle(callManager.isMuted ? .red : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Speaker button
                    Button {
                        callManager.toggleSpeaker()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: callManager.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill")
                                .font(.title2)
                            Text("Speaker")
                                .font(.caption)
                        }
                        .frame(width: 70, height: 60)
                        .background(callManager.isSpeakerOn ? .blue.opacity(0.2) : .secondary.opacity(0.2))
                        .foregroundStyle(callManager.isSpeakerOn ? .blue : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Hold button
                    Button {
                        callManager.toggleHold()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: callManager.isOnHold ? "pause.fill" : "pause")
                                .font(.title2)
                            Text("Hold")
                                .font(.caption)
                        }
                        .frame(width: 70, height: 60)
                        .background(callManager.isOnHold ? .orange.opacity(0.2) : .secondary.opacity(0.2))
                        .foregroundStyle(callManager.isOnHold ? .orange : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // End call button
                    Button {
                        callManager.endCall()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "phone.down.fill")
                                .font(.title2)
                            Text("End")
                                .font(.caption)
                        }
                        .frame(width: 70, height: 60)
                        .background(.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Incoming Call Section

    private var incomingCallSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Simulate Incoming Call")
                .font(.headline)

            VStack(spacing: 12) {
                TextField("Caller Name", text: $callerName)
                    .textFieldStyle(.roundedBorder)

                TextField("Phone Number", text: $phoneNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)

                Button {
                    callManager.simulateIncomingCall(
                        from: phoneNumber,
                        callerName: callerName
                    )
                } label: {
                    Label("Simulate Incoming Call", systemImage: "phone.arrow.down.left.fill")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(callManager.isOnCall)
            }

            Text("This will show the native iOS call UI")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Outgoing Call Section

    private var outgoingCallSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Simulate Outgoing Call")
                .font(.headline)

            Button {
                callManager.simulateOutgoingCall(to: phoneNumber)
            } label: {
                Label("Start Outgoing Call", systemImage: "phone.arrow.up.right.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(callManager.isOnCall)

            Text("Initiates a call using CXCallController")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Call Directory Section

    private var callDirectorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Call Directory")
                .font(.headline)

            HStack(spacing: 12) {
                Button {
                    showBlockedNumbers = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                        Text("Blocked")
                            .font(.caption)
                        Text("\(callManager.blockedNumbers.count)")
                            .font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    showIdentifiedNumbers = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "person.text.rectangle")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text("Identified")
                            .font(.caption)
                        Text("\(callManager.identifiedNumbers.count)")
                            .font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            // Extension status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "puzzlepiece.extension")
                        .foregroundStyle(.orange)
                    Text("Call Directory Extension")
                        .font(.subheadline.weight(.medium))
                }

                Text("To enable call blocking and caller ID, a Call Directory Extension must be added to the project and enabled in Settings > Phone > Call Blocking & Identification.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    openCallBlockingSettings()
                } label: {
                    Text("Open Settings")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Call History Section

    private var callHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Call History")
                    .font(.headline)
                Spacer()
                if !callManager.callHistory.isEmpty {
                    Button("Clear") {
                        callManager.callHistory = []
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
            }

            if callManager.callHistory.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "phone.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No calls yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
            } else {
                ForEach(callManager.callHistory.reversed()) { call in
                    callHistoryRow(call)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func callHistoryRow(_ call: CallManager.CallRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: call.isIncoming ? "phone.arrow.down.left" : "phone.arrow.up.right")
                .foregroundStyle(call.wasAnswered ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(call.callerName ?? call.phoneNumber)
                    .font(.subheadline.weight(.medium))
                Text(call.phoneNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(call.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if call.wasAnswered {
                    Text(formatDuration(call.duration))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Missed")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How CallKit Works")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                howItWorksRow(
                    icon: "phone.badge.waveform",
                    title: "CXProvider",
                    description: "Receives and reports calls to the system"
                )
                howItWorksRow(
                    icon: "dial.low",
                    title: "CXCallController",
                    description: "Initiates outgoing calls and call actions"
                )
                howItWorksRow(
                    icon: "rectangle.fill.badge.person.crop",
                    title: "Call Directory Extension",
                    description: "Blocks numbers and identifies callers"
                )
                howItWorksRow(
                    icon: "bell.badge",
                    title: "VoIP Push (PushKit)",
                    description: "Wakes app for incoming calls"
                )
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Limitations
            VStack(alignment: .leading, spacing: 8) {
                Label("Limitations", systemImage: "exclamationmark.triangle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)

                Text("• iOS 13+: Must report calls to CallKit or app terminated\n• VoIP entitlement restricted for new developers\n• Call Directory requires extension\n• Cannot intercept cellular calls")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.orange.opacity(0.1))
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

    // MARK: - Blocked Numbers Sheet

    private var blockedNumbersSheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Phone number", text: $newBlockedNumber)
                            .keyboardType(.phonePad)
                        Button("Add") {
                            if !newBlockedNumber.isEmpty {
                                callManager.blockedNumbers.append(newBlockedNumber)
                                newBlockedNumber = ""
                            }
                        }
                        .disabled(newBlockedNumber.isEmpty)
                    }
                } header: {
                    Text("Add Blocked Number")
                }

                Section {
                    if callManager.blockedNumbers.isEmpty {
                        Text("No blocked numbers")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(callManager.blockedNumbers, id: \.self) { number in
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundStyle(.red)
                                Text(number)
                            }
                        }
                        .onDelete { indexSet in
                            callManager.blockedNumbers.remove(atOffsets: indexSet)
                        }
                    }
                } header: {
                    Text("Blocked Numbers")
                }
            }
            .navigationTitle("Blocked Numbers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showBlockedNumbers = false
                    }
                }
            }
        }
    }

    // MARK: - Identified Numbers Sheet

    private var identifiedNumbersSheet: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Phone number", text: $newIdentifiedNumber)
                        .keyboardType(.phonePad)
                    TextField("Caller name", text: $newIdentifiedName)
                    Button("Add") {
                        if !newIdentifiedNumber.isEmpty && !newIdentifiedName.isEmpty {
                            callManager.identifiedNumbers[newIdentifiedNumber] = newIdentifiedName
                            newIdentifiedNumber = ""
                            newIdentifiedName = ""
                        }
                    }
                    .disabled(newIdentifiedNumber.isEmpty || newIdentifiedName.isEmpty)
                } header: {
                    Text("Add Identified Number")
                }

                Section {
                    if callManager.identifiedNumbers.isEmpty {
                        Text("No identified numbers")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(callManager.identifiedNumbers.keys), id: \.self) { number in
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text(callManager.identifiedNumbers[number] ?? "")
                                        .font(.subheadline)
                                    Text(number)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let key = Array(callManager.identifiedNumbers.keys)[index]
                                callManager.identifiedNumbers.removeValue(forKey: key)
                            }
                        }
                    }
                } header: {
                    Text("Identified Numbers")
                }
            }
            .navigationTitle("Caller ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showIdentifiedNumbers = false
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func openCallBlockingSettings() {
        if let url = URL(string: "App-Prefs:Phone") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Call Manager

class CallManager: NSObject, ObservableObject, CXProviderDelegate {
    @Published var isOnCall = false
    @Published var isMuted = false
    @Published var isSpeakerOn = false
    @Published var isOnHold = false
    @Published var callDuration: TimeInterval = 0
    @Published var currentCallerName: String?
    @Published var callHistory: [CallRecord] = []
    @Published var blockedNumbers: [String] = []
    @Published var identifiedNumbers: [String: String] = [:]

    private var provider: CXProvider?
    private var callController = CXCallController()
    private var currentCallUUID: UUID?
    private var callStartTime: Date?
    private var durationTimer: Timer?

    struct CallRecord: Identifiable {
        let id = UUID()
        let phoneNumber: String
        let callerName: String?
        let timestamp: Date
        let duration: TimeInterval
        let isIncoming: Bool
        let wasAnswered: Bool
    }

    override init() {
        super.init()
        configureProvider()
        loadData()
    }

    private func configureProvider() {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = false
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.phoneNumber]
        configuration.iconTemplateImageData = nil // Would set app icon

        provider = CXProvider(configuration: configuration)
        provider?.setDelegate(self, queue: nil)
    }

    // MARK: - Permissions

    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    // MARK: - Call Actions

    func simulateIncomingCall(from phoneNumber: String, callerName: String) {
        let uuid = UUID()
        currentCallUUID = uuid
        currentCallerName = callerName

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: phoneNumber)
        update.localizedCallerName = callerName
        update.hasVideo = false

        provider?.reportNewIncomingCall(with: uuid, update: update) { [weak self] error in
            if let error = error {
                print("Failed to report incoming call: \(error)")
                self?.currentCallUUID = nil
                self?.currentCallerName = nil
            }
        }
    }

    func simulateOutgoingCall(to phoneNumber: String) {
        let uuid = UUID()
        currentCallUUID = uuid

        let handle = CXHandle(type: .phoneNumber, value: phoneNumber)
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)

        let transaction = CXTransaction(action: startCallAction)
        callController.request(transaction) { [weak self] error in
            if let error = error {
                print("Failed to start call: \(error)")
                self?.currentCallUUID = nil
            } else {
                // Report call connected after a delay (simulating connection)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.provider?.reportOutgoingCall(with: uuid, connectedAt: Date())
                    self?.startCall()
                }
            }
        }
    }

    func endCall() {
        guard let uuid = currentCallUUID else { return }

        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callController.request(transaction) { error in
            if let error = error {
                print("Failed to end call: \(error)")
            }
        }
    }

    func toggleMute() {
        guard let uuid = currentCallUUID else { return }

        let muteAction = CXSetMutedCallAction(call: uuid, muted: !isMuted)
        let transaction = CXTransaction(action: muteAction)

        callController.request(transaction) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.isMuted.toggle()
                }
            }
        }
    }

    func toggleHold() {
        guard let uuid = currentCallUUID else { return }

        let holdAction = CXSetHeldCallAction(call: uuid, onHold: !isOnHold)
        let transaction = CXTransaction(action: holdAction)

        callController.request(transaction) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.isOnHold.toggle()
                }
            }
        }
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat)
            try audioSession.overrideOutputAudioPort(isSpeakerOn ? .speaker : .none)
        } catch {
            print("Failed to toggle speaker: \(error)")
        }
    }

    private func startCall() {
        DispatchQueue.main.async {
            self.isOnCall = true
            self.callStartTime = Date()
            self.startDurationTimer()
        }
    }

    private func endCallInternal(wasAnswered: Bool) {
        durationTimer?.invalidate()
        durationTimer = nil

        let record = CallRecord(
            phoneNumber: "+1 555 123 4567",
            callerName: currentCallerName,
            timestamp: callStartTime ?? Date(),
            duration: callDuration,
            isIncoming: true,
            wasAnswered: wasAnswered
        )

        DispatchQueue.main.async {
            self.callHistory.append(record)
            self.isOnCall = false
            self.isMuted = false
            self.isSpeakerOn = false
            self.isOnHold = false
            self.callDuration = 0
            self.currentCallUUID = nil
            self.currentCallerName = nil
            self.callStartTime = nil
            self.saveData()
        }
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.callStartTime else { return }
            DispatchQueue.main.async {
                self.callDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    // MARK: - CXProviderDelegate

    func providerDidReset(_ provider: CXProvider) {
        endCallInternal(wasAnswered: false)
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        startCall()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        endCallInternal(wasAnswered: isOnCall)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        // Configure audio session for call
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        // Clean up audio session
    }

    // MARK: - Persistence

    private func saveData() {
        UserDefaults.standard.set(blockedNumbers, forKey: "blockedNumbers")
        UserDefaults.standard.set(identifiedNumbers, forKey: "identifiedNumbers")
    }

    private func loadData() {
        blockedNumbers = UserDefaults.standard.stringArray(forKey: "blockedNumbers") ?? []
        identifiedNumbers = UserDefaults.standard.dictionary(forKey: "identifiedNumbers") as? [String: String] ?? [:]
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CallKitView()
    }
}
