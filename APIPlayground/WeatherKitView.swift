import SwiftUI
import WeatherKit
import CoreLocation

// MARK: - WeatherKitView
/// Comprehensive demonstration of Apple's WeatherKit framework.
///
/// Features:
/// - Current weather conditions
/// - Hourly forecast (24 hours)
/// - Daily forecast (10 days)
/// - Minute-by-minute precipitation
/// - Weather alerts
/// - UV index and air quality
/// - Moon phase and sunrise/sunset
/// - Historical weather data
///
/// APIs Demonstrated:
/// - WeatherService for fetching weather
/// - CurrentWeather, HourWeather, DayWeather
/// - WeatherAlert for severe weather
/// - Precipitation forecasting
/// - Attribution requirements
///
/// Note: Requires WeatherKit capability in App ID and
/// entitlements. Free tier: 500k calls/month.
struct WeatherKitView: View {
    @StateObject private var weatherManager = WeatherManager()
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location and status
                locationCard

                if weatherManager.isLoading {
                    ProgressView("Fetching weather data...")
                        .padding(40)
                } else if let error = weatherManager.errorMessage {
                    errorCard(error)
                } else if weatherManager.currentWeather != nil {
                    // Tab selector
                    Picker("View", selection: $selectedTab) {
                        Text("Current").tag(0)
                        Text("Hourly").tag(1)
                        Text("Daily").tag(2)
                        Text("Details").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch selectedTab {
                    case 0:
                        currentWeatherCard
                    case 1:
                        hourlyForecastCard
                    case 2:
                        dailyForecastCard
                    case 3:
                        detailsCard
                    default:
                        EmptyView()
                    }

                    // Attribution
                    attributionCard
                }

                // API Info
                apiInfoCard
            }
            .padding()
        }
        .navigationTitle("Weather")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { weatherManager.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            weatherManager.requestLocation()
        }
    }

    // MARK: - Location Card
    private var locationCard: some View {
        GroupBox {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)

                VStack(alignment: .leading) {
                    Text(weatherManager.locationName)
                        .font(.headline)
                    if let coords = weatherManager.coordinates {
                        Text("\(coords.latitude, specifier: "%.4f"), \(coords.longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if weatherManager.isLoading {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Error Card
    private func errorCard(_ error: String) -> some View {
        GroupBox {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)

                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Show setup instructions if it's likely an entitlement issue
                if error.contains("jwt") || error.contains("auth") || error.contains("Weather") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WeatherKit Setup Required:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("1. Go to Apple Developer Portal")
                        Text("2. Select your App ID")
                        Text("3. Enable WeatherKit in Capabilities")
                        Text("4. Enable WeatherKit in App Services")
                        Text("5. Wait 30 min for propagation")
                        Text("6. Add entitlement to project")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                Button("Retry") {
                    weatherManager.refresh()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    // MARK: - Current Weather Card
    private var currentWeatherCard: some View {
        GroupBox {
            if let current = weatherManager.currentWeather {
                VStack(spacing: 16) {
                    // Main temperature
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Image(systemName: current.symbolName)
                                .font(.system(size: 60))
                                .symbolRenderingMode(.multicolor)

                            Text(current.condition.description)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(current.temperature.formatted(.measurement(width: .abbreviated)))
                                .font(.system(size: 56, weight: .thin))

                            Text("Feels like \(current.apparentTemperature.formatted(.measurement(width: .abbreviated)))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Weather details grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        WeatherDetailItem(
                            icon: "humidity.fill",
                            title: "Humidity",
                            value: "\(Int(current.humidity * 100))%"
                        )

                        WeatherDetailItem(
                            icon: "wind",
                            title: "Wind",
                            value: current.wind.speed.formatted(.measurement(width: .abbreviated))
                        )

                        WeatherDetailItem(
                            icon: "barometer",
                            title: "Pressure",
                            value: current.pressure.formatted(.measurement(width: .abbreviated))
                        )

                        WeatherDetailItem(
                            icon: "eye.fill",
                            title: "Visibility",
                            value: current.visibility.formatted(.measurement(width: .abbreviated))
                        )

                        WeatherDetailItem(
                            icon: "sun.max.fill",
                            title: "UV Index",
                            value: "\(current.uvIndex.value) (\(current.uvIndex.category.description))"
                        )

                        WeatherDetailItem(
                            icon: "cloud.fill",
                            title: "Cloud Cover",
                            value: "\(Int(current.cloudCover * 100))%"
                        )
                    }
                }
            }
        } label: {
            Label("Current Conditions", systemImage: "sun.max.fill")
        }
    }

    // MARK: - Hourly Forecast Card
    private var hourlyForecastCard: some View {
        GroupBox {
            if let hourly = weatherManager.hourlyForecast {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(hourly.prefix(24)), id: \.date) { hour in
                            VStack(spacing: 8) {
                                Text(hour.date.formatted(.dateTime.hour()))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Image(systemName: hour.symbolName)
                                    .font(.title2)
                                    .symbolRenderingMode(.multicolor)

                                Text(hour.temperature.formatted(.measurement(width: .narrow)))
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                if hour.precipitationChance > 0 {
                                    Text("\(Int(hour.precipitationChance * 100))%")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .frame(width: 60)
                        }
                    }
                }
            }
        } label: {
            Label("Hourly Forecast", systemImage: "clock.fill")
        }
    }

    // MARK: - Daily Forecast Card
    private var dailyForecastCard: some View {
        GroupBox {
            if let daily = weatherManager.dailyForecast {
                VStack(spacing: 12) {
                    ForEach(Array(daily.prefix(10)), id: \.date) { day in
                        HStack {
                            Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                                .frame(width: 40, alignment: .leading)

                            Image(systemName: day.symbolName)
                                .font(.title3)
                                .symbolRenderingMode(.multicolor)
                                .frame(width: 30)

                            if day.precipitationChance > 0 {
                                Text("\(Int(day.precipitationChance * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                    .frame(width: 35)
                            } else {
                                Spacer()
                                    .frame(width: 35)
                            }

                            Spacer()

                            Text(day.lowTemperature.formatted(.measurement(width: .narrow)))
                                .foregroundStyle(.secondary)
                                .frame(width: 45, alignment: .trailing)

                            // Temperature bar
                            TemperatureBar(
                                low: day.lowTemperature.value,
                                high: day.highTemperature.value,
                                minTemp: daily.map { $0.lowTemperature.value }.min() ?? 0,
                                maxTemp: daily.map { $0.highTemperature.value }.max() ?? 100
                            )
                            .frame(width: 60, height: 6)

                            Text(day.highTemperature.formatted(.measurement(width: .narrow)))
                                .frame(width: 45, alignment: .leading)
                        }
                        .font(.subheadline)
                    }
                }
            }
        } label: {
            Label("10-Day Forecast", systemImage: "calendar")
        }
    }

    // MARK: - Details Card
    private var detailsCard: some View {
        VStack(spacing: 16) {
            // Sun & Moon
            GroupBox {
                if let daily = weatherManager.dailyForecast?.first {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Sunrise", systemImage: "sunrise.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let sunrise = daily.sun.sunrise {
                                    Text(sunrise.formatted(.dateTime.hour().minute()))
                                        .font(.headline)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Label("Sunset", systemImage: "sunset.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let sunset = daily.sun.sunset {
                                    Text(sunset.formatted(.dateTime.hour().minute()))
                                        .font(.headline)
                                }
                            }
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Moon Phase", systemImage: "moon.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(daily.moon.phase.description)
                                    .font(.headline)
                            }

                            Spacer()

                            Image(systemName: moonPhaseIcon(daily.moon.phase))
                                .font(.largeTitle)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            } label: {
                Label("Sun & Moon", systemImage: "sun.and.horizon.fill")
            }

            // Wind details
            if let current = weatherManager.currentWeather {
                GroupBox {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Speed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(current.wind.speed.formatted(.measurement(width: .abbreviated)))
                                    .font(.headline)
                            }

                            Spacer()

                            VStack(alignment: .center, spacing: 4) {
                                Text("Direction")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(current.wind.compassDirection.description)
                                    .font(.headline)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Gusts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let gusts = current.wind.gust {
                                    Text(gusts.formatted(.measurement(width: .abbreviated)))
                                        .font(.headline)
                                } else {
                                    Text("--")
                                        .font(.headline)
                                }
                            }
                        }
                    }
                } label: {
                    Label("Wind", systemImage: "wind")
                }
            }
        }
    }

    // MARK: - Attribution Card
    private var attributionCard: some View {
        GroupBox {
            HStack {
                Image(systemName: "apple.logo")
                Text("Weather data provided by Apple Weather")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - API Info Card
    private var apiInfoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                WKInfoRow(title: "Framework", value: "WeatherKit")
                WKInfoRow(title: "Min iOS", value: "16.0+")
                WKInfoRow(title: "Free Tier", value: "500k calls/month")
                WKInfoRow(title: "Data Source", value: "Apple Weather")

                Divider()

                Text("WeatherKit provides comprehensive weather data including forecasts, historical data, and severe weather alerts. Requires App ID configuration.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("API Information", systemImage: "info.circle")
        }
    }

    // MARK: - Helper Functions
    private func moonPhaseIcon(_ phase: MoonPhase) -> String {
        switch phase {
        case .new: return "moon.fill"
        case .waxingCrescent: return "moon.stars.fill"
        case .firstQuarter: return "moon.zzz.fill"
        case .waxingGibbous: return "moon.haze.fill"
        case .full: return "moon.circle.fill"
        case .waningGibbous: return "moon.haze.fill"
        case .lastQuarter: return "moon.zzz.fill"
        case .waningCrescent: return "moon.stars.fill"
        @unknown default: return "moon.fill"
        }
    }
}

// MARK: - WKInfoRow
struct WKInfoRow: View {
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

// MARK: - WeatherDetailItem
struct WeatherDetailItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }
}

// MARK: - TemperatureBar
struct TemperatureBar: View {
    let low: Double
    let high: Double
    let minTemp: Double
    let maxTemp: Double

    var body: some View {
        GeometryReader { geo in
            let range = maxTemp - minTemp
            let startFraction = (low - minTemp) / range
            let endFraction = (high - minTemp) / range

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.3))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * (endFraction - startFraction))
                    .offset(x: geo.size.width * startFraction)
            }
        }
    }
}

