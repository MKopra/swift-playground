import SwiftUI
import CoreLocation

// MARK: - CompassView
/// A comprehensive compass and navigation interface with waypoint support.
///
/// Features:
/// - High-precision compass with animated needle
/// - Waypoint system with distance and bearing
/// - Current location display with coordinates
/// - Level bubble for device orientation
/// - Cardinal direction highlighting
/// - Magnetic declination display
/// - Target lock mode for navigation
///
/// APIs Demonstrated:
/// - CLLocationManager for heading and location updates
/// - CLLocation for distance calculations
/// - Coordinate formatting and geodesy
/// - UserDefaults for waypoint persistence
struct CompassView: View {
    @StateObject private var compass = CompassManager()
    @State private var showingWaypoints = false
    @State private var showingAddWaypoint = false
    @State private var selectedWaypoint: Waypoint?
    @State private var isTargetLocked = false

    var body: some View {
        ZStack {
            // Dynamic gradient background based on cardinal direction
            LinearGradient(
                colors: backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Top info bar
                HStack {
                    // Coordinates display
                    if let location = compass.currentLocation {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatCoordinate(location.coordinate.latitude, isLatitude: true))
                                .font(.system(.caption, design: .monospaced))
                            Text(formatCoordinate(location.coordinate.longitude, isLatitude: false))
                                .font(.system(.caption, design: .monospaced))
                        }
                        .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    // Waypoints button
                    Button(action: { showingWaypoints = true }) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Main compass with waypoint indicator
                ZStack {
                    // Waypoint direction indicator (outer ring)
                    if let waypoint = selectedWaypoint, let location = compass.currentLocation {
                        WaypointDirectionRing(
                            bearing: compass.bearingTo(waypoint.coordinate),
                            heading: compass.heading,
                            distance: location.distance(from: CLLocation(
                                latitude: waypoint.coordinate.latitude,
                                longitude: waypoint.coordinate.longitude
                            ))
                        )
                    }

                    // Outer decorative ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1), .white.opacity(0.3)],
                                center: .center
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 280, height: 280)

                    // Compass face
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(white: 0.15), Color(white: 0.05)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .frame(width: 260, height: 260)
                        .shadow(color: .black.opacity(0.5), radius: 20)

                    // Rotating compass elements
                    Group {
                        // Degree markings
                        ForEach(0..<72, id: \.self) { i in
                            let isMajor = i % 6 == 0
                            Rectangle()
                                .fill(isMajor ? Color.white : Color.white.opacity(0.3))
                                .frame(width: isMajor ? 2 : 1, height: isMajor ? 15 : 8)
                                .offset(y: -115)
                                .rotationEffect(.degrees(Double(i) * 5))
                        }

                        // Cardinal direction labels
                        ForEach(cardinalDirections, id: \.label) { direction in
                            Text(direction.label)
                                .font(.system(size: direction.isMain ? 22 : 14, weight: .bold))
                                .foregroundStyle(direction.isMain ? direction.color : .white.opacity(0.7))
                                .offset(y: -88)
                                .rotationEffect(.degrees(-direction.degrees))
                                .rotationEffect(.degrees(direction.degrees))
                        }

                        // Degree numbers
                        ForEach([0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330], id: \.self) { degree in
                            if degree % 90 != 0 { // Skip cardinal positions
                                Text("\(degree)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .offset(y: -68)
                                    .rotationEffect(.degrees(-Double(degree)))
                                    .rotationEffect(.degrees(Double(degree)))
                            }
                        }
                    }
                    .rotationEffect(.degrees(-compass.heading))

                    // Level bubble
                    LevelBubble(pitch: compass.pitch, roll: compass.roll)
                        .frame(width: 60, height: 60)

                    // Compass needle (fixed, always points up)
                    CompassNeedle()
                        .frame(width: 140, height: 140)

                    // Center cap
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(white: 0.4), Color(white: 0.2)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)

                    // North indicator at top
                    VStack {
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .shadow(color: .red.opacity(0.5), radius: 5)
                        Spacer()
                    }
                    .frame(height: 300)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: compass.heading)

                // Heading display
                VStack(spacing: 8) {
                    Text(String(format: "%.0f°", compass.heading))
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    Text(compass.cardinalDirection)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Selected waypoint info
                if let waypoint = selectedWaypoint, let location = compass.currentLocation {
                    WaypointInfoCard(
                        waypoint: waypoint,
                        distance: location.distance(from: CLLocation(
                            latitude: waypoint.coordinate.latitude,
                            longitude: waypoint.coordinate.longitude
                        )),
                        bearing: compass.bearingTo(waypoint.coordinate),
                        isLocked: isTargetLocked,
                        onLockToggle: { isTargetLocked.toggle() },
                        onClear: { selectedWaypoint = nil }
                    )
                    .padding(.horizontal)
                }

                Spacer()

                // Bottom info bar
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Image(systemName: accuracyIcon)
                            .font(.title2)
                            .foregroundStyle(accuracyColor)
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    VStack(spacing: 4) {
                        Image(systemName: "location.north.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(compass.heading))
                        Text("True North")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    VStack(spacing: 4) {
                        Text(String(format: "%.1f°", compass.magneticDeclination))
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                        Text("Declination")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    if let altitude = compass.currentLocation?.altitude {
                        VStack(spacing: 4) {
                            Text(String(format: "%.0fm", altitude))
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.cyan)
                            Text("Altitude")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.bottom, 16)

                if let error = compass.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.bottom)
                }
            }
        }
        .navigationTitle("Compass")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { compass.start() }
        .onDisappear { compass.stop() }
        .sheet(isPresented: $showingWaypoints) {
            WaypointsListView(
                waypoints: $compass.waypoints,
                selectedWaypoint: $selectedWaypoint,
                currentLocation: compass.currentLocation,
                onAddWaypoint: { showingAddWaypoint = true }
            )
        }
        .sheet(isPresented: $showingAddWaypoint) {
            AddWaypointView(
                currentLocation: compass.currentLocation,
                onSave: { waypoint in
                    compass.addWaypoint(waypoint)
                }
            )
        }
    }

    // MARK: - Helper Properties

    private var cardinalDirections: [(label: String, degrees: Double, isMain: Bool, color: Color)] {
        [
            ("N", 0, true, .red),
            ("NE", 45, false, .white),
            ("E", 90, true, .white),
            ("SE", 135, false, .white),
            ("S", 180, true, .white),
            ("SW", 225, false, .white),
            ("W", 270, true, .white),
            ("NW", 315, false, .white)
        ]
    }

    private var backgroundColors: [Color] {
        let heading = compass.heading
        if heading < 45 || heading >= 315 { // North
            return [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.05, green: 0.1, blue: 0.2)]
        } else if heading < 135 { // East
            return [Color(red: 0.4, green: 0.3, blue: 0.1), Color(red: 0.2, green: 0.15, blue: 0.05)]
        } else if heading < 225 { // South
            return [Color(red: 0.3, green: 0.1, blue: 0.1), Color(red: 0.15, green: 0.05, blue: 0.05)]
        } else { // West
            return [Color(red: 0.2, green: 0.1, blue: 0.3), Color(red: 0.1, green: 0.05, blue: 0.15)]
        }
    }

