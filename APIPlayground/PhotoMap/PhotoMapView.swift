import SwiftUI
import MapKit
import ComposableArchitecture

struct PhotoMapView: View {
    @Bindable var store: StoreOf<PhotoMapFeature>

    var body: some View {
        ZStack {
            MapContentView(store: store)

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 12) {
                        // Center on user button
                        Button {
                            store.send(.centerOnUserLocation)
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }

                        // Camera FAB
                        Button {
                            store.send(.cameraButtonTapped)
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 6)
                        }
                        .disabled(store.isSaving)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }

            // Loading overlay
            if store.isLoading || store.isSaving {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text(store.isSaving ? "Saving..." : "Loading...")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.top, 8)
                }
                .frame(width: 120, height: 100)
                .background(.black.opacity(0.7))
                .cornerRadius(12)
            }
        }
        .navigationTitle("Photo Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.send(.loadMarkers)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isLoading)
            }
        }
        .sheet(isPresented: Binding(
            get: { store.isShowingCamera },
            set: { if !$0 { store.send(.dismissCamera) } }
        )) {
            PhotoCaptureView { image in
                store.send(.photoCaptured(image))
            }
        }
        .sheet(isPresented: Binding(
            get: { store.isShowingDetail },
            set: { if !$0 { store.send(.dismissDetail) } }
        )) {
            if let marker = store.selectedMarker {
                PhotoDetailView(
                    marker: marker,
                    image: store.selectedImage,
                    onDelete: { store.send(.deleteMarkerTapped) },
                    onDismiss: { store.send(.dismissDetail) }
                )
            }
        }
        .alert("Error", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.send(.dismissError) } }
        )) {
            Button("OK") {
                store.send(.dismissError)
            }
        } message: {
            Text(store.errorMessage ?? "Unknown error")
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

struct MapContentView: View {
    @Bindable var store: StoreOf<PhotoMapFeature>
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            // User location
            UserAnnotation()

            // Photo markers
            ForEach(store.markers) { marker in
                Annotation(
                    "",
                    coordinate: marker.coordinate,
                    anchor: .bottom
                ) {
                    PhotoMarkerAnnotationView(marker: marker) {
                        store.send(.markerTapped(marker))
                    }
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onChange(of: store.mapRegion) { _, newRegion in
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: newRegion.center,
                    span: MKCoordinateSpan(
                        latitudeDelta: newRegion.latDelta,
                        longitudeDelta: newRegion.lonDelta
                    )
                ))
            }
        }
    }
}

struct PhotoMarkerAnnotationView: View {
    let marker: PhotoMarker
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 50, height: 50)
                        .shadow(radius: 3)

                    if let thumbnailData = marker.thumbnailData,
                       let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }

                // Pin point
                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(180))
                    .offset(y: -3)
                    .shadow(radius: 2)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhotoMapView(
            store: Store(initialState: PhotoMapFeature.State()) {
                PhotoMapFeature()
            }
        )
    }
}