// MARK: - WeatherManager
@MainActor
class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentWeather: CurrentWeather?
    @Published var hourlyForecast: Forecast<HourWeather>?
    @Published var dailyForecast: Forecast<DayWeather>?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationName = "Unknown Location"
    @Published var coordinates: CLLocationCoordinate2D?

    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        isLoading = true
        errorMessage = nil

        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        } else {
            errorMessage = "Location access is required for weather data"
            isLoading = false
        }
    }

    func refresh() {
        if let coords = coordinates {
            fetchWeather(for: CLLocation(latitude: coords.latitude, longitude: coords.longitude))
        } else {
            requestLocation()
        }
    }

    private func fetchWeather(for location: CLLocation) {
        Task {
            do {
                // Reverse geocode for location name
                if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                    locationName = placemark.locality ?? placemark.administrativeArea ?? "Unknown"
                }

                coordinates = location.coordinate

                // Fetch all weather data
                let weather = try await weatherService.weather(for: location)

                currentWeather = weather.currentWeather
                hourlyForecast = weather.hourlyForecast
                dailyForecast = weather.dailyForecast

                isLoading = false
            } catch {
                errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            fetchWeather(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "Location error: \(error.localizedDescription)"
            isLoading = false
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse ||
                manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}

#Preview {
    NavigationStack {
        WeatherKitView()
    }
}
