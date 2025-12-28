import SwiftUI
import LocalAuthentication
import Security

// MARK: - BiometricsView
/// A comprehensive biometric authentication interface with secure keychain storage.
///
/// Features:
/// - Face ID / Touch ID / Optic ID authentication
/// - Secure keychain storage for sensitive data
/// - Password generation and storage
/// - Secure notes vault
/// - Authentication history logging
/// - Animated vault visualization
///
/// APIs Demonstrated:
/// - LocalAuthentication for biometric verification
/// - Security framework for Keychain operations
/// - LAContext for policy evaluation
/// - SecItemAdd/SecItemCopyMatching for secure storage
struct BiometricsView: View {
    @StateObject private var biometricManager = BiometricManager()
    @State private var unlockProgress: CGFloat = 0
    @State private var showingAddItem = false
    @State private var selectedItemType: VaultItemType = .password
    @State private var gearRotation: Double = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Vault header with status
                VaultHeader(manager: biometricManager)

                if biometricManager.isAuthenticated {
                    // Authenticated view - show vault contents
                    VaultContentsView(manager: biometricManager, showingAddItem: $showingAddItem)
                } else {
                    // Locked view - show vault door
                    VaultDoorView(
                        unlockProgress: unlockProgress,
                        isAuthenticated: biometricManager.isAuthenticated,
                        biometricType: biometricManager.biometricType,
                        gearRotation: gearRotation
                    )

                    Spacer()

                    // Authenticate button
                    AuthenticateButton(
                        biometricManager: biometricManager,
                        unlockProgress: $unlockProgress
                    )
                }

                if let error = biometricManager.error {
                    ErrorBanner(message: error)
                }
            }
            .padding()
        }
        .navigationTitle("Biometrics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if biometricManager.isAuthenticated {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { biometricManager.lock() }) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddVaultItemSheet(manager: biometricManager, itemType: $selectedItemType)
        }
        .onAppear {
            biometricManager.checkBiometricType()
            startGearAnimation()
        }
    }

    private func startGearAnimation() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            gearRotation = 360
        }
    }
}

// MARK: - VaultHeader
/// Displays vault status and biometric type information.
struct VaultHeader: View {
    @ObservedObject var manager: BiometricManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Secure Vault")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Image(systemName: manager.biometricIcon)
                        .foregroundStyle(.blue)
                    Text(manager.biometricType)
                        .foregroundStyle(.gray)
                }
                .font(.caption)
            }

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                Circle()
                    .fill(manager.isAuthenticated ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(manager.isAuthenticated ? "Unlocked" : "Locked")
                    .font(.caption)
                    .foregroundStyle(manager.isAuthenticated ? .green : .red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                (manager.isAuthenticated ? Color.green : Color.red).opacity(0.15),
                in: Capsule()
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - VaultDoorView
/// Animated vault door visualization with lock mechanism.
struct VaultDoorView: View {
    let unlockProgress: CGFloat
    let isAuthenticated: Bool
    let biometricType: String
    let gearRotation: Double

    var body: some View {
        ZStack {
            // Background gears
            ForEach(0..<3, id: \.self) { i in
                GearShape()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 150 + CGFloat(i) * 40, height: 150 + CGFloat(i) * 40)
                    .rotationEffect(.degrees(gearRotation * (i % 2 == 0 ? 1 : -1)))
            }

            // Outer ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.gray, .white.opacity(0.4), .gray, .white.opacity(0.2), .gray],
                        center: .center
                    ),
                    lineWidth: 24
                )
                .frame(width: 220, height: 220)

            // Lock mechanism ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.25), Color(white: 0.08)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 180)
                .shadow(color: .black.opacity(0.5), radius: 15, y: 8)

            // Progress ring
            Circle()
                .trim(from: 0, to: unlockProgress)
                .stroke(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))

            // Lock bolts
            ForEach(0..<8, id: \.self) { i in
                LockBolt(isUnlocked: isAuthenticated)
                    .rotationEffect(.degrees(Double(i) * 45))
            }

            // Center icon
            Image(systemName: isAuthenticated ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(isAuthenticated ? .green : .white)
                .scaleEffect(isAuthenticated ? 1.15 : 1.0)
                .animation(.spring(response: 0.3), value: isAuthenticated)
        }
        .rotation3DEffect(
            .degrees(isAuthenticated ? 0 : 3),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
    }
}