    private var accuracyIcon: String {
        switch compass.accuracy {
        case .high: return "checkmark.circle.fill"
        case .medium: return "checkmark.circle"
        case .low: return "exclamationmark.circle"
        case .unreliable: return "xmark.circle"
        }
    }

    private var accuracyColor: Color {
        switch compass.accuracy {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .orange
        case .unreliable: return .red
        }
    }

    /// Formats a coordinate value for display.
    private func formatCoordinate(_ value: Double, isLatitude: Bool) -> String {
        let direction = isLatitude ? (value >= 0 ? "N" : "S") : (value >= 0 ? "E" : "W")
        let absValue = abs(value)
        let degrees = Int(absValue)
        let minutes = Int((absValue - Double(degrees)) * 60)
        let seconds = ((absValue - Double(degrees)) * 60 - Double(minutes)) * 60
        return String(format: "%d° %d' %.1f\" %@", degrees, minutes, seconds, direction)
    }
}

// MARK: - WaypointDirectionRing
/// Visual indicator showing bearing to selected waypoint.
struct WaypointDirectionRing: View {
    let bearing: Double
    let heading: Double
    let distance: Double

    private var relativeBearing: Double {
        var diff = bearing - heading
        if diff < 0 { diff += 360 }
        return diff
    }

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.orange.opacity(0.3), lineWidth: 8)
                .frame(width: 320, height: 320)

            // Direction indicator
            Circle()
                .fill(Color.orange)
                .frame(width: 16, height: 16)
                .overlay(
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                )
                .shadow(color: .orange.opacity(0.5), radius: 5)
                .offset(y: -160)
                .rotationEffect(.degrees(relativeBearing))
        }
    }
}

// MARK: - LevelBubble
/// Circular level indicator showing device orientation.
struct LevelBubble: View {
    let pitch: Double
    let roll: Double

