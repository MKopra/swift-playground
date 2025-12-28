import SwiftUI
import Contacts
import ContactsUI

// MARK: - ContactsView
/// Comprehensive demonstration of Contacts and ContactsUI frameworks.
///
/// Features:
/// - Contact browsing and search
/// - Contact picker integration
/// - Contact creation and editing
/// - Contact groups management
/// - Phone/email extraction
/// - Contact images
/// - vCard import/export
/// - Contact linking
///
/// APIs Demonstrated:
/// - CNContactStore for data access
/// - CNContact for contact data
/// - CNContactPickerViewController for selection
/// - CNContactViewController for viewing/editing
/// - CNSaveRequest for modifications
/// - CNContactFetchRequest for queries
///
/// Note: Requires NSContactsUsageDescription in Info.plist.
struct ContactsView: View {
    @StateObject private var contactsManager = ContactsManager()
    @State private var searchText = ""
    @State private var showingContactPicker = false
    @State private var showingNewContact = false
    @State private var selectedContact: CNContact?
    @State private var showingContactDetail = false

    // New contact fields
    @State private var newFirstName = ""
    @State private var newLastName = ""
    @State private var newPhoneNumber = ""
    @State private var newEmail = ""

    var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contactsManager.contacts
        }
        return contactsManager.contacts.filter {
            $0.givenName.localizedCaseInsensitiveContains(searchText) ||
            $0.familyName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Authorization Card
                authorizationCard

                // Quick Actions
                quickActionsCard

                // Search and Contact List
                if contactsManager.isAuthorized {
                    contactListCard
                }

                // Selected Contact Details
                if let contact = selectedContact {
                    selectedContactCard(contact)
                }

                // Statistics
                statisticsCard

                // API Info
                apiInfoCard
            }
            .padding()
        }
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search contacts")
        .sheet(isPresented: $showingContactPicker) {
            ContactPickerView(selectedContact: $selectedContact)
        }
        .sheet(isPresented: $showingNewContact) {
            newContactSheet
        }
        .sheet(isPresented: $showingContactDetail) {
            if let contact = selectedContact {
                ContactDetailView(contact: contact)
            }
        }
        .onAppear {
            contactsManager.requestAccess()
        }
    }

    // MARK: - Authorization Card
    private var authorizationCard: some View {
        GroupBox {
            HStack {
                Image(systemName: contactsManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(contactsManager.isAuthorized ? .green : .red)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(contactsManager.isAuthorized ? "Contacts Access Granted" : "Contacts Access Required")
                        .font(.headline)
                    Text(contactsManager.authorizationStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !contactsManager.isAuthorized {
                    Button("Request") {
                        contactsManager.requestAccess()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } label: {
            Label("Authorization", systemImage: "lock.shield")
        }
    }

    // MARK: - Quick Actions Card
    private var quickActionsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ActionButton(
                        title: "Pick Contact",
                        icon: "person.crop.circle.badge.plus",
                        color: .blue
                    ) {
                        showingContactPicker = true
                    }
                    .disabled(!contactsManager.isAuthorized)

                    ActionButton(
                        title: "New Contact",
                        icon: "person.badge.plus",
                        color: .green
                    ) {
                        showingNewContact = true
                    }
                    .disabled(!contactsManager.isAuthorized)
                }

                HStack(spacing: 12) {
                    ActionButton(
                        title: "Refresh",
                        icon: "arrow.clockwise",
                        color: .orange
                    ) {
                        contactsManager.fetchContacts()
                    }
                    .disabled(!contactsManager.isAuthorized)

                    ActionButton(
                        title: "Export vCard",
                        icon: "square.and.arrow.up",
                        color: .purple
                    ) {
                        if let contact = selectedContact {
                            contactsManager.exportVCard(contact)
                        }
                    }
                    .disabled(selectedContact == nil)
                }
            }
        } label: {
            Label("Actions", systemImage: "hand.tap")
        }
    }

    // MARK: - Contact List Card
    private var contactListCard: some View {
        GroupBox {
            if contactsManager.isLoading {
                ProgressView("Loading contacts...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if filteredContacts.isEmpty {
                Text(searchText.isEmpty ? "No contacts found" : "No matches for '\(searchText)'")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredContacts.prefix(20), id: \.identifier) { contact in
                        ContactRow(
                            contact: contact,
                            isSelected: selectedContact?.identifier == contact.identifier
                        )
                        .onTapGesture {
                            selectedContact = contact
                        }

                        if contact.identifier != filteredContacts.prefix(20).last?.identifier {
                            Divider()
                        }
                    }

                    if filteredContacts.count > 20 {
                        Text("+ \(filteredContacts.count - 20) more contacts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
        } label: {
            Label("Contacts (\(filteredContacts.count))", systemImage: "person.2")
        }
    }

    // MARK: - Selected Contact Card
    private func selectedContactCard(_ contact: CNContact) -> some View {
        GroupBox {
            VStack(spacing: 16) {
                // Contact header
                HStack {
                    ContactAvatar(contact: contact, size: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown")
                            .font(.headline)

                        if !contact.organizationName.isEmpty {
                            Text(contact.organizationName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: { showingContactDetail = true }) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                    }
                }

                Divider()

                // Phone numbers
                if !contact.phoneNumbers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Numbers")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(contact.phoneNumbers, id: \.identifier) { phone in
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.green)
                                    .frame(width: 24)

                                VStack(alignment: .leading) {
                                    Text(phone.value.stringValue)
                                        .font(.subheadline)
                                    Text(CNLabeledValue<NSString>.localizedString(forLabel: phone.label ?? ""))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button(action: {
                                    UIPasteboard.general.string = phone.value.stringValue
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }

                // Email addresses
                if !contact.emailAddresses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Addresses")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(contact.emailAddresses, id: \.identifier) { email in
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)

                                VStack(alignment: .leading) {
                                    Text(email.value as String)
                                        .font(.subheadline)
                                    Text(CNLabeledValue<NSString>.localizedString(forLabel: email.label ?? ""))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button(action: {
                                    UIPasteboard.general.string = email.value as String
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }

                // Addresses
                if !contact.postalAddresses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Addresses")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(contact.postalAddresses, id: \.identifier) { address in
                            HStack(alignment: .top) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.red)
                                    .frame(width: 24)

                                Text(CNPostalAddressFormatter.string(from: address.value, style: .mailingAddress))
                                    .font(.subheadline)

                                Spacer()
                            }
                        }
                    }
                }
            }
        } label: {
            Label("Selected Contact", systemImage: "person.crop.circle")
        }
    }

    // MARK: - Statistics Card
    private var statisticsCard: some View {
        GroupBox {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatItem(value: "\(contactsManager.contacts.count)", label: "Contacts")
                StatItem(value: "\(contactsManager.groups.count)", label: "Groups")
                StatItem(value: "\(contactsManager.containers.count)", label: "Containers")
            }
        } label: {
            Label("Statistics", systemImage: "chart.bar")
        }
    }

    // MARK: - API Info Card
    private var apiInfoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                CNInfoRow(title: "Framework", value: "Contacts + ContactsUI")
                CNInfoRow(title: "Min iOS", value: "9.0+")
                CNInfoRow(title: "Privacy Key", value: "NSContactsUsageDescription")
                CNInfoRow(title: "Storage", value: "On-device + iCloud")

                Divider()

                Text("The Contacts framework provides access to the user's contact data. ContactsUI provides pre-built UI for contact selection and viewing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("API Information", systemImage: "info.circle")
        }
    }

    // MARK: - New Contact Sheet
    private var newContactSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("First Name", text: $newFirstName)
                    TextField("Last Name", text: $newLastName)
                }

                Section("Contact Info") {
                    TextField("Phone Number", text: $newPhoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingNewContact = false
                        clearNewContactFields()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        createContact()
                        showingNewContact = false
                        clearNewContactFields()
                    }
                    .disabled(newFirstName.isEmpty && newLastName.isEmpty)
                }
            }
        }
    }

    private func createContact() {
        contactsManager.createContact(
            firstName: newFirstName,
            lastName: newLastName,
            phone: newPhoneNumber.isEmpty ? nil : newPhoneNumber,
            email: newEmail.isEmpty ? nil : newEmail
        )
    }

    private func clearNewContactFields() {
        newFirstName = ""
        newLastName = ""
        newPhoneNumber = ""
        newEmail = ""
    }
}