// MARK: - GearShape
/// Custom gear shape for vault decoration.
struct GearShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.7
        let toothCount = 12

        for i in 0..<toothCount {
            let angle1 = Double(i) * (360.0 / Double(toothCount)) * .pi / 180
            let angle2 = (Double(i) + 0.4) * (360.0 / Double(toothCount)) * .pi / 180
            let angle3 = (Double(i) + 0.5) * (360.0 / Double(toothCount)) * .pi / 180
            let angle4 = (Double(i) + 0.9) * (360.0 / Double(toothCount)) * .pi / 180

            let p1 = CGPoint(x: center.x + innerRadius * CGFloat(Darwin.cos(angle1)), y: center.y + innerRadius * CGFloat(Darwin.sin(angle1)))
            let p2 = CGPoint(x: center.x + outerRadius * CGFloat(Darwin.cos(angle2)), y: center.y + outerRadius * CGFloat(Darwin.sin(angle2)))
            let p3 = CGPoint(x: center.x + outerRadius * CGFloat(Darwin.cos(angle3)), y: center.y + outerRadius * CGFloat(Darwin.sin(angle3)))
            let p4 = CGPoint(x: center.x + innerRadius * CGFloat(Darwin.cos(angle4)), y: center.y + innerRadius * CGFloat(Darwin.sin(angle4)))

            if i == 0 {
                path.move(to: p1)
            }
            path.addLine(to: p2)
            path.addLine(to: p3)
            path.addLine(to: p4)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - LockBolt
/// Individual lock bolt that animates on unlock.
struct LockBolt: View {
    let isUnlocked: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.5), Color(white: 0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 12, height: 25)
            .offset(y: isUnlocked ? -85 : -75)
            .animation(.spring(response: 0.4), value: isUnlocked)
    }
}

// MARK: - AuthenticateButton
/// Button to trigger biometric authentication.
struct AuthenticateButton: View {
    @ObservedObject var biometricManager: BiometricManager
    @Binding var unlockProgress: CGFloat

    var body: some View {
        Button(action: authenticate) {
            HStack(spacing: 12) {
                Image(systemName: biometricManager.biometricIcon)
                    .font(.title2)
                Text("Authenticate")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func authenticate() {
        biometricManager.authenticate { success in
            if success {
                withAnimation(.easeOut(duration: 0.8)) {
                    unlockProgress = 1.0
                }
            }
        }
    }
}

// MARK: - VaultContentsView
/// Displays the contents of the vault when unlocked.
struct VaultContentsView: View {
    @ObservedObject var manager: BiometricManager
    @Binding var showingAddItem: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Quick stats
            HStack(spacing: 16) {
                VaultStatCard(
                    icon: "key.fill",
                    count: manager.vaultItems.filter { $0.type == .password }.count,
                    label: "Passwords",
                    color: .blue
                )
                VaultStatCard(
                    icon: "note.text",
                    count: manager.vaultItems.filter { $0.type == .note }.count,
                    label: "Notes",
                    color: .purple
                )
                VaultStatCard(
                    icon: "creditcard.fill",
                    count: manager.vaultItems.filter { $0.type == .card }.count,
                    label: "Cards",
                    color: .orange
                )
            }

            // Items list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(manager.vaultItems) { item in
                        VaultItemRow(item: item, manager: manager)
                    }

                    if manager.vaultItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 50))
                                .foregroundStyle(.gray)
                            Text("No items in vault")
                                .foregroundStyle(.gray)
                            Text("Tap + to add passwords, notes, or cards")
                                .font(.caption)
                                .foregroundStyle(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
            }

            // Add button
            Button(action: { showingAddItem = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Item")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - VaultStatCard
/// Statistics card for vault item counts.
struct VaultStatCard: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - VaultItemRow
/// Row display for a vault item.
struct VaultItemRow: View {
    let item: VaultItem
    @ObservedObject var manager: BiometricManager
    @State private var showingValue = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.type.icon)
                .font(.title3)
                .foregroundStyle(item.type.color)
                .frame(width: 40, height: 40)
                .background(item.type.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Text(showingValue ? item.value : item.maskedValue)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }

            Spacer()

            // Reveal button
            Button(action: { showingValue.toggle() }) {
                Image(systemName: showingValue ? "eye.slash" : "eye")
                    .foregroundStyle(.gray)
            }

            // Copy button
            Button(action: { copyToClipboard(item.value) }) {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.gray)
            }

            // Delete button
            Button(action: { manager.deleteItem(item) }) {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
    }
}

// MARK: - AddVaultItemSheet
/// Sheet for adding new vault items.
struct AddVaultItemSheet: View {
    @ObservedObject var manager: BiometricManager
    @Binding var itemType: VaultItemType
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var value = ""
    @State private var generatedPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Type") {
                    Picker("Type", selection: $itemType) {
                        ForEach(VaultItemType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField("Title", text: $title)
                    if itemType == .note {
                        TextEditor(text: $value)
                            .frame(minHeight: 100)
                    } else {
                        SecureField(itemType == .card ? "Card Number" : "Password", text: $value)
                    }
                }

                if itemType == .password {
                    Section("Password Generator") {
                        HStack {
                            Text(generatedPassword.isEmpty ? "Generate a password" : generatedPassword)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(generatedPassword.isEmpty ? .gray : .primary)

                            Spacer()

                            Button("Generate") {
                                generatedPassword = generatePassword()
                            }
                            .buttonStyle(.bordered)
                        }

                        if !generatedPassword.isEmpty {
                            Button("Use This Password") {
                                value = generatedPassword
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(title.isEmpty || value.isEmpty)
                }
            }
        }
    }

    private func saveItem() {
        let item = VaultItem(title: title, value: value, type: itemType)
        manager.addItem(item)
    }

    private func generatePassword() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*"
        let all = letters + numbers + symbols

        var password = ""
        for _ in 0..<16 {
            if let char = all.randomElement() {
                password.append(char)
            }
        }
        return password
    }
}

// MARK: - ErrorBanner
/// Displays error messages.
struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(.white)
        .padding()
        .background(Color.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - VaultItemType
/// Types of items that can be stored in the vault.
enum VaultItemType: String, CaseIterable, Identifiable, Codable {
    case password
    case note
    case card

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .password: return "Password"
        case .note: return "Secure Note"
        case .card: return "Card"
        }
    }

