import SwiftUI
import PassKit

// MARK: - WalletView
/// A comprehensive Apple Wallet interface using PassKit.
///
/// Features:
/// - View passes in Apple Wallet
/// - Add passes to Wallet
/// - Pass type demonstrations (boarding pass, event ticket, etc.)
/// - Apple Pay integration info
/// - Pass library browsing
///
/// APIs Demonstrated:
/// - PKPassLibrary for pass management
/// - PKPass for pass representation
/// - PKAddPassesViewController for adding passes
/// - PKPaymentAuthorizationViewController for Apple Pay
///
/// Note: This API is NOT available in Flutter - requires native PassKit implementation.
/// PassKit provides integration with Apple Wallet for passes and Apple Pay.
struct WalletView: View {
    @StateObject private var walletManager = WalletManager()
    @State private var selectedPassType: PassType = .boardingPass
    @State private var showingPassPreview = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.15, green: 0.15, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Wallet header
                    WalletHeader()

                    // Apple Pay section
                    ApplePaySection(walletManager: walletManager)

                    // Pass types
                    PassTypesSection(selectedType: $selectedPassType)

                    // Demo pass preview
                    DemoPassCard(passType: selectedPassType)

                    // Wallet passes
                    if !walletManager.passes.isEmpty {
                        WalletPassesSection(passes: walletManager.passes)
                    }

                    // Capabilities info
                    CapabilitiesSection(walletManager: walletManager)
                }
                .padding()
            }
        }
        .navigationTitle("Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            walletManager.loadPasses()
        }
    }
}

// MARK: - WalletHeader
/// Wallet header with icon.
struct WalletHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Apple Wallet Integration")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Manage passes, tickets, and payments")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .padding(.vertical)
    }
}

// MARK: - ApplePaySection
/// Apple Pay information section.
struct ApplePaySection: View {
    @ObservedObject var walletManager: WalletManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "apple.logo")
                    .font(.title2)
                Text("Pay")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)

            HStack(spacing: 16) {
                ApplePayStatusItem(
                    title: "Device Support",
                    isAvailable: walletManager.canMakePayments,
                    icon: "iphone"
                )

                ApplePayStatusItem(
                    title: "Cards Added",
                    isAvailable: walletManager.hasPaymentCards,
                    icon: "creditcard"
                )
            }

            if walletManager.canMakePayments && walletManager.hasPaymentCards {
                Text("Apple Pay is ready to use")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else if walletManager.canMakePayments {
                Text("Add a card to use Apple Pay")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("Apple Pay is not available on this device")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Apple Pay button preview
            ApplePayButtonPreview()
        }
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Apple Pay status item.
struct ApplePayStatusItem: View {
    let title: String
    let isAvailable: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isAvailable ? .green : .gray)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.gray)

                Text(isAvailable ? "Available" : "Unavailable")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isAvailable ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Apple Pay button preview.
struct ApplePayButtonPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Button Styles")
                .font(.caption)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                // Buy with Apple Pay
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .frame(height: 44)
                    .overlay(
                        HStack(spacing: 4) {
                            Text("Buy with")
                                .foregroundStyle(.black)
                            Image(systemName: "apple.logo")
                                .foregroundStyle(.black)
                            Text("Pay")
                                .foregroundStyle(.black)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    )

                // Apple Pay
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black)
                    .frame(height: 44)
                    .overlay(
                        HStack(spacing: 4) {
                            Image(systemName: "apple.logo")
                            Text("Pay")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    )
            }
        }
    }
}

// MARK: - PassTypesSection
/// Pass type selector.
struct PassTypesSection: View {
    @Binding var selectedType: PassType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pass Types")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PassType.allCases) { type in
                        PassTypeButton(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
}

/// Pass type button.
struct PassTypeButton: View {
    let type: PassType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)

                Text(type.rawValue)
                    .font(.caption)
            }
            .foregroundStyle(isSelected ? .white : .gray)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? type.color.opacity(0.3) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - PassType
/// Types of passes available.
enum PassType: String, CaseIterable, Identifiable {
    case boardingPass = "Boarding"
    case eventTicket = "Event"
    case coupon = "Coupon"
    case storeCard = "Store Card"
    case generic = "Generic"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .boardingPass: return "airplane"
        case .eventTicket: return "ticket"
        case .coupon: return "tag"
        case .storeCard: return "creditcard"
        case .generic: return "rectangle.stack"
        }
    }

    var color: Color {
        switch self {
        case .boardingPass: return .blue
        case .eventTicket: return .purple
        case .coupon: return .orange
        case .storeCard: return .green
        case .generic: return .gray
        }
    }
}

