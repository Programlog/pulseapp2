import HomeKit

class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate {
    @Published var devices: [HMAccessory] = []
    private var homeManager = HMHomeManager()

    override init() {
        super.init()
        homeManager.delegate = self
    }
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        fetchDevices()
    }
    
    func fetchDevices() {
        devices = homeManager.homes.flatMap { $0.accessories }
    }
    
    func addAndSetupAccessories() {
        guard let home = homeManager.homes.first else {
            print("No homes are available")
            return
        }
        
        home.addAndSetupAccessories { error in
            if let error = error {
                print("Error setting up accessories: \(error.localizedDescription)")
            } else {
                // Reload devices list after adding
                self.fetchDevices()
            }
        }
    }
    
}