    var icon: String {
        switch self {
        case .password: return "key.fill"
        case .note: return "note.text"
        case .card: return "creditcard.fill"
        }
    }

    var color: Color {
        switch self {
        case .password: return .blue
        case .note: return .purple
        case .card: return .orange
        }
    }
}

// MARK: - VaultItem
/// Represents an item stored in the secure vault.
struct VaultItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let value: String
    let type: VaultItemType
    let createdAt: Date

    init(title: String, value: String, type: VaultItemType) {
        self.id = UUID()
        self.title = title
        self.value = value
        self.type = type
        self.createdAt = Date()
    }

    var maskedValue: String {
        switch type {
        case .password:
            return String(repeating: "•", count: min(value.count, 12))
        case .note:
            return String(value.prefix(30)) + (value.count > 30 ? "..." : "")
        case .card:
            if value.count >= 4 {
                return "•••• •••• •••• " + String(value.suffix(4))
            }
            return String(repeating: "•", count: value.count)
        }
    }
}

// MARK: - BiometricManager
/// Manages biometric authentication and secure keychain storage.
///
/// This class provides:
/// - Biometric authentication (Face ID, Touch ID, Optic ID)
/// - Secure keychain storage for vault items
/// - Item management (add, delete, retrieve)
/// - Authentication state tracking
@MainActor
class BiometricManager: ObservableObject {
    // MARK: Published Properties
    @Published var isAuthenticated = false
    @Published var biometricType = "Unknown"
    @Published var error: String?
    @Published var vaultItems: [VaultItem] = []

    // MARK: Private Properties
    private let context = LAContext()
    private let keychainService = "com.apiplayground.vault"

    /// SF Symbol for current biometric type.
    var biometricIcon: String {
        switch biometricType {
        case "Face ID": return "faceid"
        case "Touch ID": return "touchid"
        case "Optic ID": return "opticid"
        default: return "lock.shield"
        }
    }

    // MARK: Public Methods

    /// Checks which biometric type is available on the device.
    func checkBiometricType() {
        var authError: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            switch context.biometryType {
            case .faceID: biometricType = "Face ID"
            case .touchID: biometricType = "Touch ID"
            case .opticID: biometricType = "Optic ID"
            @unknown default: biometricType = "Biometrics"
            }
        } else {
            biometricType = "Not Available"
            error = authError?.localizedDescription
        }
    }

    /// Authenticates the user using biometrics.
    /// - Parameter completion: Called with true if authentication succeeds.
    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var authError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            error = authError?.localizedDescription ?? "Biometrics not available"
            completion(false)
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock your secure vault"
        ) { success, error in
            Task { @MainActor in
                if success {
                    self.isAuthenticated = true
                    self.error = nil
                    self.loadItemsFromKeychain()
                    completion(true)
                } else {
                    self.error = error?.localizedDescription
                    completion(false)
                }
            }
        }
    }

    /// Locks the vault and clears sensitive data from memory.
    func lock() {
        isAuthenticated = false
        vaultItems = []
    }

    /// Adds an item to the vault and saves to keychain.
    func addItem(_ item: VaultItem) {
        vaultItems.append(item)
        saveItemsToKeychain()
    }

    /// Deletes an item from the vault.
    func deleteItem(_ item: VaultItem) {
        vaultItems.removeAll { $0.id == item.id }
        saveItemsToKeychain()
    }

    // MARK: Private Methods - Keychain Operations

    /// Saves all vault items to the keychain.
    private func saveItemsToKeychain() {
        guard let data = try? JSONEncoder().encode(vaultItems) else { return }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new data
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            error = "Failed to save to keychain: \(status)"
        }
    }

    /// Loads vault items from the keychain.
    private func loadItemsFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let items = try? JSONDecoder().decode([VaultItem].self, from: data) {
            vaultItems = items
        } else if status != errSecItemNotFound {
            // Only show error if it's not just "no items yet"
            error = "Failed to load from keychain"
        }
    }
}

#Preview {
    NavigationStack {
        BiometricsView()
    }
}
