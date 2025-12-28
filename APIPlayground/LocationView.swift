import SwiftUI
import CoreLocation
import MapKit

// MARK: - LocationView
/// A comprehensive location tracking interface demonstrating CoreLocation and MapKit.
///
/// Features:
/// - Interactive map with user location tracking
/// - Live GPS coordinates with accuracy indicators
/// - Speed and altitude monitoring
/// - Reverse geocoding for address display
/// - Distance traveled tracking
/// - Location history breadcrumb trail
/// - Multiple map styles (standard, satellite, hybrid)
///
/// APIs Demonstrated:
/// - CLLocationManager for GPS updates
/// - MKMapView via MapKit SwiftUI integration
/// - CLGeocoder for reverse geocoding
/// - MKPolyline for path visualization
struct LocationView: View {
    @StateObject private var locationManager = LocationTracker()
    @State private var mapStyle: MapStyle = .standard
    @State private var showingStylePicker = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        ZStack {
            // Map view
            Map(position: $cameraPosition, interactionModes: .all) {
                // User location
                UserAnnotation()

                // Location history trail
                if locationManager.locationHistory.count > 1 {
                    MapPolyline(coordinates: locationManager.locationHistory.map { $0.coordinate })
                        .stroke(.blue, lineWidth: 3)
                }

                // Start point marker
                if let start = locationManager.locationHistory.first {
                    Annotation("Start", coordinate: start.coordinate) {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(.green)
                            .padding(6)
                            .background(.white, in: Circle())
                            .shadow(radius: 2)
                    }
                }
            }
            .mapStyle(mapStyle)
            .ignoresSafeArea(edges: .top)

            // Overlay controls
            VStack {
                Spacer()

                // Info panel
                LocationInfoPanel(manager: locationManager)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                // Bottom controls
                HStack(spacing: 16) {
                    // Map style button
                    Button(action: { showingStylePicker = true }) {
                        Image(systemName: "map")
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(.ultraThickMaterial, in: Circle())
                    }

                    // Center on user button
                    Button(action: {
                        withAnimation {
                            cameraPosition = .userLocation(fallback: .automatic)
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(.ultraThickMaterial, in: Circle())
                    }

                    Spacer()

                    // Tracking toggle
                    Button(action: { locationManager.toggleTracking() }) {
                        HStack {
                            Image(systemName: locationManager.isTracking ? "pause.fill" : "play.fill")
                            Text(locationManager.isTracking ? "Pause" : "Track")
                        }
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(locationManager.isTracking ? Color.orange : Color.blue, in: Capsule())
                        .foregroundStyle(.white)
                    }

                    // Reset button
                    Button(action: { locationManager.reset() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(.ultraThickMaterial, in: Circle())
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Map Style", isPresented: $showingStylePicker) {
            Button("Standard") { mapStyle = .standard }
            Button("Satellite") { mapStyle = .imagery }
            Button("Hybrid") { mapStyle = .hybrid }
        }
        .onAppear { locationManager.requestPermission() }
        .onDisappear { locationManager.stopTracking() }
    }
}

// MARK: - LocationInfoPanel
/// Displays detailed location information in a collapsible panel.
struct LocationInfoPanel: View {
    @ObservedObject var manager: LocationTracker
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with expand/collapse
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                    Text("Location Data")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                VStack(spacing: 12) {
                    // Coordinates
                    if let location = manager.location {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Coordinates")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.6f, %.6f",
                                           location.coordinate.latitude,
                                           location.coordinate.longitude))
                                    .font(.system(.body, design: .monospaced))
                            }
                            Spacer()
                            AccuracyIndicator(accuracy: location.horizontalAccuracy)
                        }

                        // Address
                        if let address = manager.address {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Address")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(address)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                        }

                        // Stats grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            StatBox(
                                icon: "arrow.up",
                                value: String(format: "%.0f m", location.altitude),
                                label: "Altitude"
                            )
                            StatBox(
                                icon: "speedometer",
                                value: formatSpeed(location.speed),
                                label: "Speed"
                            )
                            StatBox(
                                icon: "point.topleft.down.to.point.bottomright.curvepath",
                                value: formatDistance(manager.totalDistance),
                                label: "Distance"
                            )
                        }
                    } else {
                        HStack {
                            ProgressView()
                            Text("Acquiring location...")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }
                .padding()
            }
        }
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    /// Formats speed in appropriate units.
    private func formatSpeed(_ speed: CLLocationSpeed) -> String {
        if speed < 0 { return "—" }
        let kmh = speed * 3.6
        if kmh < 1 { return "0 km/h" }
        return String(format: "%.1f km/h", kmh)
    }

