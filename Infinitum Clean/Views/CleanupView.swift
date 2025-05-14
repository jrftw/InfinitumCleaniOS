import SwiftUI
import Photos
import AVFoundation
import CoreLocation

struct CleanupView: View {
    @StateObject private var cleanupManager = CleanupManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isScanning = false
    @State private var storageInfo: StorageInfo?
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Storage Overview Card
                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Storage Overview")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.textPrimary)
                                
                                if let info = storageInfo {
                                    StorageRow(title: "System Files", size: formatSize(info.systemFilesSize), icon: "folder.fill")
                                    StorageRow(title: "Cache", size: formatSize(info.cacheSize), icon: "archivebox.fill")
                                    StorageRow(title: "Downloads", size: formatSize(info.downloadsSize), icon: "arrow.down.circle.fill")
                                    StorageRow(title: "Temporary Files", size: formatSize(info.tempFilesSize), icon: "clock.fill")
                                } else {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
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
                                AppLogger.shared.info("Starting system scan", category: .cleanup)
                                Task {
                                    await scanSystem()
                                }
                            }
                            
                            ActionButton(
                                title: "Clean Cache",
                                icon: "trash",
                                color: Theme.secondary
                            ) {
                                AppLogger.shared.info("Starting cache cleanup", category: .cleanup)
                                Task {
                                    await cleanupCache()
                                }
                            }
                            
                            ActionButton(
                                title: "Optimize Storage",
                                icon: "arrow.up.arrow.down",
                                color: Theme.primary
                            ) {
                                AppLogger.shared.info("Starting storage optimization", category: .cleanup)
                                Task {
                                    await optimizeStorage()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Cleanup")
            .modernNavigationBar()
            .alert("Status", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isScanning {
                    scanningOverlay
                }
            }
            .task {
                await loadStorageInfo()
            }
        }
        .debugView("CleanupView")
        .logViewAppear("CleanupView appeared", category: .ui)
    }
    
    private func loadStorageInfo() async {
        do {
            storageInfo = try await cleanupManager.getStorageInfo()
        } catch {
            AppLogger.shared.error("Failed to load storage info: \(error.localizedDescription)", category: .cleanup)
            alertMessage = "Failed to load storage information"
            showingAlert = true
        }
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func scanSystem() async {
        isScanning = true
        do {
            let results = try await cleanupManager.scanSystem()
            alertMessage = "Found \(results.count) items to clean"
            showingAlert = true
        } catch {
            alertMessage = "Scan failed: \(error.localizedDescription)"
            showingAlert = true
        }
        isScanning = false
    }
    
    private func cleanupCache() async {
        isScanning = true
        do {
            let cleaned = try await cleanupManager.cleanCache()
            alertMessage = "Cleaned \(formatSize(cleaned)) of cache"
            showingAlert = true
            await loadStorageInfo() // Refresh storage info
        } catch {
            alertMessage = "Cleanup failed: \(error.localizedDescription)"
            showingAlert = true
        }
        isScanning = false
    }
    
    private func optimizeStorage() async {
        isScanning = true
        do {
            let optimized = try await cleanupManager.optimizeStorage()
            alertMessage = "Optimized \(formatSize(optimized)) of storage"
            showingAlert = true
            await loadStorageInfo() // Refresh storage info
        } catch {
            alertMessage = "Optimization failed: \(error.localizedDescription)"
            showingAlert = true
        }
        isScanning = false
    }
    
    private var scanningOverlay: some View {
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

struct StorageRow: View {
    let title: String
    let size: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.primary)
            Text(title)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text(size)
                .foregroundColor(Theme.textSecondary)
                .fontWeight(.medium)
        }
    }
}

struct StorageInfo {
    let systemFilesSize: Int64
    let cacheSize: Int64
    let downloadsSize: Int64
    let tempFilesSize: Int64
}

#Preview {
    CleanupView()
} 