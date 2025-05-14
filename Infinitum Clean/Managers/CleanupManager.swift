import Foundation
import Photos
import AVFoundation
import CoreLocation

class CleanupManager: ObservableObject {
    static let shared = CleanupManager()
    
    @Published var isCleaning = false
    @Published var lastCleanupDate: Date?
    @Published var cleanupProgress: Double = 0
    @Published var spaceFreed: Int64 = 0
    
    private let fileManager = FileManager.default
    private let cleanupQueue = DispatchQueue(label: "com.infinitum.cleanup", qos: .userInitiated)
    private let cachesDirectory: URL
    private let tempDirectory: URL
    private let downloadsDirectory: URL
    
    init() {
        // Get system directories
        cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        downloadsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Storage Info
    
    func getStorageInfo() async throws -> StorageInfo {
        let systemFilesSize = try await getSystemFilesSize()
        let cacheSize = try await getDirectorySize(cachesDirectory)
        let downloadsSize = try await getDirectorySize(downloadsDirectory)
        let tempFilesSize = try await getDirectorySize(tempDirectory)
        
        return StorageInfo(
            systemFilesSize: systemFilesSize,
            cacheSize: cacheSize,
            downloadsSize: downloadsSize,
            tempFilesSize: tempFilesSize
        )
    }
    
    private func getSystemFilesSize() async throws -> Int64 {
        // Get system files size from various locations
        var totalSize: Int64 = 0
        
        // System logs
        if let logsSize = try? await getDirectorySize(URL(fileURLWithPath: "/var/log")) {
            totalSize += logsSize
        }
        
        // System caches
        if let systemCacheSize = try? await getDirectorySize(URL(fileURLWithPath: "/Library/Caches")) {
            totalSize += systemCacheSize
        }
        
        // Application support
        if let appSupportSize = try? await getDirectorySize(URL(fileURLWithPath: "/Library/Application Support")) {
            totalSize += appSupportSize
        }
        
        return totalSize
    }
    
    private func getDirectorySize(_ url: URL) async throws -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else { return 0 }
        
        var totalSize: Int64 = 0
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else { continue }
            totalSize += Int64(fileSize)
        }
        
