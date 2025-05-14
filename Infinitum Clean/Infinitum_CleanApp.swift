//
//  Infinitum_CleanApp.swift
//  Infinitum Clean
//
//  Created by Kevin Doyle Jr. on 5/13/25.
//

import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct Infinitum_CleanApp: App {
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var showAds = true

    init() {
        // Initialize Google Mobile Ads
        MobileAds.shared.start { status in
            AppLogger.shared.info("Google Mobile Ads SDK initialized", category: .app)
        }
        
        // Configure app appearance
        configureAppearance()
    }
    
    private func configureAppearance() {
        // Set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView(showAds: $showAds)
                .task {
                    showAds = !(await storeManager.isSubscribed())
                }
                .preferredColorScheme(settings.isAutoMode ? nil : (settings.isDarkMode ? .dark : .light))
        }
    }
}
