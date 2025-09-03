# Door Closer App

An iOS application that automatically detects door states using computer vision and controls an ESP32-based door closer system. The app continuously captures images, analyzes them using Roboflow's machine learning models, and sends door state commands to an ESP32 microcontroller.

## 🚪 Features

- **Continuous Camera Monitoring**: Automatically captures photos at regular intervals (every 50 seconds)
- **AI-Powered Door Detection**: Uses Roboflow machine learning models to detect door states (open/closed)
- **ESP32 Integration**: Sends door state commands to an ESP32 microcontroller via HTTP requests
- **Real-time Status Display**: Shows network connectivity, model status, and detection results
- **Automatic Operation**: Starts monitoring automatically when the app launches
- **Image Processing**: Optimizes captured images for ML inference and storage

## 🏗️ Architecture

The app consists of several key components:

- **CameraManager**: Handles camera permissions and photo capture
- **RoboflowManager**: Manages ML model loading and inference
- **NetworkManager**: Communicates with ESP32 microcontroller
- **TimerManager**: Controls the timing of photo capture cycles
- **ImageProcessor**: Optimizes images for ML processing
- **ImageSaver**: Saves processed images to device storage

## 📱 Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.0+
- Camera access permission
- Internet connection for Roboflow model loading
- ESP32 microcontroller with HTTP server

## 🚀 Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd door-closer-app
   ```

2. Open the project in Xcode:
   ```bash
   open app.xcodeproj
   ```

3. Configure Roboflow settings:
   - Create a `RoboflowConfig.swift` file in the `app` directory
   - Add your Roboflow API key and model configuration

4. Update ESP32 IP address:
   - Open `NetworkManager.swift`
   - Update the `esp32IPAddress` variable with your ESP32's IP address

5. Build and run the project on your iOS device

## ⚙️ Configuration

### RoboflowConfig.swift
Create this file with your Roboflow credentials:

```swift
struct RoboflowConfig {
    static let apiKey = "YOUR_ROBOFLOW_API_KEY"
    static let modelName = "YOUR_MODEL_NAME"
    static let modelVersion = "YOUR_MODEL_VERSION"
    static let confidenceThreshold: Float = 0.5
    static let overlapThreshold: Float = 0.5
    static let maxObjects: Int = 10
}
```

### ESP32 Configuration
Ensure your ESP32 is configured to:
- Run an HTTP server on port 80
- Accept GET requests to `/open` and `/closed` endpoints
- Be accessible on the same network as your iOS device

## 🔧 Usage

1. **Launch the App**: The app automatically requests camera permission and starts monitoring
2. **Countdown Phase**: A 10-second countdown gives you time to position the camera
3. **Continuous Capture**: Photos are automatically taken every 50 seconds
4. **Door Detection**: Each image is analyzed using the ML model
5. **State Communication**: Door states are automatically sent to the ESP32

## 📊 Status Indicators

The app displays several status indicators:

- **Network Status**: Green/red circle showing ESP32 connectivity
- **Model Status**: Indicates if the ML model is loaded and ready
- **Detection Results**: Shows the number of objects detected in the last image
- **Door State**: Displays the most recently detected door state
- **Photo Counter**: Tracks the number of photos taken in the current session

## 🔄 Operation Cycle

1. **Startup**: App launches and requests camera permissions
2. **Model Loading**: Roboflow model is downloaded and configured
3. **Countdown**: 10-second preparation period
4. **Photo Capture**: Images captured every 50 seconds
5. **ML Inference**: Each image is processed by the ML model
6. **State Detection**: Door state is determined from detection results
7. **ESP32 Communication**: State commands are sent to the microcontroller

## 🛠️ Troubleshooting

### Common Issues

- **Camera Permission Denied**: Ensure camera access is granted in iOS Settings
- **Model Loading Failed**: Check your Roboflow API key and internet connection
- **ESP32 Connection Failed**: Verify the IP address and network connectivity
- **Poor Detection Results**: Adjust confidence thresholds in RoboflowConfig

### Debug Information

The app provides detailed logging in the Xcode console:
- Camera operations
- ML model status
- Network communication
- Detection results

## 📁 Project Structure

```
door-closer-app/
├── app/
│   ├── ContentView.swift          # Main UI and app logic
│   ├── CameraManager.swift        # Camera handling
│   ├── RoboflowManager.swift      # ML model management
│   ├── NetworkManager.swift       # ESP32 communication
│   ├── TimerManager.swift         # Timing control
│   ├── ImageProcessor.swift       # Image optimization
│   ├── ImageSaver.swift          # Image storage
│   └── CameraPreviewView.swift   # Camera preview UI
├── app.xcodeproj/                 # Xcode project file
└── README.md                      # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Roboflow for providing the machine learning infrastructure
- Apple for SwiftUI and AVFoundation frameworks
- ESP32 community for microcontroller integration examples

## 📞 Support

For issues and questions:
- Check the troubleshooting section above
- Review the console logs for error details
- Ensure all configuration files are properly set up
- Verify network connectivity between iOS device and ESP32

---

**Note**: This app requires proper setup of both the iOS application and the ESP32 microcontroller. Ensure both components are configured correctly before testing.
