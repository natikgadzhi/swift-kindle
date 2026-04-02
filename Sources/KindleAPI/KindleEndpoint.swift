//
//  KindleEndpoint.swift
//
//  Created by Natik Gadzhi on 10/27/24.
//

import Foundation

/// KindleEndpoint represents API endpoints and auth site that are used to grab the data for books and highlights.
///
public struct KindleEndpoint: Sendable {

    let urlString: String

    public var url: URL {
        return URL(string: urlString)!
    }

    /// Represents the Amazon OpenID login page that returns to the Kindle Notebook after sign-in.
    ///
    /// Previously this pointed to `read.amazon.com/kindle-library`, but Amazon discontinued the
    /// Kindle Cloud Reader library page (it now redirects to `/kindle-library/not-supported`).
    /// The login now targets `read.amazon.com/notebook` instead, which is the Kindle Highlights &
    /// Notebook page and remains supported. The `assoc_handle` parameter changed accordingly from
    /// `amzn_kindle_mykindle_us` to `amzn_kindle_ynhv2_us`.
    ///
    public static let login = KindleEndpoint(
        urlString:
            "https://www.amazon.com/ap/signin?openid.pape.max_auth_age=3600&openid.return_to=https%3A%2F%2Fread.amazon.com%2Fnotebook&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.assoc_handle=amzn_kindle_ynhv2_us&openid.mode=checkid_setup&language=en_US&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&pageId=amzn_kindle_ynhv2_us&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0"
    )

    public static func deviceInfo(token: String) -> KindleEndpoint {
        return KindleEndpoint(
            urlString:
                "https://read.amazon.com/service/web/register/getDeviceToken?serialNumber=\(token)&deviceType=\(token)"
        )
    }

    /// The Kindle Notebook & Highlights landing page.
    ///
    /// This is used as the post-login destination and as the trigger page for cookie extraction.
    /// The old `read.amazon.com/kindle-library` URL is discontinued by Amazon (redirects to
    /// `/kindle-library/not-supported`); the notebook page serves the same role.
    ///
    public static let notebook = KindleEndpoint(urlString: "https://read.amazon.com/notebook")

    /// Deprecated. Amazon discontinued `read.amazon.com/kindle-library`.
    /// Use ``notebook`` instead.
    @available(*, deprecated, renamed: "notebook")
    public static let library = KindleEndpoint(urlString: "https://read.amazon.com/notebook")

    /// Fetches book details in JSON format.
    /// Useful to grab metadataURL and YJVersion string
    public static func bookDetailsJSON(asin: String, clientVersion: String = "20000100") -> KindleEndpoint
    {
        return KindleEndpoint(
            urlString:
                "https://read.amazon.com/service/mobile/reader/startReading?asin=\(asin)&clientVersion=\(clientVersion)"
        )
    }

    public static func booksListJSON(paginationToken: String) -> KindleEndpoint {
        if paginationToken.isEmpty {
            return KindleEndpoint(
                urlString:
                    "https://read.amazon.com/kindle-library/search?query=&libraryType=BOOKS&sortType=recency&querySize=50"
            )
        } else {
            return KindleEndpoint(
                urlString:
                    "https://read.amazon.com/kindle-library/search?query=&libraryType=BOOKS&sortType=recency&querySize=50&paginationToken=\(paginationToken)"
            )
        }
    }

    public static func booksListHTML(paginationToken: String?) -> KindleEndpoint {
        if let paginationToken = paginationToken, !paginationToken.isEmpty {
            return KindleEndpoint(
                urlString: "https://read.amazon.com/notebook?library=list&token=\(paginationToken)&"
            )
        } else {
            return KindleEndpoint(
                urlString: "https://read.amazon.com/notebook?ref_=kcr_notebook_lib&language=en-US")
        }
    }

    /// Kindle Reader getAnnotations endpoint that returns shortened annotations in JSON format
    ///
    public static func annotationsListJSON(
        asin: String, refEmId: String, yjFormatVersion: String, clientVersion: String = "20000100"
    ) -> KindleEndpoint {
        return KindleEndpoint(
            urlString:
                "https://read.amazon.com/service/mobile/reader/getAnnotations?asin=\(asin)&guid=\(refEmId),\(yjFormatVersion)&clientVersion=\(clientVersion)"
        )
    }

    /// Kindle Notebook & Highlights endpoint that renders highlights for a given book in HTML format.
    public static func annotationsListHTML(asin: String) -> KindleEndpoint {
        return KindleEndpoint(
            urlString: "https://read.amazon.com/notebook?asin=\(asin)&contentLimitState=&")
    }
}
