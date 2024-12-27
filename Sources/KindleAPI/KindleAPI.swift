//
//  KindleAPI.swift
//  ThrowAway
//
//  Created by Natik Gadzhi on 12/24/23.
//

import Foundation
import SwiftSoup

/// KindleAPI is a Kindle web reader API client.
/// It uses Amazon's session tokens to fetch JSON and HTML data from your Kindle books.
///
public struct KindleAPI {

    let secrets: HydratedAuthenticationSession
    let session: URLSession
    let logger: KindleLoggerProtocol?

    /// Initializes a new KindleAPI client.
    /// The client needs a valid set of hydrated secrets to make it's URLSession, and saves the hydrated session as well.
    ///
    public init(
        secrets: HydratedAuthenticationSession, logger: KindleLoggerProtocol? = nil
    ) {
        self.logger = logger
        self.secrets = secrets
        self.session = URLSession(configuration: .ephemeral)

        session.configuration.httpCookieStorage = HTTPCookieStorage()
        for cookie in secrets.cookies {
            session.configuration.httpCookieStorage?.setCookie(cookie)
        }
    }

    /// Prepare the URLRequest to be sent to Kindle servers by adding additional request headers for `x-amzn-sessionid` and `x-adp-session-token`
    ///
    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)

        let sessionId = secrets.secrets.cookies.cookie(named: KindleCookies.sessionId.rawValue)!
        request.setValue(sessionId, forHTTPHeaderField: KindleRequestHeaders.sessionId.rawValue)
        request.setValue(
            secrets.adpSessionId, forHTTPHeaderField: KindleRequestHeaders.adpSessionId.rawValue)
        return request
    }

    private func fetchAndDecode<T>(into: T.Type, request: URLRequest) async throws -> T
    where T: Decodable {
        let (data, _) = try await dataWithHTTPValidation(request: request, maxAttempts: 1)

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw KindleError.decodingError(error)
        }
    }

    /// Fetches the list of books with partial information without fetching additional details or highlights for each specific book
    ///
    public func getBooks() async throws -> [KindleJSONBook] {
        var numberOfBooks: Int = 0
        var books: [KindleJSONBook] = []
        var paginationToken: String? = ""

        while paginationToken != nil {
            let request = makeRequest(
                url: KindleEndpoint.booksListJSON(paginationToken: paginationToken!).url)
            let parsed = try await fetchAndDecode(
                into: KindleLibrarySearchResponse.self, request: request)

            books.append(contentsOf: parsed.itemsList)
            paginationToken = parsed.paginationToken
            numberOfBooks += parsed.itemsList.count
        }

        return books
    }

    /// Retrieves book details and metadata for a given book.
    /// It has to do two HTTP requests to get them.
    ///
    public func getBookMetadata(asin: String) async throws -> (
        KindleBookDetails, KindleBookMetadata
    ) {
        // Start with loading the basic book details
        let request = makeRequest(url: KindleEndpoint.bookDetailsJSON(asin: asin).url)
        let details = try await fetchAndDecode(into: KindleBookDetails.self, request: request)

        guard let metadataURL = details.metadataUrl else {
            throw KindleError.noMetadata
        }

        // Based on book details, we make the second request
        // to `details.metadataUrl`.
        //
        let metadataRequest = makeRequest(url: URL(string: metadataURL)!)
        let (data, _) = try await session.data(for: metadataRequest)
        let stripped = stripJSONP(String(data: data, encoding: .utf8)!).data(using: .utf8)!
        let metadata = try JSONDecoder().decode(KindleBookMetadata.self, from: stripped)

        return (details, metadata)
    }

    /// Retrieves annotations for a given book from Kindle JSON API
    ///
    /// - Parameters:
    ///     - asin: The ASIN of the book
    ///     - refEmId: The refEmId of the book. You can obtain it from ``KindleBookMetadata``.
    ///     - yjFormatVersion: The yjFormatVersion of the book, it's in ``KindleBookDetails``.
    ///
    public func getAnnotations(
        for asin: String, refEmId: String, yjFormatVersion: String
    )
        async throws -> [KindleJSONAnnotation]
    {
        let url = KindleEndpoint.annotationsListJSON(
            asin: asin,
            refEmId: refEmId,
            yjFormatVersion: yjFormatVersion
        ).url

        let request = makeRequest(url: url)
        let parsed = try await fetchAndDecode(
            into: KindleGetAnnotationsResponse.self, request: request)
        return parsed.annotations
    }
}

//
// MARK:- HTML API functions
//

extension KindleAPI {

