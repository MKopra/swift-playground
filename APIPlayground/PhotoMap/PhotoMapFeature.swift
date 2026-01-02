import Foundation
import CoreLocation
import UIKit
import ComposableArchitecture

@Reducer
struct PhotoMapFeature {
    @ObservableState
    struct State: Equatable {
        var markers: [PhotoMarker] = []
        var selectedMarker: PhotoMarker?
        var selectedImage: UIImage?
        var currentLocation: CLLocationCoordinate2D?
        var isShowingCamera: Bool = false
        var isShowingDetail: Bool = false
        var isLoading: Bool = false
        var isSaving: Bool = false
        var errorMessage: String?
        var mapRegion: MapRegion = .default

        struct MapRegion: Equatable {
            var center: CLLocationCoordinate2D
            var latDelta: Double
            var lonDelta: Double

            static let `default` = MapRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                latDelta: 0.05,
                lonDelta: 0.05
            )
        }
    }

    enum Action: Equatable {
        // UI
        case onAppear
        case cameraButtonTapped
        case markerTapped(PhotoMarker)
        case dismissCamera
        case dismissDetail
        case deleteMarkerTapped
        case centerOnUserLocation
        case dismissError

        // Camera
        case photoCaptured(UIImage)

        // Location
        case locationUpdated(CLLocationCoordinate2D)
        case locationStreamStarted

        // Storage
        case loadMarkers
        case markersLoaded([PhotoMarker])
        case photoSaved(PhotoMarker)
        case photoSaveFailed(String)
        case photoDeleted(UUID)
        case photoDeleteFailed(String)
        case fullImageLoaded(UIImage)
        case fullImageFailed(String)
    }

    @Dependency(\.locationManager) var locationManager
    @Dependency(\.photoStorage) var photoStorage

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .merge(
                    .run { send in
                        await locationManager.requestWhenInUseAuthorization()
                        await send(.locationStreamStarted)
                    },
                    .run { send in
                        await send(.loadMarkers)
                    }
                )

            case .locationStreamStarted:
                return .run { send in
                    let stream = await locationManager.startUpdatingLocation()
                    for await location in stream {
                        await send(.locationUpdated(location))
                    }
                }

            case .locationUpdated(let location):
                let isFirstLocation = state.currentLocation == nil
                state.currentLocation = location
                if isFirstLocation {
                    state.mapRegion = State.MapRegion(
                        center: location,
                        latDelta: 0.01,
                        lonDelta: 0.01
                    )
                }
                return .none

            case .cameraButtonTapped:
                state.isShowingCamera = true
                return .none

            case .dismissCamera:
                state.isShowingCamera = false
                return .none

            case .photoCaptured(let image):
                state.isShowingCamera = false
                state.isSaving = true

                guard let location = state.currentLocation else {
                    state.errorMessage = "Location not available. Please enable location services."
                    state.isSaving = false
                    return .none
                }

                return .run { send in
                    do {
                        let marker = try await photoStorage.savePhoto(image, location)
                        await send(.photoSaved(marker))
                    } catch {
                        await send(.photoSaveFailed(error.localizedDescription))
                    }
                }

            case .photoSaved(let marker):
                state.isSaving = false
                state.markers.insert(marker, at: 0)
                return .none

            case .photoSaveFailed(let error):
                state.isSaving = false
                state.errorMessage = error
                return .none

            case .markerTapped(let marker):
                state.selectedMarker = marker
                state.selectedImage = nil
                state.isShowingDetail = true

                return .run { send in
                    do {
                        let image = try await photoStorage.loadImage(marker)
                        await send(.fullImageLoaded(image))
                    } catch {
                        await send(.fullImageFailed(error.localizedDescription))
                    }
                }

            case .fullImageLoaded(let image):
                state.selectedImage = image
                return .none

            case .fullImageFailed(let error):
                state.errorMessage = error
                return .none

            case .dismissDetail:
                state.isShowingDetail = false
                state.selectedMarker = nil
                state.selectedImage = nil
                return .none

            case .deleteMarkerTapped:
                guard let marker = state.selectedMarker else { return .none }
                state.isShowingDetail = false

                return .run { send in
                    do {
                        try await photoStorage.deleteMarker(marker.id)
                        await send(.photoDeleted(marker.id))
                    } catch {
                        await send(.photoDeleteFailed(error.localizedDescription))
                    }
                }

            case .photoDeleted(let id):
                state.markers.removeAll { $0.id == id }
                state.selectedMarker = nil
                return .none

            case .photoDeleteFailed(let error):
                state.errorMessage = error
                return .none

            case .centerOnUserLocation:
                if let location = state.currentLocation {
                    state.mapRegion = State.MapRegion(
                        center: location,
                        latDelta: 0.01,
                        lonDelta: 0.01
                    )
                }
                return .none

            case .loadMarkers:
                state.isLoading = true
                return .run { send in
                    do {
                        let markers = try await photoStorage.fetchAllMarkers()
                        await send(.markersLoaded(markers))
                    } catch {
                        await send(.markersLoaded([]))
                    }
                }

            case .markersLoaded(let markers):
                state.isLoading = false
                state.markers = markers
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}

// Make CLLocationCoordinate2D Equatable for TCA
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// Make UIImage Equatable by reference for TCA
extension UIImage: @retroactive Equatable {
    public static func == (lhs: UIImage, rhs: UIImage) -> Bool {
        lhs === rhs
    }
}
