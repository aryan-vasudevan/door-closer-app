import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeRemaining = 10
    @Published var isRunning = false
    @Published var photosTaken = 0
    @Published var isCountdownPhase = true
    
    private var countdownTimer: Timer?
    private var photoTimer: Timer?
    private var onCountdownComplete: (() -> Void)?
    private var onPhotoCapture: (() -> Void)?
    
    func startTimer(onCountdownComplete: @escaping () -> Void, onPhotoCapture: @escaping () -> Void) {
        self.onCountdownComplete = onCountdownComplete
        self.onPhotoCapture = onPhotoCapture
        timeRemaining = 10
        photosTaken = 0
        isRunning = true
        isCountdownPhase = true
        
        // Start countdown timer first
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.timeRemaining -= 1
                
                if self?.timeRemaining == 0 {
                    self?.startPhotoCapture()
                }
            }
        }
    }
    
    private func startPhotoCapture() {
        isCountdownPhase = false
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // Call the countdown complete callback
        onCountdownComplete?()
        
        // Start photo capture timer (take photo every 50 seconds - allows full actuator cycle)
        photoTimer = Timer.scheduledTimer(withTimeInterval: 50.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.photosTaken += 1
                self?.onPhotoCapture?()
            }
        }
    }
    
    func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        photoTimer?.invalidate()
        photoTimer = nil
        isRunning = false
        isCountdownPhase = true
    }
    
    func resetTimer() {
        stopTimer()
        timeRemaining = 10
        photosTaken = 0
        isCountdownPhase = true
    }
}
