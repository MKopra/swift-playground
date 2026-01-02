import SwiftUI
import Translation
import NaturalLanguage
import AVFoundation

// MARK: - Translation View (iOS 17.4+)

@available(iOS 17.4, *)
struct TranslationView: View {
    @State private var sourceText = ""
    @State private var detectedLanguage: Locale.Language?
    @State private var showSystemTranslation = false
    @State private var translationHistory: [TranslationEntry] = []

    struct TranslationEntry: Identifiable {
        let id = UUID()
        let originalText: String
        let timestamp: Date
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with privacy badge
                privacyBadge

                // Translation input
                translationInputSection

                // System translation button
                translateButton

                // Translation history
                historySection

                // Features section
                featuresSection

                // Supported languages info
                languagesInfoSection
            }
            .padding()
        }
        .navigationTitle("Translation")
        .navigationBarTitleDisplayMode(.inline)
        .translationPresentation(
            isPresented: $showSystemTranslation,
            text: sourceText
        )
    }

    // MARK: - Privacy Badge

    private var privacyBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.green)
            Text("On-Device Translation")
                .font(.subheadline.weight(.medium))
            Spacer()
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Translation Input Section

    private var translationInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Enter text to translate")
                    .font(.headline)
                Spacer()
                if !sourceText.isEmpty {
                    Button("Clear") {
                        sourceText = ""
                        detectedLanguage = nil
                    }
                    .font(.subheadline)
                }
            }

            TextField("Type or paste text here...", text: $sourceText, axis: .vertical)
                .lineLimit(3...8)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: sourceText) { _, newValue in
                    detectLanguage(text: newValue)
                }

            HStack {
                if let detected = detectedLanguage {
                    Label("Detected: \(languageDisplayName(detected))", systemImage: "wand.and.stars")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                Spacer()
                Text("\(sourceText.count) characters")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Translate Button

    private var translateButton: some View {
        VStack(spacing: 12) {
            Button {
                if !sourceText.isEmpty {
                    translationHistory.insert(
                        TranslationEntry(originalText: sourceText, timestamp: Date()),
                        at: 0
                    )
                }
                showSystemTranslation = true
            } label: {
                HStack {
                    Image(systemName: "translate")
                    Text("Translate with System UI")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(sourceText.isEmpty ? .gray : .blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(sourceText.isEmpty)

            Text("Opens Apple's translation interface with on-device processing")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Translations")
                    .font(.headline)
                Spacer()
                if !translationHistory.isEmpty {
                    Button("Clear") {
                        translationHistory = []
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
            }

            if translationHistory.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No translations yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
            } else {
                ForEach(translationHistory.prefix(5)) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.originalText)
                            .font(.subheadline)
                            .lineLimit(2)
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        sourceText = entry.originalText
                        showSystemTranslation = true
                    }
                }
            }
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Translation Features")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                featureCard(
                    icon: "brain.head.profile",
                    title: "Neural Engine",
                    description: "Apple Neural Engine powered"
                )
                featureCard(
                    icon: "iphone",
                    title: "On-Device",
                    description: "No internet required"
                )
                featureCard(
                    icon: "lock.fill",
                    title: "Private",
                    description: "Text never leaves device"
                )
                featureCard(
                    icon: "bolt.fill",
                    title: "Fast",
                    description: "Real-time translation"
                )
            }
        }
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Languages Info Section

    private var languagesInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supported Languages")
                .font(.headline)

            let languages = ["English", "Spanish", "French", "German", "Italian",
                           "Portuguese", "Chinese", "Japanese", "Korean", "Arabic",
                           "Russian", "Polish", "Dutch", "Turkish", "Thai",
                           "Vietnamese", "Indonesian", "Ukrainian", "Hindi"]

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(languages, id: \.self) { lang in
                        Text(lang)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            // Limitations
            VStack(alignment: .leading, spacing: 8) {
                Label("Notes", systemImage: "info.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)

                Text("• ~20 languages supported (vs 200+ in Google Translate)\n• Needs 10+ characters for language detection\n• Some languages require download\n• System UI provides best experience")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helper Functions

    private func detectLanguage(text: String) {
        guard text.count >= 10 else {
            detectedLanguage = nil
            return
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        if let dominantLanguage = recognizer.dominantLanguage {
            detectedLanguage = Locale.Language(identifier: dominantLanguage.rawValue)
        }
    }

    private func languageDisplayName(_ language: Locale.Language) -> String {
        Locale.current.localizedString(forIdentifier: language.minimalIdentifier) ?? language.minimalIdentifier
    }
}

// MARK: - Fallback for older iOS

struct TranslationViewFallback: View {
    var body: some View {
        ContentUnavailableView(
            "Translation Unavailable",
            systemImage: "character.bubble",
            description: Text("The Translation framework requires iOS 17.4 or later.")
        )
        .navigationTitle("Translation")
    }
}

// MARK: - Preview

#Preview {
    if #available(iOS 17.4, *) {
        NavigationStack {
            TranslationView()
        }
    } else {
        TranslationViewFallback()
    }
}
