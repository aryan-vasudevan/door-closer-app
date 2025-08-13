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
    
    @State private var showingSettings = false
    @State private var hasCameraPermission = false
    @State private var maxImages = 50
    @State private var shouldStopAfterMax = false
    
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
                    Button("Settings") {
                        showingSettings = true
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    
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
                            Text("Capturing: \(timerManager.photosTaken)/\(maxImages)")
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
                    if !timerManager.isRunning && imageSaver.imagesSaved < maxImages {
                        Button("Start Collection") {
                            startDataCollection()
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                    } else if imageSaver.imagesSaved >= maxImages {
                        Text("Collection Complete!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(15)
                    } else if timerManager.isRunning {
                        if timerManager.isCountdownPhase {
                            Text("Position camera and hold steady")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                        } else {
                            Text("Taking photos...")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                        }
                    }
                    
                    Text("Images saved: \(imageSaver.imagesSaved)/\(maxImages)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                    
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
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            requestCameraPermission()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(maxImages: $maxImages, imageSaver: imageSaver)
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
    
    private func startDataCollection() {
        if imageSaver.imagesSaved >= maxImages {
            return
        }
        
        timerManager.startTimer(
            onCountdownComplete: {
                // Countdown finished, start taking photos
                print("Countdown finished, starting photo capture")
            },
            onPhotoCapture: {
                // Take a photo
                if imageSaver.imagesSaved < maxImages {
                    cameraManager.capturePhoto()
                } else {
                    timerManager.stopTimer()
                }
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
        
        imageSaver.saveImage(processedImage)
    }
}

struct SettingsView: View {
    @Binding var maxImages: Int
    @ObservedObject var imageSaver: ImageSaver
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Collection Settings")) {
                    Stepper("Max Images: \(maxImages)", value: $maxImages, in: 10...100, step: 10)
                }
                
                Section(header: Text("Save Status")) {
                    Text("Images saved: \(imageSaver.imagesSaved)")
                    Text(imageSaver.saveStatus)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Reset Counter") {
                        imageSaver.resetCounter()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}
