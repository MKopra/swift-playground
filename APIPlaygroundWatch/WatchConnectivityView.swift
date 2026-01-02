import SwiftUI
import WatchConnectivity

struct WatchConnectivityView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager()
    @State private var messageToSend = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Connection status
                connectionStatusSection

                // Send message section
                sendMessageSection

                // Received messages
                receivedMessagesSection

                // Quick actions
                quickActionsSection
            }
            .padding(.horizontal)
        }
        .navigationTitle("iPhone Sync")
    }

    // MARK: - Connection Status

    private var connectionStatusSection: some View {
        HStack {
            Image(systemName: connectivityManager.isReachable ? "iphone" : "iphone.slash")
                .foregroundStyle(connectivityManager.isReachable ? .green : .red)

            VStack(alignment: .leading, spacing: 0) {
                Text(connectivityManager.isReachable ? "iPhone Connected" : "iPhone Not Reachable")
                    .font(.caption2)
                    .fontWeight(.medium)

                Text(connectivityManager.isPaired ? "Paired" : "Not Paired")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(connectivityManager.isReachable ? .green : .red)
                .frame(width: 8, height: 8)
        }
        .padding(8)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Send Message

    private var sendMessageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Send to iPhone")
                .font(.caption)
                .fontWeight(.medium)

            HStack {
                TextField("Message", text: $messageToSend)
                    .font(.caption)
                    .textFieldStyle(.plain)

                Button {
                    connectivityManager.sendMessage(messageToSend)
                    messageToSend = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .disabled(messageToSend.isEmpty || !connectivityManager.isReachable)
            }
            .padding(8)
            .background(Color(.darkGray).opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Received Messages

    private var receivedMessagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Received")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                if !connectivityManager.receivedMessages.isEmpty {
                    Button("Clear") {
                        connectivityManager.clearMessages()
                    }
                    .font(.caption2)
                    .foregroundStyle(.red)
                }
            }

            if connectivityManager.receivedMessages.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "tray")
                            .foregroundStyle(.secondary)
                        Text("No messages")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
            } else {
                ForEach(connectivityManager.receivedMessages, id: \.self) { message in
                    Text(message)
                        .font(.caption2)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.darkGray).opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.caption)
                .fontWeight(.medium)

            HStack(spacing: 8) {
                quickActionButton(icon: "bell.fill", title: "Ping", color: .orange) {
                    connectivityManager.sendMessage("ping")
                }

                quickActionButton(icon: "location.fill", title: "Location", color: .blue) {
                    connectivityManager.sendMessage("request_location")
                }
            }

            HStack(spacing: 8) {
                quickActionButton(icon: "camera.fill", title: "Photo", color: .purple) {
                    connectivityManager.sendMessage("request_photo")
                }

                quickActionButton(icon: "heart.fill", title: "Health", color: .pink) {
                    connectivityManager.sendMessage("sync_health")
                }
            }
        }
    }

    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color(.darkGray).opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!connectivityManager.isReachable)
    }
}

// MARK: - Watch Connectivity Manager

class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var isReachable = false
    @Published var isPaired = false
    @Published var receivedMessages: [String] = []

    private var session: WCSession?

    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendMessage(_ message: String) {
        guard let session = session, session.isReachable else { return }

        session.sendMessage(["message": message], replyHandler: nil) { error in
            print("Send error: \(error.localizedDescription)")
        }
    }

    func clearMessages() {
        receivedMessages.removeAll()
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            #if os(watchOS)
            self.isPaired = session.isCompanionAppInstalled
            #else
            self.isPaired = session.isPaired
            #endif
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let text = message["message"] as? String {
                self.receivedMessages.insert(text, at: 0)
                if self.receivedMessages.count > 10 {
                    self.receivedMessages.removeLast()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WatchConnectivityView()
    }
}
