import Foundation

class NetworkManager: ObservableObject {
    @Published var isConnected = false
    @Published var lastSentState = ""
    @Published var connectionStatus = "Not connected"
    
    // ESP32 server configuration - update with your ESP32's IP address
    private let esp32IPAddress = "10.0.0.29" // Update this with your ESP32's IP
    private let esp32Port = 80
    
    func sendDoorState(_ state: String) {
        let endpoint = state == "open" ? "/open" : "/closed"
        guard let url = URL(string: "http://\(esp32IPAddress):\(esp32Port)\(endpoint)") else {
            print("❌ Invalid URL")
            return
        }
        
        print("📡 Sending door state '\(state)' to ESP32 at \(url)")
        
        // Send simple GET request
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    self?.connectionStatus = "Connection failed: \(error.localizedDescription)"
                    self?.isConnected = false
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Door state '\(state)' sent successfully to ESP32")
                        self?.lastSentState = state
                        self?.connectionStatus = "Connected - Last sent: \(state)"
                        self?.isConnected = true
                    } else {
                        print("❌ HTTP error: \(httpResponse.statusCode)")
                        self?.connectionStatus = "HTTP error: \(httpResponse.statusCode)"
                        self?.isConnected = false
                    }
                }
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📨 ESP32 response: \(responseString)")
                }
            }
        }.resume()
    }
    
    func testConnection() {
        guard let url = URL(string: "http://\(esp32IPAddress):\(esp32Port)/") else {
            print("❌ Invalid URL for connection test")
            return
        }
        
        print("🔍 Testing connection to ESP32...")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Connection test failed: \(error.localizedDescription)")
                    self?.connectionStatus = "Connection failed"
                    self?.isConnected = false
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("✅ Connection to ESP32 successful")
                    self?.connectionStatus = "Connected to ESP32"
                    self?.isConnected = true
                } else {
                    print("❌ Connection test failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    self?.connectionStatus = "Connection failed"
                    self?.isConnected = false
                }
            }
        }.resume()
    }
}
