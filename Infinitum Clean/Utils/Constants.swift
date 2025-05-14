import Foundation

enum Constants {
    enum App {
        static let name = "Infinitum Clean"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.infinitumclean"
    }
    
    enum StoreKit {
        static let premiumFeaturesID = "com.infinitumclean.premium.features"
        static let monthlySubscriptionID = "com.infinitumclean.premium.monthly"
        static let yearlySubscriptionID = "com.infinitumclean.premium.yearly"
        
        static let subscriptionGroupID = "group1"
        static let subscriptionGroupName = "Premium Subscriptions"
    }
    
    enum AdMob {
        static let appID = "ca-app-pub-6815311336585204~3615279515"
        static let bannerAdUnitID = "ca-app-pub-6815311336585204/2358038166"
        static let interstitialAdUnitID = "ca-app-pub-6815311336585204/9507809998"
        static let rewardedAdUnitID = "ca-app-pub-6815311336585204/9507809998" // Using interstitial ID temporarily
    }
    
    enum UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastScanDate = "lastScanDate"
        static let lastBackupDate = "lastBackupDate"
        static let userPreferences = "userPreferences"
    }
    
    enum Notifications {
        static let scanComplete = "scanComplete"
        static let backupComplete = "backupComplete"
        static let securityAlert = "securityAlert"
        static let subscriptionStatusChanged = "subscriptionStatusChanged"
    }
    
    enum API {
        static let baseURL = "https://api.infinitumclean.com"
        static let version = "v1"
        static let timeout: TimeInterval = 30
    }
    
    enum Security {
        static let encryptionKey = "YOUR_ENCRYPTION_KEY"
        static let minimumPasswordLength = 8
        static let maximumLoginAttempts = 5
        static let lockoutDuration: TimeInterval = 300 // 5 minutes
    }
    
    enum Cache {
        static let maxSize: Int64 = 100 * 1024 * 1024 // 100 MB
        static let cleanupInterval: TimeInterval = 86400 // 24 hours
    }
    
    enum Analytics {
        static let enabled = true
        static let logLevel: LogLevel = .info
    }
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
} 