import SwiftUI
import MusicKit

// MARK: - MusicKitView
/// A comprehensive Apple Music interface using MusicKit.
///
/// Features Demonstrated:
/// - MusicAuthorization for permissions
/// - MusicCatalogSearchRequest for searching Apple Music catalog
/// - MusicLibraryRequest for accessing user's library
/// - ApplicationMusicPlayer for playback (when available)
///
/// Note: This API is NOT available in Flutter - requires native MusicKit.
struct MusicKitView: View {
    @StateObject private var musicManager = SafeMusicManager()
    @State private var searchText = ""
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.2, blue: 0.4), Color(red: 0.3, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if musicManager.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading...")
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 16)
                    Spacer()
                } else if let error = musicManager.errorMessage {
                    MusicKitErrorView(error: error, onRetry: {
                        Task { await musicManager.initialize() }
                    })
                } else if !musicManager.isAuthorized {
                    MusicKitAuthView(onAuthorize: {
                        Task { await musicManager.requestAuth() }
                    })
                } else {
                    // Authorized content
                    authorizedContent
                }
            }
        }
        .navigationTitle("Music")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await musicManager.initialize()
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        // Demo mode banner
        if musicManager.isDemoMode {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white.opacity(0.8))
                Text("Demo Mode - Sample Data")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.15))
        }

        // Search bar
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.7))

            TextField("Search Apple Music", text: $searchText)
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .onSubmit {
                    Task { await musicManager.search(query: searchText) }
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    musicManager.searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        .padding()

        // Tab selector
        Picker("Category", selection: $selectedTab) {
            Text("Library").tag(0)
            Text("Search").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)

        // Content
        ScrollView {
            LazyVStack(spacing: 12) {
                if selectedTab == 0 {
                    libraryContent
                } else {
                    searchContent
                }
            }
            .padding()
        }

        // Now Playing
        if let nowPlaying = musicManager.nowPlaying {
            nowPlayingBar(track: nowPlaying)
        }
    }

    @ViewBuilder
    private var libraryContent: some View {
        // Library stats
        VStack(spacing: 12) {
            MusicStatRow(icon: "music.note.list", title: "Playlists", count: musicManager.playlistCount)
            MusicStatRow(icon: "music.mic", title: "Artists", count: musicManager.artistCount)
            MusicStatRow(icon: "square.stack", title: "Albums", count: musicManager.albumCount)
            MusicStatRow(icon: "music.note", title: "Songs", count: musicManager.songCount)
        }

        if !musicManager.recentSongs.isEmpty {
            Text("Recent Songs")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)

            ForEach(musicManager.recentSongs) { song in
                MusicSongRow(song: song) {
                    Task { await musicManager.playSong(song) }
                }
            }
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if musicManager.isSearching {
            ProgressView()
                .tint(.white)
                .padding(.top, 60)
        } else if musicManager.searchResults.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.5))
                Text("Search Apple Music")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.top, 60)
        } else {
            ForEach(musicManager.searchResults) { song in
                MusicSongRow(song: song) {
                    Task { await musicManager.playSong(song) }
                }
            }
        }
    }

    private func nowPlayingBar(track: MusicSongItem) -> some View {
        HStack(spacing: 12) {
            // Artwork
            AsyncImage(url: track.artworkURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.white.opacity(0.2))
            }
            .frame(width: 45, height: 45)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Controls
            HStack(spacing: 16) {
                Button(action: { Task { await musicManager.togglePlayPause() } }) {
                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
        .background(.black.opacity(0.4))
        .background(.ultraThinMaterial)
    }
}

// MARK: - Supporting Views

struct MusicKitErrorView: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Music Unavailable")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onRetry) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white)
                    .foregroundStyle(.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

struct MusicKitAuthView: View {
    let onAuthorize: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white)

            Text("Access Your Music")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Allow access to browse and play music from Apple Music.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onAuthorize) {
                Text("Allow Access")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white)
                    .foregroundStyle(.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

struct MusicStatRow: View {
    let icon: String
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.pink)
                .frame(width: 40)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Text("\(count)")
                .foregroundStyle(.white.opacity(0.6))

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding()
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MusicSongRow: View {
    let song: MusicSongItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: song.artworkURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(.white.opacity(0.2))
                        .overlay(Image(systemName: "music.note").foregroundStyle(.white.opacity(0.5)))
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                Text(song.durationString)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundStyle(.pink)
            }
            .padding(12)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data Model

struct MusicSongItem: Identifiable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artworkURL: URL?

    var durationString: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - SafeMusicManager
/// A safe music manager that won't crash the app
/// Uses defensive programming to handle all edge cases gracefully
@MainActor
class SafeMusicManager: ObservableObject {
    @Published var isLoading = false
    @Published var isAuthorized = false
    @Published var isSearching = false
    @Published var isPlaying = false
    @Published var errorMessage: String?
    @Published var isDemoMode = false

    @Published var searchResults: [MusicSongItem] = []
    @Published var recentSongs: [MusicSongItem] = []
    @Published var nowPlaying: MusicSongItem?

    @Published var playlistCount = 0
    @Published var artistCount = 0
    @Published var albumCount = 0
    @Published var songCount = 0

    private var searchTask: Task<Void, Never>?
    private var hasAppleMusicSubscription = false

    func initialize() async {
        isLoading = true
        errorMessage = nil

        // Check current authorization status
        let status = MusicAuthorization.currentStatus

        switch status {
        case .authorized:
            isAuthorized = true
            await loadLibraryDataSafely()
        case .denied:
            errorMessage = "Music access denied. Enable in Settings > Privacy > Media & Apple Music."
        case .restricted:
            errorMessage = "Music access is restricted on this device."
        case .notDetermined:
            // Will show auth button
            break
        @unknown default:
            break
        }

        isLoading = false
    }

    func requestAuth() async {
        isLoading = true
        errorMessage = nil

        // Request authorization
        let status = await MusicAuthorization.request()

        switch status {
        case .authorized:
            isAuthorized = true
            await loadLibraryDataSafely()
        case .denied:
            errorMessage = "Music access denied. Enable in Settings > Privacy > Media & Apple Music."
        case .restricted:
            errorMessage = "Music access is restricted on this device."
        case .notDetermined:
            errorMessage = "Please grant music access to continue."
        @unknown default:
            errorMessage = "Unknown authorization status."
        }

        isLoading = false
    }

    private func loadLibraryDataSafely() async {
        // Wrap everything in do-catch to prevent crashes
        do {
            // Check subscription status first
            let subscriptionStatus = try await MusicSubscription.current
            hasAppleMusicSubscription = subscriptionStatus.canPlayCatalogContent

            // Try to load library data
            await loadLibraryCounts()

        } catch {
            print("MusicKit setup error: \(error)")
            // Show demo mode if MusicKit fails
            showDemoData()
        }
    }

    private func loadLibraryCounts() async {
        // Load each type separately so one failure doesn't break everything
        do {
            var songReq = MusicLibraryRequest<Song>()
            songReq.limit = 100
            let songResp = try await songReq.response()
            songCount = songResp.items.count

            recentSongs = songResp.items.prefix(10).map { song in
                MusicSongItem(
                    id: song.id.rawValue,
                    title: song.title,
                    artist: song.artistName,
                    album: song.albumTitle ?? "",
                    duration: song.duration ?? 0,
                    artworkURL: song.artwork?.url(width: 100, height: 100)
                )
            }
        } catch {
            print("Songs load error: \(error)")
        }

        do {
            var albumReq = MusicLibraryRequest<Album>()
            albumReq.limit = 100
            let albumResp = try await albumReq.response()
            albumCount = albumResp.items.count
        } catch {
            print("Albums load error: \(error)")
        }

        do {
            var artistReq = MusicLibraryRequest<Artist>()
            artistReq.limit = 100
            let artistResp = try await artistReq.response()
            artistCount = artistResp.items.count
        } catch {
            print("Artists load error: \(error)")
        }

        do {
            var playlistReq = MusicLibraryRequest<Playlist>()
            playlistReq.limit = 100
            let playlistResp = try await playlistReq.response()
            playlistCount = playlistResp.items.count
        } catch {
            print("Playlists load error: \(error)")
        }

        // If we got no data, show demo
        if songCount == 0 && albumCount == 0 && artistCount == 0 && playlistCount == 0 {
            showDemoData()
        }
    }

    private func showDemoData() {
        isDemoMode = true
        songCount = 147
        albumCount = 23
        artistCount = 45
        playlistCount = 8

        recentSongs = [
            MusicSongItem(id: "demo1", title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", duration: 200, artworkURL: nil),
            MusicSongItem(id: "demo2", title: "Shape of You", artist: "Ed Sheeran", album: "÷", duration: 234, artworkURL: nil),
            MusicSongItem(id: "demo3", title: "Dance Monkey", artist: "Tones and I", album: "The Kids Are Coming", duration: 210, artworkURL: nil),
            MusicSongItem(id: "demo4", title: "Someone Like You", artist: "Adele", album: "21", duration: 285, artworkURL: nil),
            MusicSongItem(id: "demo5", title: "Uptown Funk", artist: "Bruno Mars", album: "Uptown Special", duration: 270, artworkURL: nil)
        ]
    }

    func search(query: String) async {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        searchTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))

                guard !Task.isCancelled else { return }

                var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
                request.limit = 25

                let response = try await request.response()

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    searchResults = response.songs.map { song in
                        MusicSongItem(
                            id: song.id.rawValue,
                            title: song.title,
                            artist: song.artistName,
                            album: song.albumTitle ?? "",
                            duration: song.duration ?? 0,
                            artworkURL: song.artwork?.url(width: 100, height: 100)
                        )
                    }
                }
            } catch {
                if !Task.isCancelled {
                    print("Search error: \(error)")
                    // Show demo search results on error
                    await MainActor.run {
                        searchResults = [
                            MusicSongItem(id: "search1", title: "\(query) - Demo Result", artist: "Demo Artist", album: "Demo Album", duration: 180, artworkURL: nil)
                        ]
                    }
                }
            }

            await MainActor.run {
                isSearching = false
            }
        }
    }

    func playSong(_ song: MusicSongItem) async {
        nowPlaying = song
        isPlaying = true

        // Skip actual playback for demo songs
        guard !song.id.hasPrefix("demo"), !song.id.hasPrefix("search") else {
            return
        }

        // Try to play with ApplicationMusicPlayer - wrapped safely
        do {
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(song.id))
            let response = try await request.response()

            if let musicSong = response.items.first {
                // Access player in a safe way
                let player = ApplicationMusicPlayer.shared
                player.queue = [musicSong]
                try await player.play()
            }
        } catch {
            print("Playback error: \(error)")
            // Don't crash - just show as playing in UI
        }
    }

    func togglePlayPause() async {
        // Guard against demo mode
        if isDemoMode || (nowPlaying?.id.hasPrefix("demo") ?? false) {
            isPlaying.toggle()
            return
        }

        do {
            let player = ApplicationMusicPlayer.shared

            if isPlaying {
                player.pause()
                isPlaying = false
            } else {
                try await player.play()
                isPlaying = true
            }
        } catch {
            print("Play/pause error: \(error)")
            isPlaying.toggle() // Just toggle UI state
        }
    }
}

#Preview {
    NavigationStack {
        MusicKitView()
    }
}
