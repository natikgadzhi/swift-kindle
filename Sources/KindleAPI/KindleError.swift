import Foundation

public enum KindleError: Error, LocalizedError {
    /// The cookies were there, but the API returned 401 or 403
    case unauthenticated

    /// Kindle API returned HTTP 500
    case kindleAPIError

    /// Couldn't parse HTTP response into a string
    case badHTTPResponse

    /// Couldn't decode the response from the Kindle API
    case decodingError(Error)

    /// Couldn't decode HTML from the Kindle API into one of the KindleAPI models
    case htmlDecodingError(Error?)

    case noMetadata

    case kindleHTMLClientError

    case cantFetchAnnotations

    public var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "Couldn't authenticate the request to the Kindle API"
        case .kindleAPIError:
            return "Kindle Cloud Reader internal server error"
        case .badHTTPResponse:
            return "Received invalid HTTP response from Kindle API"
        case .decodingError(let error):
            return "Couldn't decode the response from the Kindle API: \(error)"
        case .noMetadata:
            return "Couldn't load the book metadata from Kindle"
        case .kindleHTMLClientError:
            return
                "Scrapes couldn't retrieve the response from HTML Kindle pages, this is an application bug"
        case .cantFetchAnnotations:
            return "Can't fetch Kindle annotations for this book"
        case .htmlDecodingError(let error):
            if let error {
                return "Couldn't decode HTML from the Kindle API: \(error)"
            } else {
                return "Couldn't decode HTML from the Kindle API"
            }
        }
    }
}
