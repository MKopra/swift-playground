import Foundation
import CloudKit
import UIKit
import ComposableArchitecture

@DependencyClient
struct CloudKitPhotoClient {
    var checkContainerAccess: @Sendable () async throws -> String = { "" }
    var uploadPhoto: @Sendable (_ image: UIImage, _ location: CLLocationCoordinate2D) async throws -> PhotoMarker
    var fetchAllMarkers: @Sendable () async throws -> [PhotoMarker]
    var deleteMarker: @Sendable (_ id: UUID) async throws -> Void
    var downloadFullImage: @Sendable (_ marker: PhotoMarker) async throws -> UIImage
}

extension CloudKitPhotoClient: DependencyKey {
    static let liveValue = CloudKitPhotoClient(
        checkContainerAccess: {
            try await CloudKitPhotoService.shared.checkContainerAccess()
        },
        uploadPhoto: { image, location in
            try await CloudKitPhotoService.shared.uploadPhoto(image, at: location)
        },
        fetchAllMarkers: {
            try await CloudKitPhotoService.shared.fetchAllMarkers()
        },
        deleteMarker: { id in
            try await CloudKitPhotoService.shared.deleteMarker(id)
        },
        downloadFullImage: { marker in
            try await CloudKitPhotoService.shared.downloadFullImage(for: marker)
        }
    )
}

extension DependencyValues {
    var cloudKitPhoto: CloudKitPhotoClient {
        get { self[CloudKitPhotoClient.self] }
        set { self[CloudKitPhotoClient.self] = newValue }
    }
}

