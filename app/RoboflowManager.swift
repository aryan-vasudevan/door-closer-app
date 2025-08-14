import Foundation
import UIKit
import Roboflow

class RoboflowManager: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isLoading = false
    @Published var lastInferenceResults: [RFPrediction] = []
    @Published var inferenceStatus = ""
    
    private var rf: RoboflowMobile?
    private var mlModel: RFModel?
    private var onDoorStateDetected: ((String) -> Void)?
    
    // Configuration from RoboflowConfig
    private let apiKey = RoboflowConfig.apiKey
    private let model = RoboflowConfig.modelName
    private let modelVersion = RoboflowConfig.modelVersion
    
    // Detection parameters
    private let threshold: Float = RoboflowConfig.confidenceThreshold
    private let overlap: Float = RoboflowConfig.overlapThreshold
    private let maxObjects: Int = RoboflowConfig.maxObjects
    
    init() {
        setupRoboflow()
    }
    
    private func setupRoboflow() {
        // Validate configuration
        guard apiKey != "YOUR_API_KEY_HERE" else {
            print("⚠️  Please configure your Roboflow API key in RoboflowConfig.swift")
            DispatchQueue.main.async {
                self.inferenceStatus = "Please configure API key"
            }
            return
        }
        
        guard model != "YOUR_MODEL_NAME" else {
            print("⚠️  Please configure your model name in RoboflowConfig.swift")
            DispatchQueue.main.async {
                self.inferenceStatus = "Please configure model name"
            }
            return
        }
        
        rf = RoboflowMobile(apiKey: apiKey)
        loadModel()
    }
    
    private func loadModel() {
        guard let rf = rf else {
            print("Roboflow not initialized")
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.inferenceStatus = "Loading model..."
        }
        
        rf.load(model: model, modelVersion: modelVersion) { [weak self] model, error, modelName, modelType in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.inferenceStatus = "Model loading failed: \(error.localizedDescription)"
                    print("Model loading error: \(error.localizedDescription)")
                } else if let model = model {
                    self?.mlModel = model
                    self?.isModelLoaded = true
                    self?.inferenceStatus = "Model loaded successfully"
                    
                    // Configure the model based on its type
                    if let objectDetectionModel = model as? RFObjectDetectionModel {
                        objectDetectionModel.configure(threshold: Double(self?.threshold ?? 0.5), 
                                                     overlap: Double(self?.overlap ?? 0.5), 
                                                     maxObjects: Float(self?.maxObjects ?? 10))
                    } else if let segmentationModel = model as? RFInstanceSegmentationModel {
                        segmentationModel.configure(threshold: Double(self?.threshold ?? 0.5), 
                                                  overlap: Double(self?.overlap ?? 0.5), 
                                                  maxObjects: Float(self?.maxObjects ?? 10),
                                                  processingMode: .balanced,
                                                  maxNumberPoints: 1000)
                    }
                    
                    print("Roboflow model loaded successfully: \(modelName ?? "Unknown") - Type: \(modelType ?? "Unknown")")
                }
            }
        }
    }
    
    func runInference(on image: UIImage) {
        guard let mlModel = mlModel, isModelLoaded else {
            print("❌ Model not loaded yet")
            inferenceStatus = "Model not loaded"
            return
        }
        
        print("🔍 Starting inference on captured image...")
        DispatchQueue.main.async {
            self.inferenceStatus = "Running inference..."
        }
        
        mlModel.detect(image: image) { [weak self] detections, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.inferenceStatus = "Inference failed: \(error.localizedDescription)"
                    print("Inference error: \(error.localizedDescription)")
                } else if let detections = detections {
                    self?.lastInferenceResults = detections
                    self?.inferenceStatus = "Found \(detections.count) objects"
                    
                    // Print detailed results
                    print("🎯 === INFERENCE RESULTS ===")
                    print("📊 Total detections: \(detections.count)")
                    print("⏰ Timestamp: \(Date())")
                    
                    for (index, detection) in detections.enumerated() {
                        let values = detection.getValues()
                        print("🔍 Detection \(index + 1):")
                        
                        // Get class name using the correct key "class"
                        if let className = values["class"] as? String {
                            print("  🏷️  Class: \(className)")
                        } else {
                            print("  ❌ Class name not found in detection values")
                        }
                        
                        if let confidence = values["confidence"] as? Double {
                            print("  📈 Confidence: \(String(format: "%.2f", confidence))")
                        }
                        
                        if let color = values["color"] as? UIColor {
                            print("  🎨 Color: \(color)")
                        }
                        
                        // If it's a segmentation model, also print polygon points
                        if let segmentationDetection = detection as? RFInstanceSegmentationPrediction {
                            let segmentationValues = segmentationDetection.getValues()
                            if let points = segmentationValues["points"] as? [CGPoint] {
                                print("  🔷 Polygon points: \(points.count) points")
                            }
                        }
                    }
                    print("🎯 ========================")
                } else {
                    self?.inferenceStatus = "No detections found"
                    print("❌ No objects detected in this image")
                }
            }
        }
    }
    
    func reloadModel() {
        isModelLoaded = false
        mlModel = nil
        loadModel()
    }
    
    func setDoorStateCallback(_ callback: @escaping (String) -> Void) {
        onDoorStateDetected = callback
    }
}
