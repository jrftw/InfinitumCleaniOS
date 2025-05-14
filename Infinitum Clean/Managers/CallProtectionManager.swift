import Foundation
import CallKit
import Contacts

class CallProtectionManager: ObservableObject {
    static let shared = CallProtectionManager()
    
    @Published var isProtectionEnabled = false
    @Published var blockedNumbers: Set<String> = []
    @Published var spamNumbers: Set<String> = []
    @Published var recentCalls: [CallRecord] = []
    @Published var protectionStatus: ProtectionStatus = .inactive
    
    private let contactsStore = CNContactStore()
    
    enum ProtectionStatus {
        case active
        case inactive
        case blocked
        case error
    }
    
    struct CallRecord: Identifiable, Codable {
        var id: UUID
        let phoneNumber: String
        let timestamp: Date
        let type: CallType
        let status: CallStatus
        
        init(id: UUID = UUID(), phoneNumber: String, timestamp: Date, type: CallType, status: CallStatus) {
            self.id = id
            self.phoneNumber = phoneNumber
            self.timestamp = timestamp
            self.type = type
            self.status = status
        }
        
        enum CallType: String, Codable {
            case incoming
            case outgoing
            case missed
            case blocked
        }
        
        enum CallStatus: String, Codable {
            case completed
            case failed
            case blocked
            case spam
        }
    }
    
    // MARK: - Call Protection
    
    func enableCallProtection() async throws {
        // Request contacts access
        try await requestContactsAccess()
        
        // Load blocked numbers
        try await loadBlockedNumbers()
        
        // Load spam numbers
        try await loadSpamNumbers()
        
        // Update call directory
        try await updateCallDirectory()
        
        // Update published properties on main thread
        await MainActor.run {
            isProtectionEnabled = true
            protectionStatus = .active
        }
    }
    
    func disableCallProtection() {
        Task { @MainActor in
            isProtectionEnabled = false
            protectionStatus = .inactive
        }
    }
    
    // MARK: - Number Management
    
    func blockNumber(_ number: String) async throws {
        blockedNumbers.insert(number)
        try await updateCallDirectory()
        try await saveBlockedNumbers()
    }
    
    func unblockNumber(_ number: String) async throws {
        blockedNumbers.remove(number)
        try await updateCallDirectory()
        try await saveBlockedNumbers()
    }
    
    func markAsSpam(_ number: String) async throws {
        await MainActor.run {
            spamNumbers.insert(number)
        }
        try await saveSpamNumbers()
    }
    
    func removeFromSpam(_ number: String) async throws {
        await MainActor.run {
            spamNumbers.remove(number)
        }
        try await saveSpamNumbers()
    }
    
    // MARK: - Call Directory
    
    private func updateCallDirectory() async {
        do {
            try await CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.infinitumclean.CallDirectoryHandler")
        } catch {
            print("Error updating call directory: \(error)")
        }
    }
    
    // MARK: - Contacts Access
    
    func requestContactsAccess() async -> Bool {
        let store = CNContactStore()
        do {
            let status = try await store.requestAccess(for: .contacts)
            return status
        } catch {
            print("Error requesting contacts access: \(error)")
            return false
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadBlockedNumbers() async throws {
        if let data = UserDefaults.standard.data(forKey: "blockedNumbers"),
           let numbers = try? JSONDecoder().decode(Set<String>.self, from: data) {
            await MainActor.run {
                blockedNumbers = numbers
            }
        }
    }
    
    private func saveBlockedNumbers() async throws {
        if let data = try? JSONEncoder().encode(blockedNumbers) {
            UserDefaults.standard.set(data, forKey: "blockedNumbers")
        }
    }
    
    private func loadSpamNumbers() async throws {
        if let data = UserDefaults.standard.data(forKey: "spamNumbers"),
           let numbers = try? JSONDecoder().decode(Set<String>.self, from: data) {
            await MainActor.run {
                spamNumbers = numbers
            }
        }
    }
    
    private func saveSpamNumbers() async throws {
        if let data = try? JSONEncoder().encode(spamNumbers) {
            UserDefaults.standard.set(data, forKey: "spamNumbers")
        }
    }
    
    // MARK: - Call Monitoring
    
    func addCallRecord(_ record: CallRecord) {
        Task { @MainActor in
            recentCalls.insert(record, at: 0)
            
            // Keep only last 100 calls
            if recentCalls.count > 100 {
                recentCalls.removeLast()
            }
            
            // Save to persistent storage
            saveCallRecords()
        }
    }
    
    private func saveCallRecords() {
        if let data = try? JSONEncoder().encode(recentCalls) {
            UserDefaults.standard.set(data, forKey: "recentCalls")
        }
    }
    
    func loadCallRecords() {
        if let data = UserDefaults.standard.data(forKey: "recentCalls"),
           let records = try? JSONDecoder().decode([CallRecord].self, from: data) {
            Task { @MainActor in
                recentCalls = records
            }
        }
    }
    
    // MARK: - Spam Detection
    
    func isSpamNumber(_ number: String) async throws -> Bool {
        // Check local spam list
        if spamNumbers.contains(number) {
            return true
        }
        
        // Check online spam database
        return try await checkOnlineSpamDatabase(number)
    }
    
    private func checkOnlineSpamDatabase(_ number: String) async throws -> Bool {
        // TODO: Implement online spam database check
        // This would typically involve calling an API to check if the number is known for spam
        return false
    }
    
    // MARK: - Call Analysis
    
    func analyzeCallPatterns() async throws -> [String: Any] {
        var patterns: [String: Any] = [:]
        
        // Analyze call frequency
        patterns["callFrequency"] = analyzeCallFrequency()
        
        // Analyze call duration
        patterns["callDuration"] = analyzeCallDuration()
        
        // Analyze call times
        patterns["callTimes"] = analyzeCallTimes()
        
        return patterns
    }
    
    private func analyzeCallFrequency() -> [String: Int] {
        var frequency: [String: Int] = [:]
        
        for call in recentCalls {
            let date = Calendar.current.startOfDay(for: call.timestamp)
            let dateString = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
            frequency[dateString, default: 0] += 1
        }
        
        return frequency
    }
    
    private func analyzeCallDuration() -> [String: TimeInterval] {
        var duration: [String: TimeInterval] = [:]
        
        for call in recentCalls {
            let date = Calendar.current.startOfDay(for: call.timestamp)
            let dateString = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
            // TODO: Add actual call duration calculation
            duration[dateString, default: 0] += 0
        }
        
        return duration
    }
    
    private func analyzeCallTimes() -> [String: Int] {
        var times: [String: Int] = [:]
        
        for call in recentCalls {
            let hour = Calendar.current.component(.hour, from: call.timestamp)
            let hourString = String(format: "%02d:00", hour)
            times[hourString, default: 0] += 1
        }
        
        return times
    }
} 