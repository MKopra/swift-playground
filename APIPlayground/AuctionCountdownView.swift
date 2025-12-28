import SwiftUI
import ActivityKit

/// Auction Countdown - Last-second bidding timer
/// High-stakes time pressure makes Live Activity essential
struct AuctionCountdownView: View {
    @StateObject private var manager = AuctionActivityManager()
    @State private var itemName: String = "Vintage Watch"
    @State private var startingBid: Double = 100
    @State private var durationMinutes: Int = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusCard
                if manager.isActive {
                    auctionCard
                    biddingCard
                }
                configurationCard
                controlsCard
                infoCard
            }
            .padding()
        }
        .navigationTitle("Auction Countdown")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: manager.isActive ? "dollarsign.circle.fill" : "dollarsign.circle")
                        .foregroundStyle(manager.isActive ? .green : .secondary)
                        .font(.title2)
                    Text(manager.isActive ? "Auction Live" : "No Active Auction")
                        .font(.headline)
                    Spacer()
                    if manager.isActive && !manager.isEnded {
                        Text(urgencyText)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(urgencyColor.opacity(0.2), in: Capsule())
                            .foregroundStyle(urgencyColor)
                    }
                }

                if manager.isActive {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.itemName)
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("\(manager.numberOfBids) bids")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if manager.isEnded {
                            VStack(alignment: .trailing) {
                                Text(manager.isWinning ? "WON!" : "ENDED")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(manager.isWinning ? .green : .red)
                                Text(formatCurrency(manager.currentBid))
                                    .font(.subheadline)
                            }
                        } else {
                            Text("\(manager.secondsRemaining)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(urgencyColor)
                        }
                    }
                    .padding(.vertical, 8)
                }

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text(manager.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Status", systemImage: "gavel")
        }
    }

    // MARK: - Auction Card
    private var auctionCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Item display
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 120)

                    HStack(spacing: 20) {
                        // Item icon
                        ZStack {
                            Circle()
                                .fill(urgencyColor.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: manager.itemImage)
                                .font(.system(size: 36))
                                .foregroundStyle(urgencyColor)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Bid")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(formatCurrency(manager.currentBid))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.green)

                            HStack {
                                Image(systemName: manager.isWinning ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(manager.isWinning ? .green : .red)
                                Text(manager.isWinning ? "You're winning!" : "Outbid")
                                    .font(.subheadline)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }

                // Timer bar
                if !manager.isEnded {
                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(urgencyColor)
                                    .frame(width: geo.size.width * manager.progress)
                                    .animation(.linear(duration: 0.5), value: manager.progress)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("Time remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatTime(manager.secondsRemaining))
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        } label: {
            Label("Auction Details", systemImage: "tag")
        }
    }

    // MARK: - Bidding Card
    private var biddingCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                if !manager.isEnded {
                    // Quick bid buttons
                    HStack(spacing: 12) {
                        ForEach([5, 10, 25, 50], id: \.self) { amount in
                            Button {
                                manager.placeBid(amount: Double(amount))
                            } label: {
                                Text("+$\(amount)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.green, in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(.white)
                            }
                        }
                    }

                    // Simulate outbid
                    Button {
                        manager.simulateOutbid()
                    } label: {
                        Label("Simulate Outbid", systemImage: "person.fill.xmark")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.red)
                    }
                } else {
                    // Auction ended
                    VStack(spacing: 8) {
                        Image(systemName: manager.isWinning ? "trophy.fill" : "xmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(manager.isWinning ? .yellow : .red)

                        Text(manager.isWinning ? "Congratulations!" : "Better luck next time")
                            .font(.headline)

                        Text(manager.isWinning ? "You won with \(formatCurrency(manager.currentBid))" : "Final price: \(formatCurrency(manager.currentBid))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        } label: {
            Label(manager.isEnded ? "Results" : "Place Bid", systemImage: "creditcard")
        }
    }

    // MARK: - Configuration Card
    private var configurationCard: some View {
        GroupBox {
            VStack(spacing: 16) {
                TextField("Item Name", text: $itemName)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isActive)

                HStack {
                    Text("Starting Bid")
                    Spacer()
                    TextField("Amount", value: $startingBid, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .multilineTextAlignment(.trailing)
                        .disabled(manager.isActive)
                }

                HStack {
                    Text("Duration")
                    Spacer()
                    Picker("Duration", selection: $durationMinutes) {
                        Text("1 min").tag(1)
                        Text("2 min").tag(2)
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                    }
                    .pickerStyle(.menu)
                    .disabled(manager.isActive)
                }
            }
        } label: {
            Label("Configuration", systemImage: "gearshape")
        }
    }

    // MARK: - Controls Card
    private var controlsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                if !manager.isActive {
                    Button {
                        manager.startAuction(
                            itemName: itemName,
                            startingBid: startingBid,
                            durationMinutes: durationMinutes
                        )
                    } label: {
                        Label("Start Auction", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                } else {
                    Button {
                        manager.endAuction()
                    } label: {
                        Label(manager.isEnded ? "Close" : "End Auction", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
            }
        } label: {
            Label("Controls", systemImage: "play.rectangle")
        }
    }

    // MARK: - Info Card
    private var infoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                AuctionInfoRow(title: "Snipe Window", value: "Last 30 seconds")
                AuctionInfoRow(title: "Bid Extension", value: "10s per late bid")

                Divider()

                Text("Auction sniping is the practice of placing a winning bid in the final seconds. Live Activity ensures you never miss the crucial end-game, with urgency colors intensifying as time runs out.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("About", systemImage: "info.circle")
        }
    }

    private var urgencyColor: Color {
        if manager.isEnded { return manager.isWinning ? .green : .red }
        if manager.secondsRemaining <= 10 { return .red }
        if manager.secondsRemaining <= 30 { return .orange }
        return .green
    }

    private var urgencyText: String {
        if manager.secondsRemaining <= 10 { return "FINAL!" }
        if manager.secondsRemaining <= 30 { return "ENDING SOON" }
        return "ACTIVE"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct AuctionInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Auction Activity Manager

@MainActor
class AuctionActivityManager: ObservableObject {
    @Published var isActive = false
    @Published var isEnded = false
    @Published var secondsRemaining: Int = 300
    @Published var totalSeconds: Int = 300
    @Published var itemName: String = ""
    @Published var itemImage: String = "tag"
    @Published var currentBid: Double = 100
    @Published var numberOfBids: Int = 0
    @Published var isWinning: Bool = true
    @Published var progress: Double = 1.0
    @Published var statusMessage = "Ready to start auction"

    private var currentActivity: Activity<AuctionActivityAttributes>?
    private var timer: Timer?

    init() {
        checkExistingActivities()
    }

    private func checkExistingActivities() {
        if #available(iOS 16.1, *) {
            for activity in Activity<AuctionActivityAttributes>.activities {
                currentActivity = activity
                isActive = true
                itemName = activity.attributes.itemName
                itemImage = activity.attributes.itemImage
                updateFromState(activity.content.state)
                if !isEnded {
                    statusMessage = "Resumed auction"
                    startTimer()
                }
                break
            }
        }
    }

    private func updateFromState(_ state: AuctionActivityAttributes.ContentState) {
        secondsRemaining = state.secondsRemaining
        currentBid = state.currentBid
        numberOfBids = state.numberOfBids
        isWinning = state.isWinning
        isEnded = state.isEnded
        progress = Double(secondsRemaining) / Double(totalSeconds)
    }

    func startAuction(itemName: String, startingBid: Double, durationMinutes: Int) {
        guard #available(iOS 16.1, *) else {
            statusMessage = "Requires iOS 16.1+"
            return
        }

        self.itemName = itemName
        self.currentBid = startingBid
        self.totalSeconds = durationMinutes * 60
        self.secondsRemaining = totalSeconds
        self.numberOfBids = 1
        self.isWinning = true
        self.isEnded = false
        self.itemImage = randomItemImage()

        let attributes = AuctionActivityAttributes(
            itemName: itemName,
            itemImage: itemImage
        )

        let initialState = AuctionActivityAttributes.ContentState(
            secondsRemaining: secondsRemaining,
            currentBid: currentBid,
            numberOfBids: 1,
            isWinning: true,
            isEnded: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            isActive = true
            statusMessage = "Auction started - you're winning!"
            startTimer()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func randomItemImage() -> String {
        let images = ["watch.analog", "camera.fill", "headphones", "gamecontroller.fill",
                      "guitars.fill", "car.fill", "bicycle", "sportscourt.fill"]
        return images.randomElement() ?? "tag"
    }

    func placeBid(amount: Double) {
        guard !isEnded else { return }

        currentBid += amount
        numberOfBids += 1
        isWinning = true

        // Extend time if under 30 seconds (anti-snipe)
        if secondsRemaining < 30 {
            secondsRemaining += 10
            progress = Double(secondsRemaining) / Double(totalSeconds)
            statusMessage = "Bid placed! +10s anti-snipe"
        } else {
            statusMessage = "Bid placed! You're winning"
        }

        updateActivity()
    }

    func simulateOutbid() {
        guard !isEnded else { return }

        currentBid += Double.random(in: 5...25)
        numberOfBids += 1
        isWinning = false
        statusMessage = "You've been outbid!"
        updateActivity()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard !isEnded else { return }

        secondsRemaining -= 1
        progress = Double(secondsRemaining) / Double(totalSeconds)

        if secondsRemaining <= 0 {
            finishAuction()
        }

        updateActivity()
    }

    private func finishAuction() {
        timer?.invalidate()
        isEnded = true
        statusMessage = isWinning ? "Congratulations! You won!" : "Auction ended - outbid"
        updateActivity()
    }

    private func updateActivity() {
        guard #available(iOS 16.1, *),
              let activity = currentActivity else { return }

        let updatedState = AuctionActivityAttributes.ContentState(
            secondsRemaining: secondsRemaining,
            currentBid: currentBid,
            numberOfBids: numberOfBids,
            isWinning: isWinning,
            isEnded: isEnded
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }

    func endAuction() {
        timer?.invalidate()
        timer = nil

        guard #available(iOS 16.1, *),
              let activity = currentActivity else {
            isActive = false
            isEnded = false
            return
        }

        let finalState = AuctionActivityAttributes.ContentState(
            secondsRemaining: 0,
            currentBid: currentBid,
            numberOfBids: numberOfBids,
            isWinning: isWinning,
            isEnded: true
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )

            await MainActor.run {
                isActive = false
                isEnded = false
                currentActivity = nil
                statusMessage = "Auction closed"
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuctionCountdownView()
    }
}
