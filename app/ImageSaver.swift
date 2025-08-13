import UIKit
import Photos

class ImageSaver: NSObject, ObservableObject {
    @Published var isSaving = false
    @Published var saveStatus = ""
    @Published var imagesSaved = 0
    
    func saveImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.isSaving = true
            self.saveStatus = "Saving image..."
        }
        
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.performSave(image)
                } else {
                    self?.isSaving = false
                    self?.saveStatus = "Photo library access denied"
                }
            }
        }
    }
    
    private func performSave(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isSaving = false
                
                if success {
                    self?.imagesSaved += 1
                    self?.saveStatus = "Saved \(self?.imagesSaved ?? 0) images"
                } else {
                    self?.saveStatus = "Failed to save: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
    
    func resetCounter() {
        imagesSaved = 0
        saveStatus = ""
    }
}
