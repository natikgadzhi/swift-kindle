import Foundation

/// Describes all required cookie fields that the application should grab from the login webview
/// to use in ``KindleSessionSecrets`` later.
///
public enum KindleCookies: String, CaseIterable, Sendable {
    case ubidMain = "ubid-main"
    case atMain = "at-main"
    case xMain = "x-main"
    case sessionId = "session-id"

    // Required for Kindle Notebook HTML pages, i.e. highlights
    // This is a short-lived cookie that we'll need to refresh periodically when it craps out.
    case sessionToken = "session-token"
}

/// Describes Kindle and Amazon request header names that are important to set on Kindle API requests
///
public enum KindleRequestHeaders: String, CaseIterable, Sendable {
    case sessionId = "x-amzn-sessionid"
    case adpSessionId = "x-adp-session-token"
}

/// Represends Kindle device information as returned from  ``KindleEndpoint.deviceInfo``
///
public struct KindleDeviceInfo: Codable, Sendable {
    public let clientHashId: String
    public let deviceName: String
    public let deviceSessionToken: String
    public let eid: String
}

/// Describes the persisted Kindle auth material shared between the app and `KindleAPI`.
/// It's used to serialize the secrets to and from ``SecureStorage``.
///
/// The app-layer ``KindleAuthenticationManager`` hydrates these into a
/// ``HydratedKindleAuthenticationSession`` after recovering device metadata.
///
/// TODO: This should be a Codable struct, not a class, and the way we save it into Keychain in Scrapes
/// should not dictate the public API.
///
public final class KindleAuthenticationSecrets: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
    public static let supportsSecureCoding = true

    public let cookies: [HTTPCookie]
    public let deviceToken: String

    public func encode(with coder: NSCoder) {
        coder.encode(cookies, forKey: "cookies")
        coder.encode(deviceToken, forKey: "deviceToken")
    }

    public init(cookies: [HTTPCookie], deviceToken: String) {
        self.cookies = cookies
        self.deviceToken = deviceToken
    }

    public required init?(coder: NSCoder) {
        guard
            let cookies = coder.decodeObject(
                of: [NSArray.self, HTTPCookie.self], forKey: "cookies")
                as? [HTTPCookie],
            let deviceToken = coder.decodeObject(of: NSString.self, forKey: "deviceToken")
                as? String
        else {
            return nil
        }

        self.cookies = cookies
        self.deviceToken = deviceToken
    }
}

/// Hydrated Kindle session that provides everything `KindleAPI` needs to perform authenticated requests.
///
public struct HydratedKindleAuthenticationSession: Sendable {
    public let secrets: KindleAuthenticationSecrets
    public let device: KindleDeviceInfo

    public let sessionId: String

    public var adpSessionId: String {
        device.deviceSessionToken
    }

    public var cookies: [HTTPCookie] {
        secrets.cookies
    }

    public init(secrets: KindleAuthenticationSecrets, device: KindleDeviceInfo, sessionId: String) {
        self.secrets = secrets
        self.device = device
        self.sessionId = sessionId
    }
}
