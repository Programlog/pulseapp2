import SwiftUI

struct HomeKitDevicesView: View {
    @ObservedObject var homeKitManager = HomeKitManager()
    
    var body: some View {
        NavigationView {
            VStack {
                // List to display the devices
                List(homeKitManager.devices, id: \.uniqueIdentifier) { device in
                    VStack(alignment: .leading) {
                        Text(device.name)
                            .font(.headline)
                        Text(device.category.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Button to add and set up new accessories
                Button("Add and Setup Accessories") {
                    homeKitManager.addAndSetupAccessories()
                }
                .padding()
            }
            .navigationTitle("HomeKit Devices")
            .onAppear {
                homeKitManager.fetchDevices()
            }
        }
    }
}

#Preview {
    HomeKitDevicesView(homeKitManager: HomeKitManager())
}
