import Foundation

/// Describes all required cookie fields that the application should grab from the login webview
/// to use in ``KindleSessionSecrets`` later.
///
public enum KindleCookies: String, CaseIterable {
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
public enum KindleRequestHeaders: String, CaseIterable {
    case sessionId = "x-amzn-sessionid"
    case adpSessionId = "x-adp-session-token"
}

/// Represends Kindle device information as returned from  ``KindleEndpoint.deviceInfo``
///
public struct KindleDeviceInfo: Codable {
    public let clientHashId: String
    public let deviceName: String
    public let deviceSessionToken: String
    public let eid: String
}

/// Describes all secrets required to make a working Kindle webview and fetch data from it.
/// It's used to serialize the secrets to and from ``SecureStorage``.
///
/// At runtime, ``AuthenticationManager`` will hydrate these into a ``HydratedAuthenticationSession``
///
/// TODO: This should be a Codable struct, not a class, and the way we save it into Keychain in Scrapes
/// should not dictate the public API.
///
public class AuthenticationSecrets: NSObject, NSCoding, NSSecureCoding {
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

/// Hydrated Kindle sesion that provides everything a webview needs to perform authenticated Kindle requests.
///
public struct HydratedAuthenticationSession {
    public let secrets: AuthenticationSecrets
    public let device: KindleDeviceInfo

    public let sessionId: String

    public var adpSessionId: String {
        device.deviceSessionToken
    }

    public var cookies: [HTTPCookie] {
        secrets.cookies
    }

    public init(secrets: AuthenticationSecrets, device: KindleDeviceInfo, sessionId: String) {
        self.secrets = secrets
        self.device = device
        self.sessionId = sessionId
    }
}
