import UIKit
import CoreImage

class ImageProcessor {
    static func processImage(_ image: UIImage) -> UIImage? {
        // Convert to grayscale
        guard let grayscaleImage = convertToGrayscale(image) else { return nil }
        
        // Resize to lower resolution
        guard let resizedImage = resizeImage(grayscaleImage, maxSize: 320) else { return nil }
        
        // Compress to ensure <500KB
        return compressImage(resizedImage, maxSizeKB: 500)
    }
    
    private static func convertToGrayscale(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(0.0, forKey: kCIInputSaturationKey) // 0 = grayscale
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    private static func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage? {
        let originalSize = image.size
        let scale = min(maxSize / originalSize.width, maxSize / originalSize.height)
        
        if scale >= 1.0 {
            return image // No need to resize
        }
        
        let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    private static func compressImage(_ image: UIImage, maxSizeKB: Int) -> UIImage? {
        var compression: CGFloat = 1.0
        let maxSizeBytes = maxSizeKB * 1024
        
        while true {
            guard let imageData = image.jpegData(compressionQuality: compression) else { return nil }
            
            if imageData.count <= maxSizeBytes || compression <= 0.1 {
                return UIImage(data: imageData)
            }
            
            compression -= 0.1
        }
    }
    
    static func getImageSizeKB(_ image: UIImage) -> Int {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return 0 }
        return imageData.count / 1024
    }
}
