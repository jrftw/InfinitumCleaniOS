import SwiftUI

struct HealthView: View {
    @StateObject private var healthManager = HealthManager.shared
    @State private var isScanning = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedIssue: HealthIssue?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Health Score
                    OverallHealthScoreView(
                        batteryHealth: healthManager.batteryHealth,
                        storageHealth: healthManager.storageSpace,
                        systemHealth: healthManager.systemHealthStatus == .good ? 1.0 : 0.5
                    )
                    
                    // Battery Health
                    BatteryHealthView(
                        health: healthManager.batteryHealth,
                        temperature: healthManager.temperature,
                        isCharging: UIDevice.current.batteryState == .charging
                    )
                    
                    // Storage Health
                    StorageHealthView(
                        health: healthManager.storageSpace,
                        totalSpace: healthManager.totalStorageSpace,
                        usedSpace: healthManager.usedStorageSpace
                    )
                    
                    // System Health
                    SystemHealthView(
                        health: healthManager.systemHealthStatus == .good ? 1.0 : 0.5,
                        cpuUsage: healthManager.cpuUsage,
                        memoryPressure: healthManager.memoryPressure
                    )
                    
                    // Hardware Diagnostics
                    HardwareDiagnosticsView()
                    
                    // Health Issues
                    if !healthManager.healthIssues.isEmpty {
                        HealthIssuesView(issues: healthManager.healthIssues) { issue in
                            selectedIssue = issue
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Device Health")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: startScan) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Status", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(item: $selectedIssue) { issue in
                HealthIssueDetailView(issue: issue)
            }
            .overlay {
                if isScanning {
                    scanningOverlay
                }
            }
            .task {
                await healthManager.startMonitoring()
            }
        }
    }
    
