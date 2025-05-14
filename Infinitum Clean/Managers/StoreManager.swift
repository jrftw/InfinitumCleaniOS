import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var premiumFeatures: [Product] = []
    @Published private(set) var purchasedPremiumFeatures: [Product] = []
    
    private let productIds = [
        Constants.StoreKit.monthlySubscriptionID,
        Constants.StoreKit.yearlySubscriptionID,
        Constants.StoreKit.premiumFeaturesID
    ]
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                await self.handleTransactionResult(result)
            }
        }
    }
    
    private func handleTransactionResult(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = result else {
            return
        }
        
        await transaction.finish()
        await self.updatePurchasedProducts()
    }
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: productIds)
            
            subscriptions = products.filter { $0.type == .autoRenewable }
            premiumFeatures = products.filter { $0.type == .nonConsumable }
            
            AppLogger.shared.info("Loaded \(subscriptions.count) subscriptions and \(premiumFeatures.count) premium features", category: .app)
        } catch {
            AppLogger.shared.error("Failed to load products: \(error.localizedDescription)", category: .app)
        }
    }
    
    func updatePurchasedProducts() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                purchasedSubscriptions.append(subscription)
            }
            
            if let feature = premiumFeatures.first(where: { $0.id == transaction.productID }) {
                purchasedPremiumFeatures.append(feature)
            }
        }
        
        AppLogger.shared.info("Updated purchased products: \(purchasedSubscriptions.count) subscriptions, \(purchasedPremiumFeatures.count) features", category: .app)
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                return nil
            }
            
            AppLogger.shared.info("Successfully purchased product: \(product.id)", category: .app)
            await updatePurchasedProducts()
            return transaction
            
        case .userCancelled:
            AppLogger.shared.info("User cancelled purchase of product: \(product.id)", category: .app)
            return nil
            
        case .pending:
            AppLogger.shared.info("Purchase pending for product: \(product.id)", category: .app)
            return nil
            
        @unknown default:
            AppLogger.shared.warning("Unknown purchase result for product: \(product.id)", category: .app)
            return nil
        }
    }
    
    func isSubscribed() async -> Bool {
        return !purchasedSubscriptions.isEmpty
    }
    
    func hasPremiumFeatures() async -> Bool {
        return !purchasedPremiumFeatures.isEmpty
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
        AppLogger.shared.info("Restored purchases", category: .app)
    }
} 