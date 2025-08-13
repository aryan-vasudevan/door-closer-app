import AVFoundation
import UIKit
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var capturedImage: UIImage?
    @Published var error: String?
    
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Use front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            DispatchQueue.main.async {
                self.error = "Front camera not available"
            }
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                DispatchQueue.main.async {
                    self.error = "Could not add video device input"
                }
                return
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Could not create video device input: \(error.localizedDescription)"
            }
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        } else {
            DispatchQueue.main.async {
                self.error = "Could not add photo output"
            }
            return
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = self?.session.isRunning ?? false
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = self?.session.isRunning ?? false
            }
        }
    }
    
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            let photoSettings = AVCapturePhotoSettings()
            self?.photoOutput.capturePhoto(with: photoSettings, delegate: self!)
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = "Error capturing photo: \(error.localizedDescription)"
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.error = "Could not create image from photo data"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}
