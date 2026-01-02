import SwiftUI
import CoreLocation
import MapKit
import UniformTypeIdentifiers

struct PhotoDetailView: View {
    let marker: PhotoMarker
    let image: UIImage?
    let onDelete: () -> Void
    let onDismiss: () -> Void

    @State private var address: String = "Loading address..."
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Photo
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                    } else if let thumbnailData = marker.thumbnailData,
                              let thumbnail = UIImage(data: thumbnailData) {
                        ZStack {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 400)
                                .blur(radius: 3)

                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay {
                                ProgressView()
                            }
                    }

                    // Info section
                    VStack(alignment: .leading, spacing: 16) {
                        // Timestamp
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            Text(marker.timestamp.formatted(date: .long, time: .shortened))
                                .font(.subheadline)
                        }

                        Divider()

                        // Location
                        HStack(alignment: .top) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(address)
                                    .font(.subheadline)
                                Text(String(format: "%.6f, %.6f", marker.latitude, marker.longitude))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        // Mini map
                        Map {
                            Marker("", coordinate: marker.coordinate)
                                .tint(.blue)
                        }
                        .frame(height: 150)
                        .cornerRadius(12)
                        .disabled(true)

                        Divider()

                        // Actions
                        HStack(spacing: 20) {
                            if let image = image,
                               let imageData = image.jpegData(compressionQuality: 0.8) {
                                ShareLink(
                                    item: ImageDataTransferable(data: imageData),
                                    preview: SharePreview("Photo", image: Image(uiImage: image))
                                ) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Button {
                                    // Disabled state
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                                .disabled(true)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete Photo",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete the photo from all your devices.")
            }
            .task {
                await reverseGeocode()
            }
        }
    }

    private func reverseGeocode() async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: marker.latitude, longitude: marker.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                var components: [String] = []

                if let name = placemark.name {
                    components.append(name)
                }
                if let locality = placemark.locality {
                    if !components.contains(locality) {
                        components.append(locality)
                    }
                }
                if let administrativeArea = placemark.administrativeArea {
                    components.append(administrativeArea)
                }
                if let country = placemark.country {
                    components.append(country)
                }

                address = components.joined(separator: ", ")
            } else {
                address = "Unknown location"
            }
        } catch {
            address = "Unable to determine address"
        }
    }
}

#Preview {
    PhotoDetailView(
        marker: .preview,
        image: nil,
        onDelete: {},
        onDismiss: {}
    )
}

struct ImageDataTransferable: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { item in
            item.data
        }
    }
}
