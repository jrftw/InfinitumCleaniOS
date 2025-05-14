import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            AppLogger.shared.info("Dark mode toggled: \(isDarkMode)", category: .ui)
        }
    }
    
    @Published var isAutoMode: Bool {
        didSet {
            UserDefaults.standard.set(isAutoMode, forKey: "isAutoMode")
            AppLogger.shared.info("Auto mode toggled: \(isAutoMode)", category: .ui)
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            AppLogger.shared.info("Notifications toggled: \(notificationsEnabled)", category: .ui)
        }
    }
    
    @Published var autoCleanupEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoCleanupEnabled, forKey: "autoCleanupEnabled")
            AppLogger.shared.info("Auto cleanup toggled: \(autoCleanupEnabled)", category: .cleanup)
        }
    }
    
    @Published var securityScanEnabled: Bool {
        didSet {
            UserDefaults.standard.set(securityScanEnabled, forKey: "securityScanEnabled")
            AppLogger.shared.info("Security scan toggled: \(securityScanEnabled)", category: .security)
        }
    }
    
    @Published var callProtectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(callProtectionEnabled, forKey: "callProtectionEnabled")
            AppLogger.shared.info("Call protection toggled: \(callProtectionEnabled)", category: .security)
        }
    }
    
    private init() {
        // Load saved settings or use defaults
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.isAutoMode = UserDefaults.standard.bool(forKey: "isAutoMode")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.autoCleanupEnabled = UserDefaults.standard.bool(forKey: "autoCleanupEnabled")
        self.securityScanEnabled = UserDefaults.standard.bool(forKey: "securityScanEnabled")
        self.callProtectionEnabled = UserDefaults.standard.bool(forKey: "callProtectionEnabled")
        
        AppLogger.shared.info("Settings initialized", category: .app)
    }
    
    func resetToDefaults() {
        isDarkMode = false
        isAutoMode = true
        notificationsEnabled = true
        autoCleanupEnabled = false
        securityScanEnabled = true
        callProtectionEnabled = true
        
        AppLogger.shared.info("Settings reset to defaults", category: .app)
    }
    
    func saveSettings() {
        UserDefaults.standard.synchronize()
        AppLogger.shared.info("Settings saved", category: .app)
    }
} 