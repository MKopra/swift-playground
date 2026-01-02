import Foundation
import CoreLocation
import ComposableArchitecture

@DependencyClient
struct LocationManagerClient {
    var requestWhenInUseAuthorization: @Sendable () async -> Void = {}
    var startUpdatingLocation: @Sendable () async -> AsyncStream<CLLocationCoordinate2D> = { AsyncStream { $0.finish() } }
    var stopUpdatingLocation: @Sendable () async -> Void = {}
    var currentLocation: @Sendable () async -> CLLocationCoordinate2D? = { nil }
    var authorizationStatus: @Sendable () -> CLAuthorizationStatus = { .notDetermined }
}

extension LocationManagerClient: DependencyKey {
    static let liveValue: LocationManagerClient = {
        let manager = LocationManagerActor()
        return LocationManagerClient(
            requestWhenInUseAuthorization: {
                await manager.requestWhenInUseAuthorization()
            },
            startUpdatingLocation: {
                await manager.startUpdatingLocation()
            },
            stopUpdatingLocation: {
                await manager.stopUpdatingLocation()
            },
            currentLocation: {
                await manager.currentLocation()
            },
            authorizationStatus: {
                CLLocationManager().authorizationStatus
            }
        )
    }()
}

extension DependencyValues {
    var locationManager: LocationManagerClient {
        get { self[LocationManagerClient.self] }
        set { self[LocationManagerClient.self] = newValue }
    }
}

private actor LocationManagerActor: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var continuation: AsyncStream<CLLocationCoordinate2D>.Continuation?
    private var lastLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
    }

    func requestWhenInUseAuthorization() {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        locationManager = manager
    }

    func startUpdatingLocation() -> AsyncStream<CLLocationCoordinate2D> {
        AsyncStream { continuation in
            self.continuation = continuation
            Task { @MainActor in
                let manager = CLLocationManager()
                manager.delegate = self
                manager.desiredAccuracy = kCLLocationAccuracyBest
                manager.startUpdatingLocation()
                await MainActor.run {
                    Task {
                        await self.setLocationManager(manager)
                    }
                }
            }
        }
    }

    private func setLocationManager(_ manager: CLLocationManager) {
        locationManager = manager
    }

    func stopUpdatingLocation() {
        locationManager?.stopUpdatingLocation()
        continuation?.finish()
        continuation = nil
    }

    func currentLocation() -> CLLocationCoordinate2D? {
        lastLocation
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task {
            await handleLocationUpdate(location.coordinate)
        }
    }

    private func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
        lastLocation = coordinate
        continuation?.yield(coordinate)
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
