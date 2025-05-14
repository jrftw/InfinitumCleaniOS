import SwiftUI
import Contacts
import Photos
import AVFoundation
import CoreLocation
import PhotosUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var showingResetAlert = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Appearance Settings
                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Appearance")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.textPrimary)
                                
                                ToggleRow(
                                    title: "Dark Mode",
                                    icon: "moon.fill",
                                    isOn: $settings.isDarkMode
                                )
                                
                                ToggleRow(
                                    title: "Auto Mode",
                                    icon: "sun.max.fill",
                                    isOn: $settings.isAutoMode
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Notification Settings
                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Notifications")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.textPrimary)
                                
                                ToggleRow(
                                    title: "Enable Notifications",
                                    icon: "bell.fill",
                                    isOn: $settings.notificationsEnabled
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Automation Settings
                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Automation")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.textPrimary)
                                
                                ToggleRow(
                                    title: "Auto Cleanup",
                                    icon: "sparkles",
                                    isOn: $settings.autoCleanupEnabled
                                )
                                
                                ToggleRow(
                                    title: "Security Scan",
                                    icon: "shield.checkerboard",
                                    isOn: $settings.securityScanEnabled
                                )
                                
                                ToggleRow(
                                    title: "Call Protection",
                                    icon: "phone.down",
                                    isOn: $settings.callProtectionEnabled
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Permissions
                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Permissions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.textPrimary)
                                
                                PermissionRow(
                                    title: "Contacts",
                                    icon: "person.2.fill",
                                    status: getContactsPermissionStatus()
                                ) {
                                    requestContactsPermission()
                                }
                                
                                PermissionRow(
                                    title: "Photos",
                                    icon: "photo.fill",
                                    status: getPhotosPermissionStatus()
                                ) {
                                    requestPhotosPermission()
                                }
                                
                                PermissionRow(
                                    title: "Camera",
                                    icon: "camera.fill",
                                    status: getCameraPermissionStatus()
                                ) {
                                    requestCameraPermission()
                                }
                                
                                PermissionRow(
                                    title: "Microphone",
                                    icon: "mic.fill",
                                    status: getMicrophonePermissionStatus()
                                ) {
                                    requestMicrophonePermission()
                                }
                                
                                PermissionRow(
                                    title: "Location",
                                    icon: "location.fill",
                                    status: getLocationPermissionStatus()
                                ) {
                                    requestLocationPermission()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Reset Settings
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            Text("Reset All Settings")
                                .foregroundColor(Theme.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Theme.card)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Settings")
            .modernNavigationBar()
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    settings.resetToDefaults()
                }
            } message: {
                Text("Are you sure you want to reset all settings to their default values?")
            }
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(permissionAlertMessage)
            }
        }
        .debugView("SettingsView")
        .logViewAppear("SettingsView appeared", category: .ui)
    }
    
    private func getContactsPermissionStatus() -> PermissionStatus {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        AppLogger.shared.debug("Contacts permission status: \(status.rawValue)", category: .security)
        return status == .authorized ? .granted : .denied
    }
    
    private func getPhotosPermissionStatus() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        AppLogger.shared.debug("Photos permission status: \(status.rawValue)", category: .security)
        return status == .authorized ? .granted : .denied
    }
    
    private func getCameraPermissionStatus() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        AppLogger.shared.debug("Camera permission status: \(status.rawValue)", category: .security)
        return status == .authorized ? .granted : .denied
    }
    
    private func getMicrophonePermissionStatus() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        AppLogger.shared.debug("Microphone permission status: \(status.rawValue)", category: .security)
        return status == .authorized ? .granted : .denied
    }
    
    private func getLocationPermissionStatus() -> PermissionStatus {
        let status = CLLocationManager().authorizationStatus
        AppLogger.shared.debug("Location permission status: \(status.rawValue)", category: .security)
        return status == .authorizedWhenInUse || status == .authorizedAlways ? .granted : .denied
    }
    
    private func requestContactsPermission() {
        AppLogger.shared.info("Requesting contacts permission", category: .security)
        CNContactStore().requestAccess(for: .contacts) { granted, error in
            if let error = error {
                AppLogger.shared.error("Contacts permission error: \(error.localizedDescription)", category: .security)
                return
            }
            AppLogger.shared.info("Contacts permission granted: \(granted)", category: .security)
        }
    }
    
    private func requestPhotosPermission() {
        AppLogger.shared.info("Requesting photos permission", category: .security)
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            AppLogger.shared.info("Photos permission status: \(status.rawValue)", category: .security)
        }
    }
    
    private func requestCameraPermission() {
        AppLogger.shared.info("Requesting camera permission", category: .security)
        AVCaptureDevice.requestAccess(for: .video) { granted in
            AppLogger.shared.info("Camera permission granted: \(granted)", category: .security)
        }
    }
    
    private func requestMicrophonePermission() {
        AppLogger.shared.info("Requesting microphone permission", category: .security)
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            AppLogger.shared.info("Microphone permission granted: \(granted)", category: .security)
        }
    }
    
    private func requestLocationPermission() {
        AppLogger.shared.info("Requesting location permission", category: .security)
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }
}

struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.primary)
                Text(title)
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .tint(Theme.primary)
    }
}

struct PermissionRow: View {
    let title: String
    let icon: String
    let status: PermissionStatus
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.primary)
                Text(title)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                statusIcon
            }
        }
    }
    
    private var statusIcon: some View {
        Image(systemName: status.icon)
            .foregroundColor(status.color)
    }
}

enum PermissionStatus {
    case granted
    case denied
    
    var icon: String {
        switch self {
        case .granted:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .granted:
            return Theme.primary
        case .denied:
            return Theme.secondary
        }
    }
}

#Preview {
    SettingsView()
} 