// MARK: - DemoPassCard
/// Demo pass card display.
struct DemoPassCard: View {
    let passType: PassType

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pass header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(passHeaderTitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    Text(passTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: passType.icon)
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
            .background(passType.color)

            // Pass body
            VStack(spacing: 16) {
                // Main content
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(primaryLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(primaryValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(secondaryLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(secondaryValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }

                Divider()

                // Additional info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                    }

                    Spacer()

                    // Barcode placeholder
                    Image(systemName: "barcode")
                        .font(.largeTitle)
                        .foregroundStyle(.black)
                }
            }
            .padding()
            .background(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }

    private var passHeaderTitle: String {
        switch passType {
        case .boardingPass: return "AIRLINE"
        case .eventTicket: return "CONCERT"
        case .coupon: return "DISCOUNT"
        case .storeCard: return "REWARDS"
        case .generic: return "PASS"
        }
    }

    private var passTitle: String {
        switch passType {
        case .boardingPass: return "Flight 2847"
        case .eventTicket: return "Live Music Festival"
        case .coupon: return "20% Off"
        case .storeCard: return "Gold Member"
        case .generic: return "Demo Pass"
        }
    }

    private var primaryLabel: String {
        switch passType {
        case .boardingPass: return "From"
        case .eventTicket: return "Venue"
        case .coupon: return "Discount"
        case .storeCard: return "Points"
        case .generic: return "Type"
        }
    }

    private var primaryValue: String {
        switch passType {
        case .boardingPass: return "SFO"
        case .eventTicket: return "Stadium Arena"
        case .coupon: return "$25 OFF"
        case .storeCard: return "1,250"
        case .generic: return "Standard"
        }
    }

    private var secondaryLabel: String {
        switch passType {
        case .boardingPass: return "To"
        case .eventTicket: return "Seat"
        case .coupon: return "Expires"
        case .storeCard: return "Status"
        case .generic: return "ID"
        }
    }

    private var secondaryValue: String {
        switch passType {
        case .boardingPass: return "JFK"
        case .eventTicket: return "A-127"
        case .coupon: return "Jan 31"
        case .storeCard: return "Gold"
        case .generic: return "#12345"
        }
    }
}

// MARK: - WalletPassesSection
/// Section showing passes in wallet.
struct WalletPassesSection: View {
    let passes: [WalletPass]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Passes")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(passes) { pass in
                HStack(spacing: 16) {
                    Image(systemName: pass.icon)
                        .font(.title2)
                        .foregroundStyle(pass.color)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pass.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)

                        Text(pass.organization)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - CapabilitiesSection
/// PassKit capabilities information.
struct CapabilitiesSection: View {
    @ObservedObject var walletManager: WalletManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Capabilities")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                CapabilityRow(
                    title: "PassKit Available",
                    isAvailable: true,
                    description: "PassKit framework is available"
                )

                CapabilityRow(
                    title: "Add Passes",
                    isAvailable: walletManager.canAddPasses,
                    description: "Device can add passes to Wallet"
                )

                CapabilityRow(
                    title: "Apple Pay",
                    isAvailable: walletManager.canMakePayments,
                    description: "Device supports Apple Pay"
                )

                CapabilityRow(
                    title: "Secure Element",
                    isAvailable: walletManager.hasSecureElement,
                    description: "Secure payment hardware available"
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Capability row display.
struct CapabilityRow: View {
    let title: String
    let isAvailable: Bool
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isAvailable ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models

/// Represents a pass in the wallet.
struct WalletPass: Identifiable {
    let id = UUID()
    let name: String
    let organization: String
    let icon: String
    let color: Color
}

// MARK: - WalletManager
/// Manages PassKit operations.
///
/// This class provides:
/// - Pass library access
/// - Apple Pay capability checking
/// - Pass management operations
@MainActor
class WalletManager: ObservableObject {
    // MARK: Published Properties
    @Published var passes: [WalletPass] = []
    @Published var canMakePayments = false
    @Published var hasPaymentCards = false
    @Published var canAddPasses = false
    @Published var hasSecureElement = false

    // MARK: Private Properties
    private let passLibrary = PKPassLibrary()

    // MARK: Initialization

    init() {
        checkCapabilities()
    }

    // MARK: Public Methods

    /// Loads passes from the library.
    func loadPasses() {
        let libraryPasses = passLibrary.passes()

        passes = libraryPasses.map { pass in
            WalletPass(
                name: pass.localizedName,
                organization: pass.organizationName,
                icon: iconForPassType(pass.passType),
                color: colorForPassType(pass.passType)
            )
        }
    }

    // MARK: Private Methods

    private func checkCapabilities() {
        canMakePayments = PKPaymentAuthorizationController.canMakePayments()
        hasPaymentCards = PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex])
        canAddPasses = PKAddPassesViewController.canAddPasses()
        hasSecureElement = PKPaymentAuthorizationController.canMakePayments()
    }

    private func iconForPassType(_ passType: PKPassType) -> String {
        switch passType {
        case .barcode:
            return "barcode"
        case .payment:
            return "creditcard"
        case .secureElement:
            return "lock.shield"
        case .any:
            return "rectangle.stack"
        @unknown default:
            return "rectangle.stack"
        }
    }

    private func colorForPassType(_ passType: PKPassType) -> Color {
        switch passType {
        case .barcode:
            return .blue
        case .payment:
            return .green
        case .secureElement:
            return .purple
        case .any:
            return .gray
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        WalletView()
    }
}