    /// Request and return the list of ``Book`` from Kindle's HTML Notebook site.
    /// Automatically handles pagination internally and returns when the full list of books is retrieved.
    ///
    public func getHTMLBooks() async throws -> [KindleHTMLBook] {
        var books: [KindleHTMLBook] = []
        var paginationToken: String? = nil

        do {
            repeat {
                let request = makeRequest(
                    url: KindleEndpoint.booksListHTML(paginationToken: paginationToken).url)

                let (data, _) = try await dataWithHTTPValidation(request: request)

                guard let responseHTML = String(data: data, encoding: .utf8) else {
                    throw KindleError.badHTTPResponse
                }

                let (pageBooks, nextPageTokenFromResponse) = try parseBooksMarkup(responseHTML)

                // naming is critical here: out of the loop scoped nextPageToken cannot be reassigned with the let tuple assignment above,
                // so we have to use the temporary variable nextPageTokenFromResponse.
                paginationToken = nextPageTokenFromResponse
                books.append(contentsOf: pageBooks)

            } while paginationToken.notEmpty
        } catch {
            // Throw unauthenticated transparently
            if case KindleError.unauthenticated = error {
                throw error
            }

            logger?.error("Failed to fetch or parse books")
            throw KindleError.htmlDecodingError(error)
        }

        return books
    }

    /// Fetches ``Annotaion`` objects from Kindle HTML Notebook site
    /// Does NOT paginate automatically.
    ///
    public func getHTMLAnnotations(for asin: String) async throws -> [KindleHTMLAnnotation] {
        let url = KindleEndpoint.annotationsListHTML(asin: asin).url
        let request = makeRequest(url: url)

        do {
            let (data, _) = try await dataWithHTTPValidation(request: request)

            guard let responseHTML = String(data: data, encoding: .utf8) else {
                throw KindleError.badHTTPResponse
            }

            return try KindleHTMLAnnotation.parseFromHTML(markup: responseHTML)
        }

        // If we got a general error that we did not throw ourselves (not KindleAPIError),
        // it's most likely in markup parsing because the format changed.
        catch {
            // Throw unauthenticated transparently
            if case KindleError.unauthenticated = error {
                throw error
            }

            logger?.error("Failed to fetch or parse annotations")
            throw KindleError.htmlDecodingError(error)
        }
    }

    /// Parse a string http request response markup into an array of Books and the next page token
    private func parseBooksMarkup(_ responseBody: String) throws -> ([KindleHTMLBook], String?) {
        let page = try SwiftSoup.parse(responseBody)
        let booksMarkup = try page.select(".kp-notebook-library-each-book")
        guard !booksMarkup.isEmpty() else {
            throw KindleError.htmlDecodingError(nil)
        }

        let nextPageToken = try page.select(".kp-notebook-library-next-page-start").first()?.attr(
            "value")
        let books = try booksMarkup.map { try KindleHTMLBook(from: $0) }
        return (books, nextPageToken)
    }

    /// Sends the request and ensures it returned a valid 200...299 HTTP response, throws an error otherwise.
    ///
    /// Returns:
    ///     (``Data``,  ``URLResponse``) — same as ``URLSession.data()``
    ///
    private func dataWithHTTPValidation(request: URLRequest, maxAttempts: UInt = 2) async throws
        -> (data: Data, response: URLResponse)
    {
        var attemptCount = 1

        while attemptCount <= maxAttempts {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw KindleError.badHTTPResponse
            }

            switch httpResponse.statusCode {
            case 401...403:
                throw KindleError.unauthenticated
            case 500...599:
                // Sometimes Kindle HTML pages render HTTP 500, but if you retry right away,
                // they return the data. So, we attempt retrying right away.
                if attemptCount < maxAttempts {
                    logger?.error("Retrying request with \(request.url!) for \(attemptCount) time")
                    attemptCount += 1
                } else {
                    throw KindleError.kindleAPIError
                }
            case 200...299:
                // Amazon is funny — they redirect to the signin page without throwing HTTP 40*
                // We could intercept the redirect, but it's easier to just check the resulting URL instead.
                if let url = httpResponse.url, url.path().starts(with: "/ap/signin") {
                    // Safe to unwrap because if we're here, means we've already successfully navigated to this URL, means it's for sure there.
                    logger?.error(
                        "Request returned HTTP 401, throwing .unauthenticated. URL: \(request.url!)"
                    )
                    throw KindleError.unauthenticated
                }

                return (data, response)
            default:
                throw KindleError.badHTTPResponse
            }
        }

        // We should only end up here if we ran out of retries, but have not returned any data yet
        // and neither thrown any errors. This should never happen. Upstream, we should collect this and die.
        logger?.error(
            "Unexpectedly got out of the while loop with retries without returning or erroring out")
        throw KindleError.kindleHTMLClientError
    }
}