actor CloudKitPhotoService {
    static let shared = CloudKitPhotoService()

    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "PhotoMarker"
    private let kvStore = NSUbiquitousKeyValueStore.default

    private init() {
        // Try default container first
        container = CKContainer.default()
        database = container.privateCloudDatabase
    }

    func checkContainerAccess() async throws -> String {
        var statusInfo = "Container ID: \(container.containerIdentifier ?? "nil")\n"

        // Check account status
        do {
            let accountStatus = try await container.accountStatus()
            statusInfo += "Account Status: \(accountStatusString(accountStatus))\n"
        } catch {
            statusInfo += "Account Status Error: \(error.localizedDescription)\n"
            statusInfo += formatError(error)
            throw CloudKitPhotoError.containerAccessFailed(statusInfo)
        }

        // Try to get user record ID to verify access
        do {
            let userRecordID = try await container.userRecordID()
            statusInfo += "User Record ID: \(userRecordID.recordName)\n"
            statusInfo += "Status: OK"
        } catch {
            statusInfo += "User Record Error: \(error.localizedDescription)\n"
            statusInfo += formatError(error)
            throw CloudKitPhotoError.containerAccessFailed(statusInfo)
        }

        return statusInfo
    }

    private func formatError(_ error: Error) -> String {
        var result = ""
        if let ckError = error as? CKError {
            result += "CKError Code: \(ckError.code.rawValue) (\(ckError.code))\n"
            for (key, value) in ckError.userInfo {
                result += "  \(key): \(value)\n"
            }
        } else {
            let nsError = error as NSError
            result += "Domain: \(nsError.domain)\n"
            result += "Code: \(nsError.code)\n"
            for (key, value) in nsError.userInfo {
                result += "  \(key): \(value)\n"
            }
        }
        return result
    }

    private func accountStatusString(_ status: CKAccountStatus) -> String {
        switch status {
        case .available: return "Available"
        case .noAccount: return "No Account"
        case .restricted: return "Restricted"
        case .couldNotDetermine: return "Could Not Determine"
        case .temporarilyUnavailable: return "Temporarily Unavailable"
        @unknown default: return "Unknown (\(status.rawValue))"
        }
    }

    func uploadPhoto(_ image: UIImage, at location: CLLocationCoordinate2D) async throws -> PhotoMarker {
        let recordID = CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        // Save full image as asset
        let imageURL = try saveImageToTempFile(image, quality: 0.8)
        record["imageAsset"] = CKAsset(fileURL: imageURL)

        // Save thumbnail as asset
        let thumbnail = createThumbnail(from: image, maxSize: 200)
        let thumbnailURL = try saveImageToTempFile(thumbnail, quality: 0.6)
        record["thumbnailAsset"] = CKAsset(fileURL: thumbnailURL)

        // Set metadata
        record["latitude"] = location.latitude
        record["longitude"] = location.longitude
        record["timestamp"] = Date()

        // Upload to CloudKit
        let savedRecord = try await database.save(record)

        // Get thumbnail data for local cache
        let thumbnailData = thumbnail.jpegData(compressionQuality: 0.6)

        // Create marker
        let marker = PhotoMarker(
            id: UUID(uuidString: savedRecord.recordID.recordName) ?? UUID(),
            imageRecordID: savedRecord.recordID.recordName,
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: Date(),
            thumbnailData: thumbnailData
        )

        // Update KV store
        await saveMarkerToKVStore(marker)

        // Cleanup temp files
        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: thumbnailURL)

        return marker
    }

    func fetchAllMarkers() async throws -> [PhotoMarker] {
        // First try to get from KV store for quick access
        var cachedMarkers = loadMarkersFromKVStore()

        // Fetch from CloudKit
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let (results, _) = try await database.records(matching: query)

        var markers: [PhotoMarker] = []
        for (_, result) in results {
            switch result {
            case .success(let record):
                // Try to get cached thumbnail
                var thumbnailData: Data? = nil
                if let cachedMarker = cachedMarkers.first(where: { $0.imageRecordID == record.recordID.recordName }) {
                    thumbnailData = cachedMarker.thumbnailData
                } else if let thumbnailAsset = record["thumbnailAsset"] as? CKAsset,
                          let thumbnailURL = thumbnailAsset.fileURL,
                          let data = try? Data(contentsOf: thumbnailURL) {
                    thumbnailData = data
                }

                let marker = PhotoMarker(from: record, thumbnailData: thumbnailData)
                markers.append(marker)
            case .failure(let error):
                print("Error fetching record: \(error)")
            }
        }

        // Update KV store with latest
        await saveAllMarkersToKVStore(markers)

        return markers
    }

    func deleteMarker(_ id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        try await database.deleteRecord(withID: recordID)

        // Remove from KV store
        await removeMarkerFromKVStore(id)
    }

    func downloadFullImage(for marker: PhotoMarker) async throws -> UIImage {
        let recordID = CKRecord.ID(recordName: marker.imageRecordID)
        let record = try await database.record(for: recordID)

        guard let imageAsset = record["imageAsset"] as? CKAsset,
              let imageURL = imageAsset.fileURL,
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            throw CloudKitPhotoError.imageNotFound
        }

        return image
    }

    // MARK: - Private Helpers

    private func saveImageToTempFile(_ image: UIImage, quality: CGFloat) throws -> URL {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw CloudKitPhotoError.imageConversionFailed
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        try data.write(to: tempURL)
        return tempURL
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

    // MARK: - KV Store Helpers

    private func loadMarkersFromKVStore() -> [PhotoMarker] {
        guard let data = kvStore.data(forKey: "photoMarkers"),
              let markers = try? JSONDecoder().decode([PhotoMarker].self, from: data) else {
            return []
        }
        return markers
    }

    private func saveMarkerToKVStore(_ marker: PhotoMarker) async {
        var markers = loadMarkersFromKVStore()
        markers.insert(marker, at: 0)
        saveAllMarkersToKVStore(markers)
    }

    private func saveAllMarkersToKVStore(_ markers: [PhotoMarker]) {
        // Store without thumbnail data to save space
        let markersWithoutThumbnails = markers.map { marker -> PhotoMarker in
            var m = marker
            m.thumbnailData = nil
            return m
        }

        if let data = try? JSONEncoder().encode(markersWithoutThumbnails) {
            kvStore.set(data, forKey: "photoMarkers")
            kvStore.synchronize()
        }
    }

    private func removeMarkerFromKVStore(_ id: UUID) async {
        var markers = loadMarkersFromKVStore()
        markers.removeAll { $0.id == id }
        saveAllMarkersToKVStore(markers)
    }
}

enum CloudKitPhotoError: Error, LocalizedError {
    case imageNotFound
    case imageConversionFailed
    case uploadFailed
    case containerAccessFailed(String)

    var errorDescription: String? {
        switch self {
        case .imageNotFound:
            return "Image not found in CloudKit"
        case .imageConversionFailed:
            return "Failed to convert image"
        case .uploadFailed:
            return "Failed to upload photo"
        case .containerAccessFailed(let details):
            return "Container Access Failed:\n\(details)"
        }
    }
}