// MARK: - ActionButton
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ContactRow
struct ContactRow: View {
    let contact: CNContact
    let isSelected: Bool

    var body: some View {
        HStack {
            ContactAvatar(contact: contact, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown")
                    .font(.subheadline)

                if !contact.organizationName.isEmpty {
                    Text(contact.organizationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let phone = contact.phoneNumbers.first {
                    Text(phone.value.stringValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - ContactAvatar
struct ContactAvatar: View {
    let contact: CNContact
    let size: CGFloat

    var body: some View {
        Group {
            if let imageData = contact.thumbnailImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - StatItem
struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - CNInfoRow
struct CNInfoRow: View {
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

// MARK: - ContactPickerView
struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var selectedContact: CNContact?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.selectedContact = contact
            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - ContactDetailView
struct ContactDetailView: UIViewControllerRepresentable {
    let contact: CNContact
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = false
        contactVC.allowsActions = true

        let navController = UINavigationController(rootViewController: contactVC)
        contactVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.dismiss)
        )
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: ContactDetailView

        init(_ parent: ContactDetailView) {
            self.parent = parent
        }

        @objc func dismiss() {
            parent.dismiss()
        }
    }
}

// MARK: - ContactsManager
@MainActor
class ContactsManager: ObservableObject {
    @Published var contacts: [CNContact] = []
    @Published var groups: [CNGroup] = []
    @Published var containers: [CNContainer] = []
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var authorizationStatus = "Unknown"

    private let contactStore = CNContactStore()

    private let keysToFetch: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactPostalAddressesKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
        CNContactViewController.descriptorForRequiredKeys()
    ]

    func requestAccess() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        updateAuthorizationStatus(status)

        if status == .notDetermined {
            contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
                Task { @MainActor in
                    self?.isAuthorized = granted
                    self?.updateAuthorizationStatus(CNContactStore.authorizationStatus(for: .contacts))
                    if granted {
                        self?.fetchContacts()
                        self?.fetchGroups()
                        self?.fetchContainers()
                    }
                }
            }
        } else if status == .authorized {
            isAuthorized = true
            fetchContacts()
            fetchGroups()
            fetchContainers()
        }
    }

    private func updateAuthorizationStatus(_ status: CNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            authorizationStatus = "Not Determined"
        case .restricted:
            authorizationStatus = "Restricted"
        case .denied:
            authorizationStatus = "Denied"
        case .authorized:
            authorizationStatus = "Authorized"
            isAuthorized = true
        case .limited:
            authorizationStatus = "Limited"
            isAuthorized = true
        @unknown default:
            authorizationStatus = "Unknown"
        }
    }

    func fetchContacts() {
        isLoading = true

        // Copy values to avoid actor isolation issues
        let keys = keysToFetch
        let store = contactStore

        DispatchQueue.global(qos: .userInitiated).async {
            var allContacts: [CNContact] = []
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .givenName

            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    allContacts.append(contact)
                }

                Task { @MainActor [weak self] in
                    self?.contacts = allContacts
                    self?.isLoading = false
                }
            } catch {
                print("Error fetching contacts: \(error)")
                Task { @MainActor [weak self] in
                    self?.isLoading = false
                }
            }
        }
    }

    func fetchGroups() {
        do {
            groups = try contactStore.groups(matching: nil)
        } catch {
            print("Error fetching groups: \(error)")
        }
    }

    func fetchContainers() {
        do {
            containers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers: \(error)")
        }
    }

    func createContact(firstName: String, lastName: String, phone: String?, email: String?) {
        let contact = CNMutableContact()
        contact.givenName = firstName
        contact.familyName = lastName

        if let phone = phone {
            contact.phoneNumbers = [
                CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phone))
            ]
        }

        if let email = email {
            contact.emailAddresses = [
                CNLabeledValue(label: CNLabelWork, value: email as NSString)
            ]
        }

        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)

        do {
            try contactStore.execute(saveRequest)
            fetchContacts()
        } catch {
            print("Error saving contact: \(error)")
        }
    }

    func exportVCard(_ contact: CNContact) {
        do {
            let vCardData = try CNContactVCardSerialization.data(with: [contact])
            let activityVC = UIActivityViewController(
                activityItems: [vCardData],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting vCard: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        ContactsView()
    }
}
