import SwiftUI
import StoreKit

struct PremiumView: View {
    @StateObject private var storeManager = StoreManager.shared
    @State private var selectedSubscription: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    PremiumHeaderView()
                    
                    // Subscription Plans
                    SubscriptionPlansView(
                        subscriptions: storeManager.subscriptions,
                        selectedSubscription: $selectedSubscription
                    )
                    
                    // Premium Features
                    PremiumFeaturesView()
                    
                    // Purchase Button
                    PurchaseButton(
                        isPurchasing: $isPurchasing,
                        selectedSubscription: selectedSubscription,
                        onPurchase: purchase
                    )
                    
                    // Restore Purchases
                    Button("Restore Purchases") {
                        Task {
                            await restorePurchases()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding()
            }
            .navigationTitle("Premium")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func purchase() {
        guard let subscription = selectedSubscription else { return }
        
        isPurchasing = true
        
        Task {
            do {
                if let transaction = try await storeManager.purchase(subscription) {
                    await transaction.finish()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            
            isPurchasing = false
        }
    }
    
    private func restorePurchases() async {
        do {
            try await storeManager.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct PremiumHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Upgrade to Premium")
                .font(.title)
                .bold()
            
            Text("Get access to all premium features and remove ads")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SubscriptionPlansView: View {
    let subscriptions: [Product]
    @Binding var selectedSubscription: Product?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Your Plan")
                .font(.headline)
            
            ForEach(subscriptions, id: \.id) { subscription in
                SubscriptionPlanCard(
                    subscription: subscription,
                    isSelected: selectedSubscription?.id == subscription.id,
                    onSelect: { selectedSubscription = subscription }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SubscriptionPlanCard: View {
    let subscription: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(subscription.displayName)
                        .font(.headline)
                    Text(subscription.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(subscription.displayPrice)
                    .font(.title3)
                    .bold()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PremiumFeaturesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium Features")
                .font(.headline)
            
            ForEach([
                ("Advanced Virus Protection", "shield.checkered.fill"),
                ("Real-time Call Protection", "phone.down.fill"),
                ("Cloud Backup", "icloud.fill"),
                ("Priority Support", "star.fill"),
                ("No Ads", "xmark.circle.fill")
            ], id: \.0) { feature in
                HStack {
                    Image(systemName: feature.1)
                        .foregroundColor(.blue)
                    Text(feature.0)
                    Spacer()
                }
                .padding(.vertical, 8)
                
                if feature.0 != "No Ads" {
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

struct PurchaseButton: View {
    @Binding var isPurchasing: Bool
    let selectedSubscription: Product?
    let onPurchase: () -> Void
    
    var body: some View {
        Button(action: onPurchase) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(selectedSubscription == nil ? "Select a Plan" : "Subscribe Now")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedSubscription == nil ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(selectedSubscription == nil || isPurchasing)
    }
}

struct PremiumView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumView()
    }
} 