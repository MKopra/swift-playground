import SwiftUI
import CoreSpotlight
import MobileCoreServices
import UniformTypeIdentifiers

// MARK: - Core Spotlight Demo View

struct SpotlightView: View {
    @State private var indexedItems: [SpotlightItem] = []
    @State private var isIndexing = false
    @State private var indexedCount = 0
    @State private var showAddItem = false
    @State private var newItemTitle = ""
    @State private var newItemDescription = ""
    @State private var selectedCategory: ItemCategory = .note
    @State private var searchQuery = ""
    @State private var searchResults: [SpotlightItem] = []
    @State private var showSearchResults = false
    @State private var statusMessage: String?
    @State private var lastIndexedDate: Date?

    enum ItemCategory: String, CaseIterable, Identifiable {
        case note = "Note"
        case contact = "Contact"
        case recipe = "Recipe"
        case bookmark = "Bookmark"
        case task = "Task"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .note: return "note.text"
            case .contact: return "person.circle"
            case .recipe: return "fork.knife"
            case .bookmark: return "bookmark"
            case .task: return "checkmark.circle"
            }
        }

        var color: Color {
            switch self {
            case .note: return .yellow
            case .contact: return .blue
            case .recipe: return .orange
            case .bookmark: return .purple
            case .task: return .green
            }
        }
    }

    struct SpotlightItem: Identifiable, Codable {
        let id: String
        let title: String
        let description: String
        let category: String
        let keywords: [String]
        let dateCreated: Date
        var isIndexed: Bool

        init(title: String, description: String, category: ItemCategory) {
            self.id = UUID().uuidString
            self.title = title
            self.description = description
            self.category = category.rawValue
            self.keywords = Self.generateKeywords(title: title, description: description, category: category)
            self.dateCreated = Date()
            self.isIndexed = false
        }

        static func generateKeywords(title: String, description: String, category: ItemCategory) -> [String] {
            var keywords = title.lowercased().components(separatedBy: " ")
            keywords += description.lowercased().components(separatedBy: " ").prefix(5)
            keywords.append(category.rawValue.lowercased())
            keywords.append("apiplayground")
            return keywords.filter { $0.count > 2 }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Stats
                statsHeader

                // Quick Actions
                quickActions

                // Search Demo
                searchSection

                // Indexed Items
                indexedItemsSection

                // How It Works
                howItWorksSection
            }
            .padding()
        }
        .navigationTitle("Core Spotlight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            addItemSheet
        }
        .onAppear {
            loadItems()
            updateIndexedCount()
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Indexed",
                value: "\(indexedItems.filter { $0.isIndexed }.count)",
                icon: "magnifyingglass",
                color: .blue
            )

            StatCard(
                title: "Total Items",
                value: "\(indexedItems.count)",
                icon: "doc.text",
                color: .gray
            )

            StatCard(
                title: "Categories",
                value: "\(Set(indexedItems.map { $0.category }).count)",
                icon: "folder",
                color: .orange
            )
        }
    }

    struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title2.weight(.bold))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                Button {
                    Task {
                        await addSampleItems()
                    }
                } label: {
                    Label("Add Samples", systemImage: "plus.rectangle.on.folder")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    Task {
                        await indexAllItems()
                    }
                } label: {
                    HStack {
                        if isIndexing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isIndexing ? "Indexing..." : "Index All")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isIndexing || indexedItems.isEmpty)
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        await removeAllFromIndex()
                    }
                } label: {
                    Label("Clear Index", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    openSpotlight()
                } label: {
                    Label("Open Spotlight", systemImage: "magnifyingglass")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.opacity(0.1))
                        .foregroundStyle(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if let message = statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In-App Search (via Spotlight Index)")
                .font(.headline)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search indexed items...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onChange(of: searchQuery) { _, newValue in
                        Task {
                            await searchSpotlight(query: newValue)
                        }
                    }
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if !searchResults.isEmpty {
                VStack(spacing: 8) {
                    ForEach(searchResults) { item in
                        searchResultRow(item)
                    }
                }
            } else if !searchQuery.isEmpty && searchQuery.count >= 2 {
                Text("No results found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    private func searchResultRow(_ item: SpotlightItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ItemCategory(rawValue: item.category)?.icon ?? "doc")
                .font(.title3)
                .foregroundStyle(ItemCategory(rawValue: item.category)?.color ?? .gray)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if item.isIndexed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Indexed Items Section

    private var indexedItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Items")
                    .font(.headline)
                Spacer()
                if !indexedItems.isEmpty {
                    Button("Clear All") {
                        Task {
                            await clearAllItems()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
            }

            if indexedItems.isEmpty {
                ContentUnavailableView(
                    "No Items Yet",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Add items to index them in Spotlight search")
                )
                .frame(height: 150)
            } else {
                ForEach(ItemCategory.allCases) { category in
                    let categoryItems = indexedItems.filter { $0.category == category.rawValue }
                    if !categoryItems.isEmpty {
                        categorySection(category: category, items: categoryItems)
                    }
                }
            }
        }
    }

    private func categorySection(category: ItemCategory, items: [SpotlightItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                Text(category.rawValue)
                    .font(.subheadline.weight(.medium))
                Text("(\(items.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(items) { item in
                itemRow(item)
            }
        }
    }

    private func itemRow(_ item: SpotlightItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Index status toggle
            Button {
                Task {
                    if item.isIndexed {
                        await removeFromIndex(item)
                    } else {
                        await addToIndex(item)
                    }
                }
            } label: {
                Image(systemName: item.isIndexed ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    .font(.title2)
                    .foregroundStyle(item.isIndexed ? .blue : .secondary)
            }

            // Delete button
            Button {
                Task {
                    await deleteItem(item)
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How Spotlight Indexing Works")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                howItWorksRow(
                    number: 1,
                    title: "Create Searchable Items",
                    description: "Add titles, descriptions, and keywords to CSSearchableItem"
                )
                howItWorksRow(
                    number: 2,
                    title: "Index to Spotlight",
                    description: "Use CSSearchableIndex.default() to add items"
                )
                howItWorksRow(
                    number: 3,
                    title: "User Searches",
                    description: "Items appear in iOS Spotlight search"
                )
                howItWorksRow(
                    number: 4,
                    title: "Deep Link Back",
                    description: "Tapping result opens app via NSUserActivity"
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

                Text("• Index is private to your app\n• Max ~thousands of items recommended\n• Content must be refreshed periodically\n• Semantic search requires iOS 18+")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func howItWorksRow(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Add Item Sheet

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Title", text: $newItemTitle)
                    TextField("Description", text: $newItemDescription)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ItemCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section {
                    Button("Add & Index") {
                        Task {
                            await addNewItem(andIndex: true)
                        }
                    }
                    .disabled(newItemTitle.isEmpty)

                    Button("Add Only (Don't Index)") {
                        Task {
                            await addNewItem(andIndex: false)
                        }
                    }
                    .disabled(newItemTitle.isEmpty)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showAddItem = false
                    }
                }
            }
        }
    }

    // MARK: - Spotlight Functions

    private func addNewItem(andIndex: Bool) async {
        var item = SpotlightItem(
            title: newItemTitle,
            description: newItemDescription.isEmpty ? "No description" : newItemDescription,
            category: selectedCategory
        )

        if andIndex {
            await addToIndex(item)
            item.isIndexed = true
        }

        indexedItems.append(item)
        saveItems()

        newItemTitle = ""
        newItemDescription = ""
        showAddItem = false

        statusMessage = andIndex ? "Item added and indexed" : "Item added (not indexed)"
    }

    private func addToIndex(_ item: SpotlightItem) async {
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.text)
        attributeSet.title = item.title
        attributeSet.contentDescription = item.description
        attributeSet.keywords = item.keywords

        // Add category-specific attributes
        if let category = ItemCategory(rawValue: item.category) {
            switch category {
            case .contact:
                attributeSet.contentType = UTType.contact.identifier
            case .note:
                attributeSet.contentType = UTType.text.identifier
            default:
                break
            }
        }

        let searchableItem = CSSearchableItem(
            uniqueIdentifier: item.id,
            domainIdentifier: "com.apiplayground.spotlight",
            attributeSet: attributeSet
        )

        // Items expire after 30 days by default, extend to 1 year
        searchableItem.expirationDate = Date().addingTimeInterval(365 * 24 * 60 * 60)

        do {
            try await CSSearchableIndex.default().indexSearchableItems([searchableItem])

            if let index = indexedItems.firstIndex(where: { $0.id == item.id }) {
                indexedItems[index].isIndexed = true
                saveItems()
            }

            statusMessage = "Indexed: \(item.title)"
        } catch {
            statusMessage = "Failed to index: \(error.localizedDescription)"
        }
    }

    private func removeFromIndex(_ item: SpotlightItem) async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [item.id])

            if let index = indexedItems.firstIndex(where: { $0.id == item.id }) {
                indexedItems[index].isIndexed = false
                saveItems()
            }

            statusMessage = "Removed from index: \(item.title)"
        } catch {
            statusMessage = "Failed to remove: \(error.localizedDescription)"
        }
    }

    private func indexAllItems() async {
        isIndexing = true
        var indexed = 0

        for item in indexedItems where !item.isIndexed {
            await addToIndex(item)
            indexed += 1
        }

        isIndexing = false
        statusMessage = "Indexed \(indexed) items"
        lastIndexedDate = Date()
    }

    private func removeAllFromIndex() async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.apiplayground.spotlight"])

            for i in indexedItems.indices {
                indexedItems[i].isIndexed = false
            }
            saveItems()

            statusMessage = "Cleared all indexed items"
        } catch {
            statusMessage = "Failed to clear index: \(error.localizedDescription)"
        }
    }

    private func deleteItem(_ item: SpotlightItem) async {
        if item.isIndexed {
            await removeFromIndex(item)
        }

        indexedItems.removeAll { $0.id == item.id }
        saveItems()
    }

    private func clearAllItems() async {
        await removeAllFromIndex()
        indexedItems = []
        saveItems()
        statusMessage = "All items cleared"
    }

    private func searchSpotlight(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }

        let queryString = "title == \"*\(query)*\"cd || contentDescription == \"*\(query)*\"cd"
        let searchQuery = CSSearchQuery(queryString: queryString, attributes: ["title", "contentDescription"])

        var foundIds: [String] = []

        searchQuery.foundItemsHandler = { items in
            foundIds.append(contentsOf: items.map { $0.uniqueIdentifier })
        }

        searchQuery.completionHandler = { error in
            if let error = error {
                print("Search error: \(error)")
            }
        }

        searchQuery.start()

        // Wait a bit for results
        try? await Task.sleep(nanoseconds: 300_000_000)
        searchQuery.cancel()

        // Match with local items
        searchResults = indexedItems.filter { item in
            foundIds.contains(item.id) ||
            item.title.localizedCaseInsensitiveContains(query) ||
            item.description.localizedCaseInsensitiveContains(query)
        }
    }

    private func openSpotlight() {
        // Can't programmatically open Spotlight, but we can guide the user
        statusMessage = "Swipe down on home screen to open Spotlight and search for your indexed items"
    }

    private func addSampleItems() async {
        let samples: [(String, String, ItemCategory)] = [
            ("Meeting Notes", "Discussed Q4 roadmap and timeline", .note),
            ("John Smith", "Product Manager at Acme Corp", .contact),
            ("Pasta Carbonara", "Classic Italian pasta with eggs and pancetta", .recipe),
            ("SwiftUI Documentation", "Apple's official SwiftUI tutorials", .bookmark),
            ("Finish API Demo", "Complete the Spotlight integration demo", .task),
            ("Project Ideas", "List of potential features to implement", .note),
            ("Jane Doe", "iOS Developer, met at WWDC", .contact),
            ("Chicken Tikka Masala", "Creamy Indian curry dish", .recipe),
            ("Core Data Guide", "Ray Wenderlich tutorial bookmark", .bookmark),
            ("Review Pull Request", "Check teammate's code submission", .task)
        ]

        for (title, desc, category) in samples {
            // Don't add duplicates
            if !indexedItems.contains(where: { $0.title == title }) {
                let item = SpotlightItem(title: title, description: desc, category: category)
                indexedItems.append(item)
            }
        }

        saveItems()
        statusMessage = "Added sample items"
    }

    // MARK: - Persistence

    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(indexedItems) {
            UserDefaults.standard.set(encoded, forKey: "spotlightItems")
        }
    }

    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: "spotlightItems"),
           let decoded = try? JSONDecoder().decode([SpotlightItem].self, from: data) {
            indexedItems = decoded
        }
    }

    private func updateIndexedCount() {
        CSSearchableIndex.default().fetchLastClientState { data, error in
            // This gives us info about the index state
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SpotlightView()
    }
}
