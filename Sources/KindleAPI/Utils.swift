
import Foundation
import OSLog

/// Some internal string utilities
///
/// TODO: How can we make sure these don't leak out of the package?
///

internal extension Optional where Wrapped: StringProtocol {
    /// Returns true if the underlying string is not null and not empty.
    ///
    var notEmpty: Bool {
        !(self ?? "").isEmpty
    }
}

/// Strip JSONP function call and return the JSON contents of the string inside.
/// If the string is not a valid JSONP string and does not contain `{}` characters, this will return the string itself.
///
internal func stripJSONP(_ jsonpString: String) -> String {
    guard let start = jsonpString.firstIndex(of: "{"),
        let end = jsonpString.lastIndex(of: "}")
    else {
        return jsonpString
    }

    return String(jsonpString[start...end])
}

// Easier access to specific cookies in the HTTPCookie array
internal extension Array where Element == HTTPCookie {
    /// Returns true if the array contains a cookie with the given name
    func contains(_ cookieName: String) -> Bool {
        contains { $0.name == cookieName }
    }

    /// Returns the value of the cookie with the given name, if it exists
    func cookie(named name: String) -> String? {
        first { $0.name == name }?.value
    }
}
