import Foundation
import OSLog
import SwiftUI

enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case critical = "🚨 CRITICAL"
}

enum LogCategory: String {
    case app = "App"
    case ui = "UI"
    case network = "Network"
    case security = "Security"
    case cleanup = "Cleanup"
    case health = "Health"
    case performance = "Performance"
    case storage = "Storage"
}

class AppLogger {
    static let shared = AppLogger()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.infinitumclean", category: "App")
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private init() {}
    
    func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(category.rawValue)] [\(fileName):\(line)] \(function): \(message)"
        
        // Console logging
        print(logMessage)
        
        // OSLog logging
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .critical:
            logger.critical("\(logMessage)")
        }
        
        #if DEBUG
        // Additional debug-only logging
        if level == .debug {
            logger.debug("\(logMessage)")
        }
        #endif
    }
    
    // Convenience methods for different log levels
    func debug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
}

// MARK: - View Extensions for Logging
extension View {
    func logViewAppear(_ message: String, category: LogCategory = .ui) -> some View {
        self.onAppear {
            AppLogger.shared.info(message, category: category)
        }
    }
    
    func logViewDisappear(_ message: String, category: LogCategory = .ui) -> some View {
        self.onDisappear {
            AppLogger.shared.info(message, category: category)
        }
    }
}

// MARK: - Debug View Modifier
struct DebugViewModifier: ViewModifier {
    let identifier: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                AppLogger.shared.debug("View appeared: \(identifier)", category: .ui)
            }
            .onDisappear {
                AppLogger.shared.debug("View disappeared: \(identifier)", category: .ui)
            }
    }
}

extension View {
    func debugView(_ identifier: String) -> some View {
        modifier(DebugViewModifier(identifier: identifier))
    }
} 