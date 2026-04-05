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
public struct KindleHTMLBook: Sendable {

    public let asin: String
    public let title: String
    public let author: String
    public let modifiedAt: Date

    /// TODO: Process this to be high quality image.
    ///
    public let coverImageURL: URL

    /// Make a new `Book` from a `SwiftSoup.Element` and return it.
    ///
    /// ## Expected element structure (as of late 2024)
    ///
    /// ```html
    /// <div id="<ASIN>" class="kp-notebook-library-each-book ...">
    ///   <img class="kp-notebook-cover-image" src="https://..."/>
    ///   <h2>Book Title</h2>                      <!-- or <h2 class="kp-notebook-searchable"> -->
    ///   <p class="kp-notebook-searchable">By: Author Name</p>
    ///   <input id="kp-notebook-annotated-date-<ASIN>" type="hidden" value="Wednesday Jan 1, 2025"/>
    /// </div>
    /// ```
    ///
    public init(from markup: SwiftSoup.Element) throws {

        let id = markup.id()
        guard !id.isEmpty else {
            throw Self.parseFailure("book container is missing its ASIN id")
        }
        self.asin = id

        // Try both the plain h2 and the class-qualified variant for robustness.
        // Amazon has used both `<h2>` and `<h2 class="kp-notebook-searchable">` in different page versions.
        let kindleTitle = try markup.select("h2.kp-notebook-searchable").first()?.text()
            ?? markup.select("h2").first()?.text()
        guard let kindleTitle = kindleTitle else {
            throw Self.parseFailure("missing title for ASIN \(id)")
        }

        self.title = kindleTitle

        let authorString = try markup.select("p.kp-notebook-searchable").first()?.text()
        guard let authorString = authorString else {
            throw Self.parseFailure("missing author for ASIN \(id)")
        }

        if authorString.starts(with: "By: ") {
            self.author = String(authorString.dropFirst("By: ".count))
        } else {
            self.author = authorString
        }

        let modifiedAtElement = try markup.select("#kp-notebook-annotated-date-\(id)").first()
        guard let modifiedAtElement = modifiedAtElement else {
            throw Self.parseFailure("missing annotated date input for ASIN \(id)")
        }

        let modifiedAtString = try modifiedAtElement.attr("value")
        let modifiedAt = Self.parseNotebookDate(modifiedAtString)
        guard let modifiedAt = modifiedAt else {
            throw Self.parseFailure(
                "could not parse annotated date '\(modifiedAtString)' for ASIN \(id)")
        }
        self.modifiedAt = modifiedAt

        guard let imgElement = try markup.select("img.kp-notebook-cover-image").first(),
              let coverImageURL = URL(string: try imgElement.attr("src")) else {
            throw Self.parseFailure("missing or invalid cover image URL for ASIN \(id)")
        }
        self.coverImageURL = coverImageURL
    }

    private static func parseFailure(_ description: String) -> KindleError {
        KindleError.htmlDecodingError(
            NSError(domain: "KindleHTMLBook", code: 1, userInfo: [
                NSLocalizedDescriptionKey: description
            ])
        )
    }

    private static func parseNotebookDate(_ rawValue: String) -> Date? {
        let cleaned = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // Amazon has used multiple notebook date variants over time.
        for format in [
            "EEEE, MMMM d, yyyy",
            "EEEE, MMM d, yyyy",
            "EEEE MMMM d, yyyy",
            "EEEE MMM d, yyyy"
        ] {
            formatter.dateFormat = format
            if let date = formatter.date(from: cleaned) {
                return date
            }
        }

        return nil
    }
}
