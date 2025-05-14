import SwiftUI

struct CallProtectionView: View {
    @State private var isProtectionEnabled = true
    @State private var blockedNumbers: [String] = []
    @State private var recentSpamCalls: [SpamCall] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Protection Status
                    ProtectionStatusCard(isEnabled: isProtectionEnabled)
                    
                    // Blocked Numbers
                    BlockedNumbersView(blockedNumbers: blockedNumbers)
                    
                    // Recent Spam Calls
                    RecentSpamCallsView(calls: recentSpamCalls)
                    
                    // Call Screening Settings
                    CallScreeningSettingsView()
                }
                .padding()
            }
            .navigationTitle("Call Protection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isProtectionEnabled.toggle() }) {
                        Image(systemName: isProtectionEnabled ? "shield.fill" : "shield.slash.fill")
                    }
                }
            }
        }
    }
}

struct ProtectionStatusCard: View {
    let isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Call Protection")
                        .font(.headline)
                    Text(isEnabled ? "Active" : "Disabled")
                        .font(.subheadline)
                        .foregroundColor(isEnabled ? .green : .red)
                }
                
                Spacer()
                
                Image(systemName: isEnabled ? "phone.down.fill" : "phone.down.slash.fill")
                    .font(.title)
                    .foregroundColor(isEnabled ? .green : .red)
            }
            
            Text("Protecting you from spam and scam calls")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct BlockedNumbersView: View {
    let blockedNumbers: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Blocked Numbers")
                    .font(.headline)
                Spacer()
                Text("\(blockedNumbers.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if blockedNumbers.isEmpty {
                Text("No numbers blocked")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(blockedNumbers, id: \.self) { number in
                    HStack {
                        Text(number)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if number != blockedNumbers.last {
                        Divider()
                    }
                }
            }
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Number")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SpamCall: Identifiable {
    let id = UUID()
    let number: String
    let date: Date
    let type: String
}

struct RecentSpamCallsView: View {
    let calls: [SpamCall]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Spam Calls")
                .font(.headline)
            
            if calls.isEmpty {
                Text("No recent spam calls")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(calls) { call in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(call.number)
                                .font(.subheadline)
                            Text(call.type)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        Text(call.date, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    if call.id != calls.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CallScreeningSettingsView: View {
    @State private var screenUnknownCallers = true
    @State private var blockSuspiciousNumbers = true
    @State private var notifyOnSpam = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Call Screening Settings")
                .font(.headline)
            
            Toggle("Screen Unknown Callers", isOn: $screenUnknownCallers)
            Toggle("Block Suspicious Numbers", isOn: $blockSuspiciousNumbers)
            Toggle("Notify on Spam", isOn: $notifyOnSpam)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CallProtectionView_Previews: PreviewProvider {
    static var previews: some View {
        CallProtectionView()
    }
} 