import Foundation
import Security
import Network
import SystemConfiguration
import UIKit

class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    @Published var isScanning = false
    @Published var lastScanDate: Date?
    @Published var threatsFound: [Threat] = []
    @Published var systemStatus: SystemStatus = .secure
    
    private let fileManager = FileManager.default
    private let securityQueue = DispatchQueue(label: "com.infinitum.security", qos: .userInitiated)
    
    enum SystemStatus {
        case secure
        case atRisk
        case compromised
    }
    
    struct Threat: Identifiable {
        let id = UUID()
        let name: String
        let type: ThreatType
        let severity: ThreatSeverity
        let location: String
        let description: String
        let timestamp: Date
        
        enum ThreatType {
            case malware
            case phishing
            case suspiciousActivity
            case unauthorizedAccess
            case dataLeak
        }
        
        enum ThreatSeverity {
            case low
            case medium
            case high
            case critical
        }
    }
    
    // MARK: - Virus Scanning
    
    func startVirusScan() async throws {
        isScanning = true
        defer { isScanning = false }
        
        // Get app directories to scan
        let directories = try getAppDirectories()
        
        // Scan each directory
        for directory in directories {
            try await scanDirectory(directory)
        }
        
        // Check for suspicious processes
        try await checkSuspiciousProcesses()
        
        // Verify system integrity
        try await verifySystemIntegrity()
        
        // Update last scan date
        lastScanDate = Date()
        
        // Update system status
        updateSystemStatus()
    }
    
    private func getAppDirectories() throws -> [URL] {
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let libraryDirectory = try fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let tmpDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        
        return [documentsDirectory, libraryDirectory, cachesDirectory, tmpDirectory]
    }
    
    private func scanDirectory(_ directory: URL) async throws {
        let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            guard try fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { continue }
            
            // Check file signature
            if try await isFileMalicious(fileURL) {
                let threat = Threat(
                    name: "Malicious File",
                    type: .malware,
                    severity: .high,
                    location: fileURL.path,
                    description: "Potentially malicious file detected",
                    timestamp: Date()
                )
                threatsFound.append(threat)
            }
            
            // Check file permissions
            if try await hasSuspiciousPermissions(fileURL) {
                let threat = Threat(
                    name: "Suspicious Permissions",
                    type: .unauthorizedAccess,
                    severity: .medium,
                    location: fileURL.path,
                    description: "File has suspicious permissions",
                    timestamp: Date()
                )
                threatsFound.append(threat)
            }
        }
    }
    
    private func isFileMalicious(_ fileURL: URL) async throws -> Bool {
        // Check file signature
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }
        
        // Read first 8 bytes for signature check
        let signature = try fileHandle.read(upToCount: 8)
        
        // Check against known malicious signatures
        let maliciousSignatures: [[UInt8]] = [
            [0x4D, 0x5A], // MZ header (Windows executables)
            [0x7F, 0x45, 0x4C, 0x46], // ELF header (Linux executables)
            [0xCA, 0xFE, 0xBA, 0xBE] // Java class file
        ]
        
        return maliciousSignatures.contains { signature == Data($0) }
    }
    
    private func hasSuspiciousPermissions(_ fileURL: URL) async throws -> Bool {
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        
        // Check for world-writable or world-executable permissions
        return (permissions?.intValue ?? 0) & 0o002 != 0
    }
    
    // MARK: - Process Monitoring
    
    private func checkSuspiciousProcesses() async throws {
        // On iOS, we can only check our own app's processes
        let processInfo = ProcessInfo.processInfo
        let activeProcessors = processInfo.activeProcessorCount
        let physicalMemory = processInfo.physicalMemory
        
        // Check for suspicious resource usage
        if activeProcessors > 2 || physicalMemory > 2_000_000_000 { // 2GB
            let threat = Threat(
                name: "High Resource Usage",
                type: .suspiciousActivity,
                severity: .high,
                location: "System Process",
                description: "Unusually high resource usage detected",
                timestamp: Date()
            )
            threatsFound.append(threat)
        }
    }
    
    // MARK: - System Integrity
    
    private func verifySystemIntegrity() async throws {
        // Check app files
        try await verifyAppFiles()
        
        // Check network connections
        try await checkNetworkConnections()
        
        // Check for unauthorized modifications
        try await checkSystemModifications()
    }
    
    private func verifyAppFiles() async throws {
        let appPaths = [
            Bundle.main.bundlePath,
            try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).path,
            try fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false).path
        ]
        
        for path in appPaths {
            let url = URL(fileURLWithPath: path)
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            
            // Check modification date
            if let modificationDate = attributes[.modificationDate] as? Date {
                let timeSinceModification = Date().timeIntervalSince(modificationDate)
                if timeSinceModification < 3600 { // Modified in the last hour
                    let threat = Threat(
                        name: "App File Modified",
                        type: .unauthorizedAccess,
                        severity: .high,
                        location: path,
                        description: "App file was recently modified",
                        timestamp: Date()
                    )
                    threatsFound.append(threat)
                }
            }
        }
    }
    
    private func checkNetworkConnections() async throws {
        // On iOS, we can only check our own app's network connections
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                // Check for suspicious interfaces
                if path.availableInterfaces.contains(where: { $0.type == .loopback || $0.type == .other }) {
                    let threat = Threat(
                        name: "Suspicious Network Connection",
                        type: .suspiciousActivity,
                        severity: .high,
                        location: "Network",
                        description: "Suspicious network interface detected",
                        timestamp: Date()
                    )
                    self?.threatsFound.append(threat)
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func checkSystemModifications() async throws {
        // On iOS, we can only check our own app's files
        let appDirectory = Bundle.main.bundlePath
        let url = URL(fileURLWithPath: appDirectory)
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        
        for file in contents {
            if try await isFileMalicious(file) {
                let threat = Threat(
                    name: "Unauthorized App Modification",
                    type: .unauthorizedAccess,
                    severity: .critical,
                    location: file.path,
                    description: "Unauthorized app modification detected",
                    timestamp: Date()
                )
                threatsFound.append(threat)
            }
        }
    }
    
    // MARK: - System Status
    
    private func updateSystemStatus() {
        let criticalThreats = threatsFound.filter { $0.severity == .critical }
        let highThreats = threatsFound.filter { $0.severity == .high }
        
        if !criticalThreats.isEmpty {
            systemStatus = .compromised
        } else if !highThreats.isEmpty {
            systemStatus = .atRisk
        } else {
            systemStatus = .secure
        }
    }
    
    // MARK: - Threat Removal
    
    func removeThreat(_ threat: Threat) async throws {
        // Remove the threat based on its type
        switch threat.type {
        case .malware, .unauthorizedAccess:
            try await removeMaliciousFile(at: URL(fileURLWithPath: threat.location))
        case .suspiciousActivity:
            // On iOS, we can't terminate processes
            break
        default:
            break
        }
        
        // Remove from threats list
        threatsFound.removeAll { $0.id == threat.id }
        
        // Update system status
        updateSystemStatus()
    }
    
    private func removeMaliciousFile(at url: URL) async throws {
        try fileManager.removeItem(at: url)
    }
} 