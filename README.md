# Infinitum Clean

A comprehensive iOS app for system optimization, security, and maintenance.

## Features

- **System Health Monitoring**
  - Battery health tracking
  - CPU usage monitoring
  - Memory pressure analysis
  - Storage space optimization
  - Temperature monitoring

- **Security Features**
  - Call protection
  - Spam number blocking
  - Security status monitoring
  - Privacy protection

- **Cleanup Tools**
  - Cache cleaning
  - Temporary file removal
  - Download management
  - Storage optimization

- **Premium Features**
  - Ad-free experience
  - Advanced security features
  - Priority cleanup
  - Real-time monitoring

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- CocoaPods

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/infinitum-clean.git
```

2. Install dependencies:
```bash
cd infinitum-clean
pod install
```

3. Open `Infinitum Clean.xcworkspace` in Xcode

4. Build and run the project

## Configuration

### Google Mobile Ads
1. Create a new project in the Google AdMob console
2. Add your app and get the app ID
3. Replace the placeholder ad unit IDs in the code

### In-App Purchases
1. Configure your products in App Store Connect
2. Update the product identifiers in `StoreManager.swift`

## Privacy

Infinitum Clean requires the following permissions:
- Contacts access for call protection
- Photo library access for storage optimization
- Camera access for security features
- Microphone access for audio security
- Location access for location-based security

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [DeviceKit](https://github.com/devicekit/DeviceKit) for device information
- [Google Mobile Ads SDK](https://developers.google.com/admob/ios/quick-start) for ad integration
- [CallKit](https://developer.apple.com/documentation/callkit) for call protection features 