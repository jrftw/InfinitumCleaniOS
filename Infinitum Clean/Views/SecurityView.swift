import SwiftUI
import CallKit
import Contacts

struct SecurityView: View {
    @StateObject private var callProtection = CallProtectionManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isScanning = false
    @State private var showingBlockNumberSheet = false
    @State private var showingSpamReportSheet = false
    @State private var showingCallHistorySheet = false
    @State private var newBlockedNumber = ""
    @State private var newSpamNumber = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        securityStatusCard
                        actionButtons
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Security")
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
            .sheet(isPresented: $showingBlockNumberSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Block Number")) {
                            TextField("Enter phone number", text: $newBlockedNumber)
                                .keyboardType(.phonePad)
                        }
                        
                        Section {
                            Button("Block Number") {
                                Task {
                                    do {
                                        try await callProtection.blockNumber(newBlockedNumber)
                                        alertMessage = "Number blocked successfully"
                                        showingAlert = true
                                        showingBlockNumberSheet = false
                                        newBlockedNumber = ""
                                    } catch {
                                        alertMessage = "Failed to block number: \(error.localizedDescription)"
                                        showingAlert = true
                                    }
                                }
                            }
                            .disabled(newBlockedNumber.isEmpty)
                        }
                    }
                    .navigationTitle("Block Number")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingBlockNumberSheet = false
                    })
                }
            }
            .sheet(isPresented: $showingSpamReportSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Report Spam")) {
                            TextField("Enter phone number", text: $newSpamNumber)
                                .keyboardType(.phonePad)
                        }
                        
                        Section {
                            Button("Report as Spam") {
                                Task {
                                    do {
                                        try await callProtection.markAsSpam(newSpamNumber)
                                        alertMessage = "Number reported as spam"
                                        showingAlert = true
                                        showingSpamReportSheet = false
                                        newSpamNumber = ""
                                    } catch {
                                        alertMessage = "Failed to report spam: \(error.localizedDescription)"
                                        showingAlert = true
                                    }
                                }
                            }
                            .disabled(newSpamNumber.isEmpty)
                        }
                    }
                    .navigationTitle("Report Spam")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingSpamReportSheet = false
                    })
                }
            }
            .sheet(isPresented: $showingCallHistorySheet) {
                NavigationView {
                    List {
                        ForEach(callProtection.recentCalls) { call in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(call.phoneNumber)
                                        .font(.headline)
                                    Spacer()
                                    Text(call.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text(call.type.rawValue.capitalized)
                                        .font(.subheadline)
                                        .foregroundColor(call.type == .blocked ? .red : .primary)
                                    
                                    Spacer()
                                    
                                    Text(call.status.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(statusColor(call.status))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .navigationTitle("Call History")
                    .navigationBarItems(trailing: Button("Done") {
                        showingCallHistorySheet = false
                    })
                }
            }
        }
        .debugView("SecurityView")
        .logViewAppear("SecurityView appeared", category: .ui)
    }
    
    private var securityStatusCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 15) {
                Text("Security Status")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
                
                SecurityMetricRow(
                    title: "Call Protection",
                    value: callProtection.isProtectionEnabled ? "Enabled" : "Disabled",
                    icon: "phone.down.fill",
                    status: callProtection.isProtectionEnabled ? .enabled : .disabled
                )
                
                SecurityMetricRow(
                    title: "Blocked Numbers",
                    value: "\(callProtection.blockedNumbers.count)",
                    icon: "person.crop.circle.badge.xmark",
                    status: .enabled
                )
                
                SecurityMetricRow(
                    title: "Spam Numbers",
                    value: "\(callProtection.spamNumbers.count)",
                    icon: "exclamationmark.shield.fill",
                    status: .warning
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 15) {
            ActionButton(
                title: callProtection.isProtectionEnabled ? "Disable Call Protection" : "Enable Call Protection",
                icon: "phone.down.fill",
                color: Theme.primary
            ) {
                AppLogger.shared.info("Toggling call protection", category: .security)
                Task {
                    if callProtection.isProtectionEnabled {
                        callProtection.disableCallProtection()
                    } else {
                        try? await callProtection.enableCallProtection()
                    }
                    alertMessage = "Call protection \(callProtection.isProtectionEnabled ? "enabled" : "disabled")"
                    showingAlert = true
                }
            }
            
            ActionButton(
                title: "Block Number",
                icon: "person.crop.circle.badge.xmark",
                color: Theme.secondary
            ) {
                AppLogger.shared.info("Opening block number interface", category: .security)
                showingBlockNumberSheet = true
            }
            
            ActionButton(
                title: "Report Spam",
                icon: "exclamationmark.shield.fill",
                color: Theme.primary
            ) {
                AppLogger.shared.info("Opening spam report interface", category: .security)
                showingSpamReportSheet = true
            }
            
            ActionButton(
                title: "Call History",
                icon: "clock.fill",
                color: Theme.secondary
            ) {
                AppLogger.shared.info("Opening call history", category: .security)
                showingCallHistorySheet = true
            }
        }
        .padding(.horizontal)
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
    
    private func statusColor(_ status: CallProtectionManager.CallRecord.CallStatus) -> Color {
        switch status {
        case .completed:
            return .green
        case .failed:
            return .red
        case .blocked:
            return .orange
        case .spam:
            return .red
        }
    }
}

struct SecurityMetricRow: View {
    let title: String
    let value: String
    let icon: String
    let status: SecurityStatus
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(status.color)
            Text(title)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(status.color)
                .fontWeight(.medium)
        }
    }
}

enum SecurityStatus {
    case enabled
    case disabled
    case warning
    
    var color: Color {
        switch self {
        case .enabled:
            return Theme.primary
        case .disabled:
            return Theme.secondary
        case .warning:
            return Theme.destructive
        }
    }
}

#Preview {
    SecurityView()
} 