        return totalSize
    }
    
    // MARK: - System Scan
    
    func scanSystem() async throws -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        // Scan system files
        if let systemItems = try? await scanDirectory(cachesDirectory, type: .system) {
            items.append(contentsOf: systemItems)
        }
        
        // Scan cache
        if let cacheItems = try? await scanDirectory(cachesDirectory, type: .cache) {
            items.append(contentsOf: cacheItems)
        }
        
        // Scan downloads
        if let downloadItems = try? await scanDirectory(downloadsDirectory, type: .downloads) {
            items.append(contentsOf: downloadItems)
        }
        
        // Scan temp files
        if let tempItems = try? await scanDirectory(tempDirectory, type: .temp) {
            items.append(contentsOf: tempItems)
        }
        
        return items
    }
    
    private func scanDirectory(_ url: URL, type: CleanupItemType) async throws -> [CleanupItem] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        
        var items: [CleanupItem] = []
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let fileSize = resourceValues.fileSize,
                  let modificationDate = resourceValues.contentModificationDate else { continue }
            
            let item = CleanupItem(
                url: fileURL,
                size: Int64(fileSize),
                type: type,
                lastModified: modificationDate
            )
            items.append(item)
        }
        
        return items
    }
    
    // MARK: - Cleanup Operations
    
    func startCleanup() async throws {
        isCleaning = true
        cleanupProgress = 0
        spaceFreed = 0
        
        defer {
            isCleaning = false
            lastCleanupDate = Date()
        }
        
        // Clear system caches
        try await clearSystemCaches()
        cleanupProgress = 0.2
        
        // Clear application caches
        try await clearApplicationCaches()
        cleanupProgress = 0.4
        
        // Clear temporary files
        try await clearTemporaryFiles()
        cleanupProgress = 0.6
        
        // Clear logs
        try await clearLogs()
        cleanupProgress = 0.8
        
        // Optimize system
        try await optimizeSystem()
        cleanupProgress = 1.0
    }
    
    // MARK: - Cache Clearing
    
    private func clearSystemCaches() async throws {
        let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        try await clearDirectory(cachesDirectory)
    }
    
    private func clearApplicationCaches() async throws {
        let appCachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        try await clearDirectory(appCachesDirectory)
    }
    
    private func clearTemporaryFiles() async throws {
        let tmpDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        try await clearDirectory(tmpDirectory)
    }
    
    private func clearLogs() async throws {
        let libraryDirectory = try fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let logsDirectory = libraryDirectory.appendingPathComponent("Logs")
        try await clearDirectory(logsDirectory)
    }
    
    private func clearDirectory(_ directory: URL) async throws {
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
        
        for file in contents {
            let attributes = try fileManager.attributesOfItem(atPath: file.path)
            if let fileSize = attributes[.size] as? Int64 {
                spaceFreed += fileSize
            }
            
            try fileManager.removeItem(at: file)
        }
    }
    
    // MARK: - System Optimization
    
    private func optimizeSystem() async throws {
        // Clear memory cache
        try await clearMemoryCache()
        
        // Optimize disk
        try await optimizeDisk()
    }
    
    private func clearMemoryCache() async throws {
        // On iOS, we can only clear our app's memory cache
        URLCache.shared.removeAllCachedResponses()
    }
    
    private func optimizeDisk() async throws {
        // On iOS, we can only optimize our app's storage
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let libraryDirectory = try fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        
        // Remove old files
        try await removeOldFiles(in: documentsDirectory)
        try await removeOldFiles(in: libraryDirectory)
    }
    
    private func removeOldFiles(in directory: URL) async throws {
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
        
        let oldDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        for file in contents {
            let attributes = try fileManager.attributesOfItem(atPath: file.path)
            if let modificationDate = attributes[.modificationDate] as? Date,
               modificationDate < oldDate {
                if let fileSize = attributes[.size] as? Int64 {
                    spaceFreed += fileSize
                }
                try fileManager.removeItem(at: file)
            }
        }
    }
    
    // MARK: - Space Analysis
    
    func analyzeDiskSpace() async throws -> [String: Int64] {
        var spaceInfo: [String: Int64] = [:]
        
        // Get app's documents directory size
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        spaceInfo["documents"] = try await getDirectorySize(documentsDirectory)
        
        // Get app's library directory size
        let libraryDirectory = try fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        spaceInfo["library"] = try await getDirectorySize(libraryDirectory)
        
        // Get app's caches directory size
        let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        spaceInfo["caches"] = try await getDirectorySize(cachesDirectory)
        
        return spaceInfo
    }
    
    // MARK: - Performance Monitoring
    
    func monitorSystemPerformance() async throws -> [String: Double] {
        var performance: [String: Double] = [:]
        
        // Get CPU usage
        performance["cpuUsage"] = getCPUUsage()
        
        // Get memory usage
        performance["memoryUsage"] = getMemoryUsage()
        
        // Get disk usage
        performance["diskUsage"] = try await getDiskUsage()
        
        return performance
    }
    
    private func getCPUUsage() -> Double {
        // On iOS, we can only get our app's CPU usage
        let processInfo = ProcessInfo.processInfo
        return Double(processInfo.activeProcessorCount) / Double(processInfo.processorCount)
    }
    
    private func getMemoryUsage() -> Double {
        // On iOS, we can only get our app's memory usage
        let processInfo = ProcessInfo.processInfo
        return Double(processInfo.physicalMemory) / Double(1024 * 1024 * 1024) // Convert to GB
    }
    
    private func getDiskUsage() async throws -> Double {
        let spaceInfo = try await analyzeDiskSpace()
        let totalSpace = spaceInfo.values.reduce(0, +)
        return Double(totalSpace) / Double(1024 * 1024 * 1024) // Convert to GB
    }
    
    func cleanCache() async throws -> Int64 {
        let items = try await scanDirectory(cachesDirectory, type: .cache)
        var totalCleaned: Int64 = 0
        
        for item in items {
            do {
                try fileManager.removeItem(at: item.url)
                totalCleaned += item.size
            } catch {
                AppLogger.shared.error("Failed to remove cache item: \(error.localizedDescription)", category: .cleanup)
            }
        }
        
        return totalCleaned
    }
    
    func optimizeStorage() async throws -> Int64 {
        var totalOptimized: Int64 = 0
        
        // Clean old temporary files
        let tempItems = try await scanDirectory(tempDirectory, type: .temp)
        for item in tempItems where item.isOld {
            do {
                try fileManager.removeItem(at: item.url)
                totalOptimized += item.size
            } catch {
                AppLogger.shared.error("Failed to remove temp item: \(error.localizedDescription)", category: .cleanup)
            }
        }
        
        // Clean old cache files
        let cacheItems = try await scanDirectory(cachesDirectory, type: .cache)
        for item in cacheItems where item.isOld {
            do {
                try fileManager.removeItem(at: item.url)
                totalOptimized += item.size
            } catch {
                AppLogger.shared.error("Failed to remove cache item: \(error.localizedDescription)", category: .cleanup)
            }
        }
        
        return totalOptimized
    }
}

// MARK: - Supporting Types

struct CleanupItem {
    let url: URL
    let size: Int64
    let type: CleanupItemType
    let lastModified: Date
    
    var isOld: Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return lastModified < thirtyDaysAgo
    }
}

enum CleanupItemType {
    case system
    case cache
    case downloads
    case temp
} 