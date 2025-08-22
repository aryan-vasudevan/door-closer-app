//
//  ContentView.swift
//  app
//
//  Created by Aryan Vasudevan on 2025-08-13.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var timerManager = TimerManager()
    @StateObject private var imageSaver = ImageSaver()
    @StateObject private var roboflowManager = RoboflowManager()
    
    @State private var hasCameraPermission = false
    @State private var isContinuousCapture = false

    
    var body: some View {
        ZStack {
            // Camera preview
            if hasCameraPermission && cameraManager.isSessionRunning {
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            

            
            VStack {
                // Top controls
                HStack {
                    Spacer()
                    
                    if timerManager.isRunning {
                        if timerManager.isCountdownPhase {
                            Text("Get Ready: \(timerManager.timeRemaining)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.orange.opacity(0.8))
                                .cornerRadius(10)
                        } else {
                            Text("Capturing: \(timerManager.photosTaken) photos")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    if timerManager.isRunning {
                        if timerManager.isCountdownPhase {
                            Text("Position camera and hold steady")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                        } else {
                            Text("Taking photos every 50 seconds...")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                        }
                    }
                    

                    
                    if imageSaver.isSaving {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text(imageSaver.saveStatus)
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                    }
                    
                    // Network status
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(roboflowManager.getNetworkManager().isConnected ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text(roboflowManager.getNetworkManager().connectionStatus)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        if !roboflowManager.getNetworkManager().lastSentState.isEmpty {
                            Text("Last sent: \(roboflowManager.getNetworkManager().lastSentState)")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    
                    // Roboflow status
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(roboflowManager.isModelLoaded ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text(roboflowManager.isModelLoaded ? "Model Ready" : "Model Loading...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        if !roboflowManager.inferenceStatus.isEmpty {
                            Text(roboflowManager.inferenceStatus)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        if roboflowManager.lastInferenceResults.count > 0 {
                            Text("Last detection: \(roboflowManager.lastInferenceResults.count) objects")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        
                        if !roboflowManager.lastDetectedDoorState.isEmpty {
                            Text("Door state: \(roboflowManager.lastDetectedDoorState)")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            requestCameraPermission()
            // Automatically start continuous capture when app opens
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startContinuousCapture()
            }
        }

        .onReceive(cameraManager.$capturedImage) { image in
            if let image = image {
                processAndSaveImage(image)
            }
        }
        .onReceive(cameraManager.$error) { error in
            if let error = error {
                print("Camera error: \(error)")
            }
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                hasCameraPermission = granted
                if granted {
                    cameraManager.startSession()
                }
            }
        }
    }
    
    private func startContinuousCapture() {
        isContinuousCapture = true
        
        timerManager.startTimer(
            onCountdownComplete: {
                // Countdown finished, start taking photos
                print("Countdown finished, starting continuous photo capture")
            },
            onPhotoCapture: {
                // Take a photo every 5 seconds
                cameraManager.capturePhoto()
            }
        )
    }
    

    
    private func processAndSaveImage(_ image: UIImage) {
        guard let processedImage = ImageProcessor.processImage(image) else {
            print("Failed to process image")
            return
        }
        
        let sizeKB = ImageProcessor.getImageSizeKB(processedImage)
        print("Processed image size: \(sizeKB)KB")
        
        // Save the image
        imageSaver.saveImage(processedImage)
        
        // Run inference on the processed image
        roboflowManager.runInference(on: processedImage)
    }
}



#Preview {
    ContentView()
}
