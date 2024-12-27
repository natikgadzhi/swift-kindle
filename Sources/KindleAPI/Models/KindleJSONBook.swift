//
//  KindleJSONBook.swift
//  Scrapes
//
//  Created by Natik Gadzhi on 12/15/24.
//

import Foundation


/// Represents Kindle Library books list JSON API response
///
public struct KindleLibrarySearchResponse: Decodable {
    public let itemsList: [KindleJSONBook]
    public let paginationToken: String?
    public let libraryType: String
    public let sortType: String
}

/// Represents Kindle book details fetched from `startReading` Kindle API endpoint
///
public struct KindleBookDetails: Codable {
    public let contentVersion: String?
    public let metadataUrl: String?
    public let formatVersion: String?
    public let YJFormatVersion: String?
    public let lastPageReadData: KindleBookLastPageReadData?
}

/// Represents Kindle book last page read data API response
///
public struct KindleBookLastPageReadData: Codable {
    public let position: Int?
    public let syncTime: Date?

    enum CodingKeys: CodingKey {
        case position
        case syncTime
    }
}

/// Represents Kindle book metadata fetched from the `metadata.jsonp` Kindle API call
///
public struct KindleBookMetadata: Codable {
    enum CodingKeys: CodingKey {
        case ACR
        case bookSize
        case publisher
        case releaseDate
        case version
        case startPosition
        case endPosition
        case refEmId
    }

    public let ACR: String
    public let bookSize: String
    public let publisher: String
    public let releaseDate: String
    public let version: String
    public let startPosition: Int
    public let endPosition: Int
    public let refEmId: String
}


/// A struct that parses out books from Kindle JSON API response
///
public struct KindleJSONBook: Decodable {

    /*
     Kindle book JSON:

     {
       "asin": "B084357H23",
       "webReaderUrl": "https://read.amazon.com/?asin=B084357H23",
       "productUrl": "https://m.media-amazon.com/images/I/418brAemxDL._SY400_.jpg",
       "title": "The Invisible Life of Addie LaRue",
       "percentageRead": 0,
       "authors": [
         "Schwab, V. E.:"
       ],
       "resourceType": "EBOOK",
       "originType": "PURCHASE",
       "mangaOrComicAsin": false
     }
     */

    public let asin: String
    public let webReaderURL: URL

    /// TODO: Process this to be high quality image.
    ///
    public let coverImageURL: URL
    public let title: String
    public let authors: [String]
    public let author: String
    public let resourceType: String

    public var details: KindleBookDetails?
    public var metadata: KindleBookMetadata?

    enum CodingKeys: CodingKey {
        case id
        case asin
        case webReaderUrl
        case productUrl
        case title
        case authors
        case resourceType
    }


    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        asin = try container.decode(String.self, forKey: .asin)
        title = try container.decode(String.self, forKey: .title)
        webReaderURL = try URL(string: container.decode(String.self, forKey: .webReaderUrl))!
        coverImageURL = try URL(string: container.decode(String.self, forKey: .productUrl))!
        resourceType = try container.decode(String.self, forKey: .resourceType)
        authors = try container.decode([String].self, forKey: .authors)

        let deduped = Set(authors.first!
            .split(separator: ":")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })

        author = deduped
            .first!
            .split(separator: ",")
            .reversed()
            .joined(separator: " ")
    }
}