    /// Formats distance in meters or kilometers.
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        }
        return String(format: "%.2f km", meters / 1000)
    }
}

// MARK: - AccuracyIndicator
/// Visual indicator for GPS accuracy quality.
struct AccuracyIndicator: View {
    let accuracy: CLLocationAccuracy

    private var color: Color {
        if accuracy < 10 { return .green }
        if accuracy < 30 { return .yellow }
        if accuracy < 100 { return .orange }
        return .red
    }

    private var label: String {
        if accuracy < 10 { return "Excellent" }
        if accuracy < 30 { return "Good" }
        if accuracy < 100 { return "Fair" }
        return "Poor"
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("±\(Int(accuracy))m")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1), in: Capsule())
    }
}

// MARK: - StatBox
/// Compact statistics display box.
struct StatBox: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - LocationTracker
/// Manages location updates, tracking, and geocoding.
///
/// This class provides:
/// - Continuous location updates with configurable accuracy
/// - Location history for path tracking
/// - Total distance calculation
/// - Reverse geocoding for address lookup
/// - Authorization handling
@MainActor
class LocationTracker: NSObject, ObservableObject {
    // MARK: Published Properties
    @Published var location: CLLocation?
    @Published var address: String?
    @Published var isTracking = false
    @Published var locationHistory: [CLLocation] = []
    @Published var totalDistance: Double = 0
    @Published var error: String?

    // MARK: Private Properties
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastGeocodedLocation: CLLocation?

    // MARK: Initialization
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // Update every 5 meters
        manager.allowsBackgroundLocationUpdates = false
    }

    // MARK: Public Methods

    /// Requests location authorization from the user.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        isTracking = true
    }

    /// Toggles location tracking on/off.
    func toggleTracking() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }

    /// Starts continuous location tracking.
    func startTracking() {
        manager.startUpdatingLocation()
        isTracking = true
    }

    /// Stops location tracking.
    func stopTracking() {
        manager.stopUpdatingLocation()
        isTracking = false
    }

    /// Resets all tracking data.
    func reset() {
        locationHistory.removeAll()
        totalDistance = 0
        address = nil
        lastGeocodedLocation = nil
    }

    // MARK: Private Methods

    /// Performs reverse geocoding to get address from coordinates.
    private func reverseGeocode(_ location: CLLocation) {
        // Only geocode if moved significantly (100m+)
        if let last = lastGeocodedLocation,
           location.distance(from: last) < 100 {
            return
        }

        lastGeocodedLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first else { return }

            Task { @MainActor in
                self?.address = [
                    placemark.name,
                    placemark.locality,
                    placemark.administrativeArea
                ]
                .compactMap { $0 }
                .joined(separator: ", ")
            }
        }
    }

    /// Calculates distance between two locations.
    private func updateDistance(from oldLocation: CLLocation?, to newLocation: CLLocation) {
        guard let old = oldLocation else { return }

        // Only count if accuracy is reasonable
        if newLocation.horizontalAccuracy < 50 && old.horizontalAccuracy < 50 {
            let distance = newLocation.distance(from: old)
            // Filter out GPS jumps
            if distance < 100 {
                totalDistance += distance
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationTracker: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        Task { @MainActor in
            let oldLocation = self.location
            self.location = newLocation
            self.error = nil

            // Update distance
            updateDistance(from: oldLocation, to: newLocation)

            // Add to history if tracking and accurate enough
            if isTracking && newLocation.horizontalAccuracy < 50 {
                // Avoid duplicates
                if let last = locationHistory.last,
                   newLocation.distance(from: last) < 3 {
                    return
                }
                locationHistory.append(newLocation)

                // Keep last 1000 points
                if locationHistory.count > 1000 {
                    locationHistory.removeFirst()
                }
            }

            // Reverse geocode
            reverseGeocode(newLocation)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error.localizedDescription
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
                isTracking = true
            case .denied, .restricted:
                error = "Location access denied. Enable in Settings."
            default:
                break
            }
        }
    }
}

#Preview {
    NavigationStack {
        LocationView()
    }
}
