import Foundation
import Combine
import UIKit
import CoreTelephony
import SystemConfiguration

enum HealthIssueType: String, Codable {
    case battery, temperature, memory, storage, security
}

enum HealthIssueSeverity: String, Codable {
    case low, medium, high
}

enum SystemHealthStatus {
    case good, warning, critical
}

struct HealthIssue: Identifiable, Codable {
    let id: UUID
    let type: HealthIssueType
    let severity: HealthIssueSeverity
    let message: String
    let timestamp: Date

    init(type: HealthIssueType, severity: HealthIssueSeverity, message: String) {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.message = message
        self.timestamp = Date()
    }
}

@MainActor
class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @Published private(set) var batteryHealth: Double = 1.0
    @Published private(set) var temperature: Double = 0.0
    @Published private(set) var cpuUsage: Double = 0.0
    @Published private(set) var memoryPressure: Double = 0.0
    @Published private(set) var storageSpace: Double = 1.0
    @Published private(set) var totalStorageSpace: Int64 = 0
    @Published private(set) var usedStorageSpace: Int64 = 0
    @Published private(set) var systemHealthStatus: SystemHealthStatus = .good
    @Published private(set) var healthIssues: [HealthIssue] = []

    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?

    private init() {
        setupMonitoring()
    }

    func startMonitoring() async {
        await updateAllMetrics()
        if monitoringTimer == nil {
            monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                Task { await self?.updateAllMetrics() }
            }
        }
    }

    private func setupMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                Task { await self?.updateBatteryHealth() }
            }
            .store(in: &cancellables)
    }

    private func updateAllMetrics() async {
        await updateBatteryHealth()
        await updateTemperature()
        await updateCPUUsage()
        await updateMemoryPressure()
        await updateStorageSpace()
        await checkSystemHealth()
    }

    private func updateBatteryHealth() async {
        let device = UIDevice.current
        var health = 1.0
        let batteryLevel = device.batteryLevel
        let state = device.batteryState

        if batteryLevel < 0.2 {
            health *= 0.8
            addHealthIssue(type: .battery, severity: .medium, message: "Battery level critically low")
        } else if batteryLevel < 0.4 {
            health *= 0.9
            addHealthIssue(type: .battery, severity: .low, message: "Battery level low")
        }

        if state == .charging && batteryLevel < 0.9 {
            health *= 0.95
            addHealthIssue(type: .battery, severity: .low, message: "Slow charging detected")
        }

        self.batteryHealth = health
    }

    private func updateTemperature() async {
        // Approximation: iOS doesn't expose thermal state anymore
        let temp = 30.0
        self.temperature = temp
    }

    private func updateCPUUsage() async {
        // Mock implementation — replace with real method if needed
        self.cpuUsage = Double.random(in: 0.2...0.8)
    }

    private func updateMemoryPressure() async {
        // Mock implementation — replace with real method if needed
        self.memoryPressure = Double.random(in: 0.2...0.8)
    }

    private func updateStorageSpace() async {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let free = (attrs[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            let total = (attrs[.systemSize] as? NSNumber)?.int64Value ?? 0
            let used = total - free
            let ratio = Double(free) / Double(total)

            self.totalStorageSpace = total
            self.usedStorageSpace = used
            self.storageSpace = ratio

            if ratio < 0.1 {
                systemHealthStatus = .warning
                addHealthIssue(type: .storage, severity: .high, message: "Storage space critically low")
            } else if ratio < 0.2 {
                addHealthIssue(type: .storage, severity: .medium, message: "Storage space low")
            }
        } catch {
            print("Failed to read disk space: \(error)")
        }
    }

    private func checkSystemHealth() async {
        if healthIssues.contains(where: { $0.severity == .high }) {
            systemHealthStatus = .critical
        } else if healthIssues.contains(where: { $0.severity == .medium }) {
            systemHealthStatus = .warning
        } else {
            systemHealthStatus = .good
        }
    }

    private func addHealthIssue(type: HealthIssueType, severity: HealthIssueSeverity, message: String) {
        let issue = HealthIssue(type: type, severity: severity, message: message)
        healthIssues.removeAll { $0.type == type }
        healthIssues.append(issue)
        healthIssues.sort {
            if $0.severity == $1.severity {
                return $0.timestamp > $1.timestamp
            }
            return $0.severity.rawValue > $1.severity.rawValue
        }
        if healthIssues.count > 10 {
            healthIssues = Array(healthIssues.prefix(10))
        }
    }
}
