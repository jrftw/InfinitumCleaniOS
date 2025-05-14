import SwiftUI
import GoogleMobileAds

struct AdView: View {
    let adUnitID: String
    @Binding var showAds: Bool
    @State private var adError: Error?
    @State private var showError = false

    var body: some View {
        if showAds {
            BannerAdView(adUnitID: adUnitID, onError: { error in
                adError = error
                showError = true
            })
            .frame(height: 50)
            .alert("Ad Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(adError?.localizedDescription ?? "Unknown error")
            }
        }
    }
}

struct BannerAdView: UIViewControllerRepresentable {
    let adUnitID: String
    let onError: (Error) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let banner = BannerView(adSize: AdSizeBanner)
        let viewController = UIViewController()
        banner.adUnitID = adUnitID
        banner.rootViewController = viewController
        banner.delegate = context.coordinator
        viewController.view.addSubview(banner)
        viewController.view.frame = CGRect(origin: .zero, size: AdSizeBanner.size)

        banner.load(Request())

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onError: onError)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        let onError: (Error) -> Void

        init(onError: @escaping (Error) -> Void) {
            self.onError = onError
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            onError(error)
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("Banner ad loaded successfully")
        }
    }
}

struct InterstitialAdView: UIViewControllerRepresentable {
    let adUnitID: String
    @Binding var showAd: Bool
    @State private var interstitial: InterstitialAd?
    @State private var adError: Error?
    @State private var showError = false

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        if showAd {
            loadInterstitial(from: viewController)
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if showAd, let interstitial = interstitial {
            interstitial.present(from: uiViewController)
        }
    }

    private func loadInterstitial(from viewController: UIViewController) {
        InterstitialAd.load(
            with: adUnitID,
            request: Request()
        ) { ad, error in
            if let error = error {
                adError = error
                showError = true
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                return
            }

            interstitial = ad
            print("Interstitial ad loaded successfully")
        }
    }
}

struct RewardedAdView: UIViewControllerRepresentable {
    let adUnitID: String
    @Binding var showAd: Bool
    let onReward: (Int) -> Void
    @State private var rewardedAd: RewardedAd?
    @State private var adError: Error?
    @State private var showError = false

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        if showAd {
            loadRewardedAd(from: viewController)
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if showAd, let rewardedAd = rewardedAd {
            rewardedAd.present(from: uiViewController) {
                onReward(1)
                print("User earned reward")
            }
        }
    }

    private func loadRewardedAd(from viewController: UIViewController) {
        RewardedAd.load(
            with: adUnitID,
            request: Request()
        ) { ad, error in
            if let error = error {
                adError = error
                showError = true
                print("Failed to load rewarded ad: \(error.localizedDescription)")
                return
            }

            rewardedAd = ad
            print("Rewarded ad loaded successfully")
        }
    }
}

// MARK: - Replace With Your AdMob Unit IDs
enum AdUnitIDs {
    static let banner = "ca-app-pub-xxxxxxxxxxxxxxxx/BANNER_ID"
    static let interstitial = "ca-app-pub-xxxxxxxxxxxxxxxx/INTERSTITIAL_ID"
    static let rewarded = "ca-app-pub-xxxxxxxxxxxxxxxx/REWARDED_ID"
}
