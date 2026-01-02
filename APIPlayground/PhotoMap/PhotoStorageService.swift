import Foundation
import UIKit
import CoreLocation
import ComposableArchitecture

@DependencyClient
struct PhotoStorageClient {
    var savePhoto: @Sendable (_ image: UIImage, _ location: CLLocationCoordinate2D) async throws -> PhotoMarker = { _, _ in .preview }
    var fetchAllMarkers: @Sendable () async throws -> [PhotoMarker] = { [] }
    var deleteMarker: @Sendable (_ id: UUID) async throws -> Void = { _ in }
    var loadImage: @Sendable (_ marker: PhotoMarker) async throws -> UIImage = { _ in UIImage() }
}

extension PhotoStorageClient: DependencyKey {
    static let liveValue = PhotoStorageClient(
        savePhoto: { image, location in
            try await PhotoStorageService.shared.savePhoto(image, at: location)
        },
        fetchAllMarkers: {
            await PhotoStorageService.shared.fetchAllMarkers()
        },
        deleteMarker: { id in
            await PhotoStorageService.shared.deleteMarker(id)
        },
        loadImage: { marker in
            try await PhotoStorageService.shared.loadImage(for: marker)
        }
    )
}

extension DependencyValues {
    var photoStorage: PhotoStorageClient {
        get { self[PhotoStorageClient.self] }
        set { self[PhotoStorageClient.self] = newValue }
    }
}

actor PhotoStorageService {
    static let shared = PhotoStorageService()

    private let userDefaults = UserDefaults.standard
    private let markersKey = "photoMapMarkers"

    private var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDir = docs.appendingPathComponent("PhotoMapImages", isDirectory: true)

        if !FileManager.default.fileExists(atPath: photosDir.path) {
            try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
        }

        return photosDir
    }

    func savePhoto(_ image: UIImage, at location: CLLocationCoordinate2D) async throws -> PhotoMarker {
        let id = UUID()

        // Save full image
        let imageURL = photosDirectory.appendingPathComponent("\(id.uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoStorageError.imageConversionFailed
        }
        try imageData.write(to: imageURL)

        // Create thumbnail
        let thumbnail = createThumbnail(from: image, maxSize: 200)
        let thumbnailData = thumbnail.jpegData(compressionQuality: 0.6)

        // Create marker
        let marker = PhotoMarker(
            id: id,
            imageRecordID: id.uuidString,
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: Date(),
            thumbnailData: thumbnailData
        )

        // Save to UserDefaults
        var markers = loadMarkers()
        markers.insert(marker, at: 0)
        saveMarkers(markers)

        return marker
    }

    func fetchAllMarkers() async -> [PhotoMarker] {
        return loadMarkers()
    }

    func deleteMarker(_ id: UUID) async {
        // Delete image file
        let imageURL = photosDirectory.appendingPathComponent("\(id.uuidString).jpg")
        try? FileManager.default.removeItem(at: imageURL)

        // Remove from UserDefaults
        var markers = loadMarkers()
        markers.removeAll { $0.id == id }
        saveMarkers(markers)
    }

    func loadImage(for marker: PhotoMarker) async throws -> UIImage {
        let imageURL = photosDirectory.appendingPathComponent("\(marker.imageRecordID).jpg")

        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            throw PhotoStorageError.imageNotFound
        }

        return image
    }

    // MARK: - Private Helpers

    private func loadMarkers() -> [PhotoMarker] {
        guard let data = userDefaults.data(forKey: markersKey),
              let markers = try? JSONDecoder().decode([PhotoMarker].self, from: data) else {
            return []
        }
        return markers
    }

    private func saveMarkers(_ markers: [PhotoMarker]) {
        // Save without thumbnail data to keep UserDefaults small
        let markersForStorage = markers.map { marker -> PhotoMarker in
            var m = marker
            m.thumbnailData = nil
            return m
        }

        if let data = try? JSONEncoder().encode(markersForStorage) {
            userDefaults.set(data, forKey: markersKey)
        }
    }

    private func createThumbnail(from image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)

        if ratio >= 1 { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

enum PhotoStorageError: Error, LocalizedError {
    case imageNotFound
    case imageConversionFailed

    var errorDescription: String? {
        switch self {
        case .imageNotFound:
            return "Image not found"
        case .imageConversionFailed:
            return "Failed to convert image"
        }
    }
}