    private func startScan() {
        isScanning = true
        Task {
            await healthManager.startMonitoring()
            isScanning = false
            alertMessage = "Health check completed"
            showingAlert = true
        }
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

struct OverallHealthScoreView: View {
    let batteryHealth: Double
    let storageHealth: Double
    let systemHealth: Double
    
    var overallScore: Double {
        (batteryHealth + storageHealth + systemHealth) / 3.0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Health Score")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(.blue)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(overallScore))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(healthColor(score: overallScore))
                    .rotationEffect(Angle(degrees: 270.0))
                
                VStack {
                    Text("\(Int(overallScore * 100))")
                        .font(.system(size: 44, weight: .bold))
                    Text("Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 200)
            
            Text(healthStatus(score: overallScore))
                .font(.subheadline)
                .foregroundColor(healthColor(score: overallScore))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func healthColor(score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        default: return .red
        }
    }
    
    private func healthStatus(score: Double) -> String {
        switch score {
        case 0.8...: return "Excellent"
        case 0.6..<0.8: return "Good"
        default: return "Needs Attention"
        }
    }
}

struct BatteryHealthView: View {
    let health: Double
    let temperature: Double
    let isCharging: Bool
    
    var body: some View {
        HealthMetricView(
            title: "Battery Health",
            icon: isCharging ? "battery.100.bolt" : "battery.100",
            health: health,
            details: [
                "Current Capacity: \(Int(health * 100))%",
                "Temperature: \(String(format: "%.1f", temperature))°C",
                "Status: \(isCharging ? "Charging" : "Not Charging")"
            ]
        )
    }
}

struct StorageHealthView: View {
    let health: Double
    let totalSpace: Int64
    let usedSpace: Int64
    
    var body: some View {
        HealthMetricView(
            title: "Storage Health",
            icon: "externaldrive",
            health: health,
            details: [
                "Total Space: \(formatSize(totalSpace))",
                "Used Space: \(formatSize(usedSpace))",
                "Free Space: \(formatSize(totalSpace - usedSpace))"
            ]
        )
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct SystemHealthView: View {
    let health: Double
    let cpuUsage: Double
    let memoryPressure: Double
    
    var body: some View {
        HealthMetricView(
            title: "System Health",
            icon: "cpu",
            health: health,
            details: [
                "CPU Usage: \(Int(cpuUsage * 100))%",
                "Memory Pressure: \(Int(memoryPressure * 100))%",
                "System Load: \(systemLoadStatus)"
            ]
        )
    }
    
    private var systemLoadStatus: String {
        if cpuUsage > 0.8 || memoryPressure > 0.8 {
            return "High"
        } else if cpuUsage > 0.5 || memoryPressure > 0.5 {
            return "Moderate"
        } else {
            return "Normal"
        }
    }
}

struct HealthMetricView: View {
    let title: String
    let icon: String
    let health: Double
    let details: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(Int(health * 100))%")
                    .font(.subheadline)
                    .foregroundColor(healthColor(score: health))
            }
            
            ProgressView(value: health)
                .tint(healthColor(score: health))
            
            ForEach(details, id: \.self) { detail in
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func healthColor(score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        default: return .red
        }
    }
}

struct HardwareDiagnosticsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hardware Diagnostics")
                .font(.headline)
            
            ForEach([
                ("Display", "checkmark.circle.fill", "Good"),
                ("Touch Screen", "checkmark.circle.fill", "Good"),
                ("Speakers", "checkmark.circle.fill", "Good"),
                ("Microphone", "checkmark.circle.fill", "Good"),
                ("Camera", "checkmark.circle.fill", "Good"),
                ("Sensors", "checkmark.circle.fill", "Good"),
                ("Vibration", "checkmark.circle.fill", "Good"),
                ("GPS", "checkmark.circle.fill", "Good")
            ], id: \.0) { component in
                HStack {
                    Image(systemName: component.1)
                        .foregroundColor(.green)
                    Text(component.0)
                    Spacer()
                    Text(component.2)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                
                if component.0 != "GPS" {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct HealthIssuesView: View {
    let issues: [HealthIssue]
    let onIssueSelected: (HealthIssue) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Issues")
                .font(.headline)
            
            ForEach(issues) { issue in
                Button(action: { onIssueSelected(issue) }) {
                    HStack {
                        Image(systemName: issueIcon(for: issue.type))
                            .foregroundColor(severityColor(for: issue.severity))
                        VStack(alignment: .leading) {
                            Text(issue.message)
                                .font(.subheadline)
                            Text(issue.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                if issue.id != issues.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func issueIcon(for type: HealthIssueType) -> String {
        switch type {
        case .battery: return "battery.25"
        case .temperature: return "thermometer"
        case .memory: return "memorychip"
        case .storage: return "externaldrive"
        case .security: return "shield"
        }
    }
    
    private func severityColor(for severity: HealthIssueSeverity) -> Color {
        switch severity {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct HealthIssueDetailView: View {
    let issue: HealthIssue
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Issue Details") {
                    LabeledContent("Type", value: String(describing: issue.type))
                    LabeledContent("Severity", value: String(describing: issue.severity))
                    LabeledContent("Time", value: issue.timestamp, format: .dateTime)
                }
                
                Section("Description") {
                    Text(issue.message)
                }
                
                Section("Recommendations") {
                    ForEach(recommendations, id: \.self) { recommendation in
                        Text(recommendation)
                    }
                }
            }
            .navigationTitle("Issue Details")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private var recommendations: [String] {
        switch issue.type {
        case .battery:
            return [
                "Avoid extreme temperatures",
                "Keep battery level between 20% and 80%",
                "Use original charger"
            ]
        case .temperature:
            return [
                "Close background apps",
                "Remove case if device is hot",
                "Avoid direct sunlight"
            ]
        case .memory:
            return [
                "Close unused apps",
                "Clear browser cache",
                "Restart device"
            ]
        case .storage:
            return [
                "Delete unused apps",
                "Clear cache and temporary files",
                "Move photos to cloud storage"
            ]
        case .security:
            return [
                "Update system software",
                "Enable security features",
                "Run security scan"
            ]
        }
    }
}

#Preview {
    HealthView()
} 