    private var bubbleOffset: CGSize {
        let maxOffset: CGFloat = 20
        let x = CGFloat(min(max(roll, -45), 45)) / 45 * maxOffset
        let y = CGFloat(min(max(pitch, -45), 45)) / 45 * maxOffset
        return CGSize(width: x, height: y)
    }

    private var isLevel: Bool {
        abs(pitch) < 3 && abs(roll) < 3
    }

    var body: some View {
        ZStack {
            // Target circles
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 50, height: 50)

            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 30, height: 30)

            Circle()
                .stroke(isLevel ? Color.green.opacity(0.5) : Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 10, height: 10)

            // Bubble
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            isLevel ? .green : .yellow,
                            isLevel ? .green.opacity(0.5) : .yellow.opacity(0.5)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 10
                    )
                )
                .frame(width: 12, height: 12)
                .shadow(color: isLevel ? .green.opacity(0.5) : .yellow.opacity(0.5), radius: 3)
                .offset(bubbleOffset)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: bubbleOffset)
        }
    }
}

// MARK: - WaypointInfoCard
/// Displays information about selected waypoint.
struct WaypointInfoCard: View {
    let waypoint: Waypoint
    let distance: Double
    let bearing: Double
    let isLocked: Bool
    let onLockToggle: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Waypoint icon
            Circle()
                .fill(waypoint.color.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: waypoint.icon)
                        .foregroundStyle(.white)
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(waypoint.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Label(formatDistance(distance), systemImage: "arrow.triangle.swap")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(String(format: "%.0f°", bearing), systemImage: "safari")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Lock button
            Button(action: onLockToggle) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .foregroundStyle(isLocked ? .orange : .gray)
            }

            // Clear button
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0fm", meters)
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
}

