import SwiftUI
import UIKit

struct PhotoCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.cameraDevice = .rear
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                // Fix orientation
                let fixedImage = fixImageOrientation(image)
                onCapture(fixedImage)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }

        private func fixImageOrientation(_ image: UIImage) -> UIImage {
            if image.imageOrientation == .up {
                return image
            }

            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return normalizedImage ?? image
        }
    }
}

// Fallback view for simulator
struct PhotoCaptureSimulatorView: View {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                Text("Camera not available")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("Running in Simulator")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Use Sample Photo") {
                    // Create a sample colored image
                    let size = CGSize(width: 400, height: 400)
                    let renderer = UIGraphicsImageRenderer(size: size)
                    let sampleImage = renderer.image { ctx in
                        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple]
                        let color = colors.randomElement() ?? .systemBlue
                        color.setFill()
                        ctx.fill(CGRect(origin: .zero, size: size))

                        // Add text
                        let attrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.boldSystemFont(ofSize: 40),
                            .foregroundColor: UIColor.white
                        ]
                        let text = "Sample Photo"
                        let textSize = text.size(withAttributes: attrs)
                        let textRect = CGRect(
                            x: (size.width - textSize.width) / 2,
                            y: (size.height - textSize.height) / 2,
                            width: textSize.width,
                            height: textSize.height
                        )
                        text.draw(in: textRect, withAttributes: attrs)
                    }
                    onCapture(sampleImage)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
