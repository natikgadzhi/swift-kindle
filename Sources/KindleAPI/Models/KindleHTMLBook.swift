//
//  KindleHTMLBook.swift
//  Scrapes
//
//  Created by Natik Gadzhi on 12/15/24.
//

import Foundation
import SwiftSoup

/// A struct that parses out books from Kindle HTML Notebook markup
///
public struct KindleHTMLBook {

    public let asin: String
    public let title: String
    public let author: String
    public let modifiedAt: Date

    /// TODO: Process this to be high quality image.
    ///
    public let coverImageURL: URL

    /// Make a new `Book` from a `SwiftSoup.Element` and return it.
    public init(from markup: SwiftSoup.Element) throws {

        let id = markup.id()
        self.asin = id

        let kindleTitle = try markup.select("h2").first()?.text()
        guard let kindleTitle = kindleTitle else {
            throw KindleError.htmlDecodingError(nil)
        }

        self.title = kindleTitle

        let authorString = try markup.select("p.kp-notebook-searchable").first()?.text()
        guard let authorString = authorString else {
            throw KindleError.htmlDecodingError(nil)
        }

        if authorString.starts(with: "By: ") {
            self.author = String(authorString.split(separator: "By: ").last!)
        } else {
            self.author = authorString
        }


        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEEE MMM d, yyyy"

        let modifiedAtString = try markup.select("#kp-notebook-annotated-date-\(id)").val()
        let modifiedAt = dateFormatter.date(from: modifiedAtString)
        guard let modifiedAt = modifiedAt else {
            throw KindleError.htmlDecodingError(nil)
        }
        self.modifiedAt = modifiedAt

        guard let imgElement = try markup.select("img.kp-notebook-cover-image").first(),
              let coverImageURL = URL(string: try imgElement.attr("src")) else {
            throw KindleError.htmlDecodingError(nil)
        }
        self.coverImageURL = coverImageURL
    }
}
