import SwiftUI
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - WCSessionDelegate Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle session activation
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session inactivity
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle receiving data from Watch
        NotificationCenter.default.post(name: Notification.Name("didReceiveMessage"), object: message)
    }
}

struct ContentView: View {
    @State private var temperature: Double?
    @State private var heartRate: Double?
    @State private var heartRates: [Double] = []
    @State private var hrv: Double?
    @State private var steps: Double?
    @State private var errorMessage: String?
    let healthKitManager = HealthKitManager()
    let homeKitManager = HomeKitManager()

    var body: some View {
        NavigationView {
            VStack {
                Text("Health Data Monitor")
                    .font(.largeTitle)
                    .padding()
                if let temperature = temperature {
                    Text("Body Temperature: \(temperature, specifier: "%.2f")°C")
                        .padding()
                }
                if let heartRate = heartRate {
                    Text("Heart Rate: \(heartRate, specifier: "%.2f") BPM")
                        .padding()
                }
                if let hrv = hrv {
                    Text("Heart Rate Variability: \(hrv, specifier: "%.2f") ms")
                        .padding()
                }
                if let steps = steps {
                    Text("Steps Today: \(Int(steps))")
                        .padding()
                }
                Text("Latest 5 Heart Rates")
                    .font(.largeTitle)
                    .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if heartRates.isEmpty {
                    Text("Fetching heart rate data...")
                        .padding()
                } else {
                    List(heartRates, id: \.self) { heartRate in
                        Text("\(heartRate, specifier: "%.2f") BPM")
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .padding()
                        .foregroundColor(.red)
                } else {
                    Text("Fetching health data...")
                        .padding()
                }
                Button(action: fetchHeartRates) {
                    Text("Refresh")
                        .padding()
                }
                
                NavigationLink(destination: HomeKitDevicesView()) {
                    Text("Go to HomeKit Devices")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }

            }
            .onAppear {
                requestHealthKitAuthorization()
            }
        }.navigationTitle("HomeKit and HealthKit")
    }

    func requestHealthKitAuthorization() {
        healthKitManager.requestAuthorization { (success, error) in
            DispatchQueue.main.async {
                if success {
                    print("HealthKit authorization successful")
                    self.fetchAllHealthData()
                } else {
                    self.errorMessage = "HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")"
                    print(self.errorMessage ?? "")
                }
            }
        }
    }

    func fetchHealthData() {
        healthKitManager.fetchBodyTemperature { (temperature, error) in
            if let error = error {
                self.errorMessage = "Failed to fetch temperature: \(error.localizedDescription)"
            } else {
                self.temperature = temperature
            }
        }

        healthKitManager.fetchHeartRate { (heartRate, error) in
            if let error = error {
                self.errorMessage = "Failed to fetch heart rate: \(error.localizedDescription)"
            } else {
                self.heartRate = heartRate
            }
        }
    }
    func fetchHeartRates() {
        healthKitManager.fetchLatestHeartRates { (rates, error) in
            if let rates = rates {
                heartRates = rates
                errorMessage = nil
            } else if let error = error {
                errorMessage = "Failed to fetch heart rates: \(error.localizedDescription)"
                heartRates = []
            }
        }
    }


    func setupNotificationObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name("didReceiveMessage"), object: nil, queue: .main) { notification in
            if let message = notification.object as? [String: Any] {
                if let watchHeartRate = message["heartRate"] as? Double {
                    self.heartRate = watchHeartRate
                }
                else {
                    print("There is an error")
                }
                if message["temperature"] is Double {
                    self.temperature = 75
                }
            }
        }
    }
    
    func fetchAllHealthData() {
        fetchHealthData()
        fetchHeartRates()
        fetchHRV()
        fetchSteps()
    }

    func fetchHRV() {
        healthKitManager.fetchHeartRateVariability { (hrv, error) in
            DispatchQueue.main.async {
                if let error = error {
                    if (error as NSError).code == 1 {
                        self.requestHealthKitAuthorization()
                    } else {
                        self.errorMessage = "Failed to fetch HRV: \(error.localizedDescription)"
                    }
                } else {
                    self.hrv = hrv
                    self.errorMessage = nil
                }
            }
        }
    }

    func fetchSteps() {
        healthKitManager.fetchSteps { (steps, error) in
            DispatchQueue.main.async {
                if let error = error {
                    if (error as NSError).code == 1 {
                        self.requestHealthKitAuthorization()
                    } else {
                        self.errorMessage = "Failed to fetch steps: \(error.localizedDescription)"
                    }
                } else {
                    self.steps = steps
                    self.errorMessage = nil
                }
            }
        }
    }
}

//WatchConectivityManager --> handles all the WC tasks and follows with the delegation
