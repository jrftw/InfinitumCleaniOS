import SwiftUI

struct ContentView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @Binding var showAds: Bool
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isScanning = false
    @State private var selectedTab = 0
    @State private var isSubscribed = false
    
    var body: some View {
        ZStack {
            // Background
            Theme.background
                .ignoresSafeArea()
            
            // Main Content
            TabView(selection: $selectedTab) {
                mainView
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                CleanupView()
                    .tabItem {
                        Label("Clean", systemImage: "sparkles")
                    }
                    .tag(1)
                
                SecurityView()
                    .tabItem {
                        Label("Security", systemImage: "shield.fill")
                    }
                    .tag(2)
                
                CallProtectionView()
                    .tabItem {
                        Label("Calls", systemImage: "phone.down")
                    }
                    .tag(3)
                
                HealthView()
                    .tabItem {
                        Label("Health", systemImage: "heart.text.square")
                    }
                    .tag(4)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(5)
                
                if !isSubscribed {
                    PremiumView()
                        .tabItem {
                            Label("Premium", systemImage: "star.fill")
                        }
                        .tag(6)
                }
            }
            .tint(Theme.primary)
        }
        .alert("Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .debugView("ContentView")
        .logViewAppear("ContentView appeared", category: .ui)
        .task {
            // Update subscription status
            isSubscribed = await storeManager.isSubscribed()
            
            // Listen for subscription changes
            for await _ in storeManager.$purchasedSubscriptions.values {
                isSubscribed = await storeManager.isSubscribed()
                showAds = !isSubscribed
            }
        }
    }
    
    private var mainView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Health Status Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("System Health")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)
                            
                            HealthMetricRow(title: "Battery Health", value: "98%", icon: "battery.100")
                            HealthMetricRow(title: "Temperature", value: "Normal", icon: "thermometer")
                            HealthMetricRow(title: "CPU Usage", value: "32%", icon: "cpu")
                            HealthMetricRow(title: "Memory Pressure", value: "Low", icon: "memorychip")
                            HealthMetricRow(title: "Storage Space", value: "64GB Free", icon: "externaldrive")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        ActionButton(
                            title: "Scan System",
                            icon: "magnifyingglass",
                            color: Theme.primary
                        ) {
                            AppLogger.shared.info("Starting system scan", category: .health)
                            isScanning = true
                            // Simulate scanning
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isScanning = false
                                alertMessage = "System scan completed successfully"
                                showingAlert = true
                                AppLogger.shared.info("System scan completed", category: .health)
                            }
                        }
                        
                        ActionButton(
                            title: "Clean System",
                            icon: "sparkles",
                            color: Theme.secondary
                        ) {
                            AppLogger.shared.info("Starting system cleanup", category: .cleanup)
                            selectedTab = 1
                        }
                        
                        ActionButton(
                            title: "Security Check",
                            icon: "shield.checkerboard",
                            color: Theme.primary
                        ) {
                            AppLogger.shared.info("Starting security check", category: .security)
                            selectedTab = 2
                        }
                        
                        ActionButton(
                            title: "Optimize Performance",
                            icon: "gauge",
                            color: Theme.secondary
                        ) {
                            AppLogger.shared.info("Starting performance optimization", category: .performance)
                            alertMessage = "Performance optimized"
                            showingAlert = true
                        }
                    }
                    .padding(.horizontal)
                    
                    // Ad Banner
                    if showAds {
                        AdBannerView()
                            .frame(height: 50)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Infinitum Clean")
            .modernNavigationBar()
        }
        .overlay {
            if isScanning {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Scanning...")
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                }
            }
        }
    }
}

struct AdBannerView: View {
    var body: some View {
        // Placeholder for ad banner
        Rectangle()
            .fill(Theme.card)
            .overlay {
                Text("Advertisement")
                    .foregroundColor(Theme.textSecondary)
            }
    }
}

#Preview {
    ContentView(showAds: .constant(true))
} 