// MARK: - WaypointsListView
/// List view for managing waypoints.
struct WaypointsListView: View {
    @Binding var waypoints: [Waypoint]
    @Binding var selectedWaypoint: Waypoint?
    let currentLocation: CLLocation?
    let onAddWaypoint: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if waypoints.isEmpty {
                    ContentUnavailableView(
                        "No Waypoints",
                        systemImage: "mappin.slash",
                        description: Text("Add waypoints to navigate to saved locations")
                    )
                } else {
                    ForEach(waypoints) { waypoint in
                        Button(action: {
                            selectedWaypoint = waypoint
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(waypoint.color.gradient)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: waypoint.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(waypoint.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    if let location = currentLocation {
                                        let distance = location.distance(from: CLLocation(
                                            latitude: waypoint.coordinate.latitude,
                                            longitude: waypoint.coordinate.longitude
                                        ))
                                        Text(formatDistance(distance))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if selectedWaypoint?.id == waypoint.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        waypoints.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Waypoints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onAddWaypoint) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m away", meters)
        } else {
            return String(format: "%.1f km away", meters / 1000)
        }
    }
}

// MARK: - AddWaypointView
/// Form for adding a new waypoint.
struct AddWaypointView: View {
    let currentLocation: CLLocation?
    let onSave: (Waypoint) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "mappin"
    @State private var selectedColor = Color.orange
    @State private var useCurrentLocation = true
    @State private var manualLatitude = ""
    @State private var manualLongitude = ""

    private let icons = ["mappin", "house.fill", "building.2.fill", "car.fill", "figure.walk",
                         "leaf.fill", "mountain.2.fill", "water.waves", "flag.fill", "star.fill"]
    private let colors: [Color] = [.orange, .red, .pink, .purple, .blue, .cyan, .green, .yellow]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Waypoint name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        selectedIcon == icon
                                            ? selectedColor.opacity(0.3)
                                            : Color.gray.opacity(0.1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color.gradient)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Location") {
                    Toggle("Use Current Location", isOn: $useCurrentLocation)

                    if useCurrentLocation {
                        if let location = currentLocation {
                            Text(String(format: "%.6f, %.6f",
                                        location.coordinate.latitude,
                                        location.coordinate.longitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Waiting for location...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        TextField("Latitude", text: $manualLatitude)
                            .keyboardType(.decimalPad)
                        TextField("Longitude", text: $manualLongitude)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Add Waypoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveWaypoint()
                    }
                    .disabled(name.isEmpty || (useCurrentLocation && currentLocation == nil))
                }
            }
        }
    }

    private func saveWaypoint() {
        let coordinate: CLLocationCoordinate2D
        if useCurrentLocation, let location = currentLocation {
            coordinate = location.coordinate
        } else {
            guard let lat = Double(manualLatitude),
                  let lon = Double(manualLongitude) else { return }
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }

        let waypoint = Waypoint(
            name: name,
            coordinate: coordinate,
            icon: selectedIcon,
            color: selectedColor
        )
        onSave(waypoint)
        dismiss()
    }
}

// MARK: - CompassNeedle
/// Stylized compass needle with north and south indicators.
struct CompassNeedle: View {
    var body: some View {
        ZStack {
            // North needle (red)
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [.red, Color(red: 0.8, green: 0, blue: 0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 18, height: 60)
                .offset(y: -30)

            // South needle (white)
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(white: 0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 18, height: 60)
                .rotationEffect(.degrees(180))
                .offset(y: 30)
        }
        .shadow(color: .black.opacity(0.3), radius: 5)
    }
}

// MARK: - Triangle
/// Basic triangle shape for compass needle.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - HeadingAccuracy
/// Accuracy levels for compass heading.
enum HeadingAccuracy {
    case high, medium, low, unreliable
}

// MARK: - Waypoint
/// Represents a saved navigation waypoint.
struct Waypoint: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let icon: String
    private let colorComponents: [Double]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var color: Color {
        Color(
            red: colorComponents[0],
            green: colorComponents[1],
            blue: colorComponents[2]
        )
    }

    init(name: String, coordinate: CLLocationCoordinate2D, icon: String, color: Color) {
        self.id = UUID()
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.icon = icon

        // Extract RGB components for Codable support
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        self.colorComponents = [Double(r), Double(g), Double(b)]
    }

    static func == (lhs: Waypoint, rhs: Waypoint) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CompassManager
/// Manages compass heading, location, and waypoint data.
///
/// This class provides:
/// - Real-time heading updates with accuracy tracking
/// - Current location for distance calculations
/// - Device orientation (pitch/roll) for level bubble
/// - Waypoint storage with UserDefaults persistence
/// - Bearing calculation to waypoints
@MainActor
class CompassManager: NSObject, ObservableObject {
    // MARK: Published Properties
    @Published var heading: Double = 0
    @Published var cardinalDirection: String = "N"
    @Published var accuracy: HeadingAccuracy = .unreliable
    @Published var magneticDeclination: Double = 0
    @Published var currentLocation: CLLocation?
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var waypoints: [Waypoint] = [] {
        didSet { saveWaypoints() }
    }
    @Published var error: String?

    // MARK: Private Properties
    private let locationManager = CLLocationManager()
    private let waypointsKey = "compass_waypoints"

    // MARK: Initialization

    override init() {
        super.init()
        locationManager.delegate = self
        loadWaypoints()
    }

    // MARK: Public Methods

    /// Starts compass and location updates.
    func start() {
        guard CLLocationManager.headingAvailable() else {
            error = "Compass not available"
            return
        }

        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
    }

    /// Stops all updates.
    func stop() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
    }

    /// Adds a new waypoint.
    func addWaypoint(_ waypoint: Waypoint) {
        waypoints.append(waypoint)
    }

    /// Calculates bearing from current location to a coordinate.
    func bearingTo(_ coordinate: CLLocationCoordinate2D) -> Double {
        guard let current = currentLocation else { return 0 }

        let lat1 = current.coordinate.latitude * .pi / 180
        let lon1 = current.coordinate.longitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let lon2 = coordinate.longitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        var bearing = atan2(y, x) * 180 / .pi
        if bearing < 0 { bearing += 360 }
        return bearing
    }

    // MARK: Private Methods

    private func loadWaypoints() {
        guard let data = UserDefaults.standard.data(forKey: waypointsKey),
              let decoded = try? JSONDecoder().decode([Waypoint].self, from: data) else { return }
        waypoints = decoded
    }

    private func saveWaypoints() {
        guard let data = try? JSONEncoder().encode(waypoints) else { return }
        UserDefaults.standard.set(data, forKey: waypointsKey)
    }

    private func directionFromHeading(_ heading: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((heading + 11.25) / 22.5) % 16
        return directions[index]
    }
}

// MARK: - CLLocationManagerDelegate
extension CompassManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            self.heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            self.magneticDeclination = newHeading.trueHeading - newHeading.magneticHeading
            self.cardinalDirection = self.directionFromHeading(self.heading)

            switch newHeading.headingAccuracy {
            case ..<0: self.accuracy = .unreliable
            case 0..<10: self.accuracy = .high
            case 10..<25: self.accuracy = .medium
            default: self.accuracy = .low
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CompassView()
    }
}
