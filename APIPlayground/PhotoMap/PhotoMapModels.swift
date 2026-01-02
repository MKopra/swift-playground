import Foundation
import CoreLocation
import CloudKit

struct PhotoMarker: Identifiable, Codable, Equatable {
    let id: UUID
    let imageRecordID: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    var thumbnailData: Data?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        imageRecordID: String,
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.imageRecordID = imageRecordID
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.thumbnailData = thumbnailData
    }

    init(from record: CKRecord, thumbnailData: Data?) {
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.imageRecordID = record.recordID.recordName
        self.latitude = record["latitude"] as? Double ?? 0
        self.longitude = record["longitude"] as? Double ?? 0
        self.timestamp = record["timestamp"] as? Date ?? Date()
        self.thumbnailData = thumbnailData
    }
}

extension PhotoMarker {
    static let preview = PhotoMarker(
        id: UUID(),
        imageRecordID: "preview-record",
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: Date(),
        thumbnailData: nil
    )
}
