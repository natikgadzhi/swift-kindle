import Foundation

/// Protocol defining the logging interface for KindleAPI.
///
/// KindleAPI doesn't log with `OSLog.Logger` by default to ensure you can use the library on any platform.
/// However, we provide the standard protocol for you to implement. You can pass the logger into ``KindleAPI`` when making a new client instance.
///
/// If you're building for an Apple platform, `OSLog.Logger` is the easiest option to go with, and it will work out of the box.
///
public protocol KindleLoggerProtocol {
    func debug(_ message: @autoclosure () -> String)
    func info(_ message: @autoclosure () -> String)
    func error(_ message: @autoclosure () -> String)
}


// On Apple platforms, patch extend the default Logger to work with KindleAPI
//
#if canImport(OSLog)

import OSLog

extension Logger: KindleLoggerProtocol {
    public func debug(_ message: @autoclosure () -> String) {
        let msg = message()
        self.log(level: .debug, "\(msg, privacy: .public)")
    }

    public func info(_ message: @autoclosure () -> String) {
        let msg = message()
        self.log(level: .info, "\(msg, privacy: .public)")
    }

    public func error(_ message: @autoclosure () -> String) {
        let msg = message()
        self.log(level: .error, "\(msg, privacy: .public)")
    }
}

#endif
