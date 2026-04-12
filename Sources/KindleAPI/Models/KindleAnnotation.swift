//
//  KindleAnnotation.swift
//  Scrapes
//
//  Created by Natik Gadzhi on 12/19/24.
//

import Foundation
import SwiftSoup

/// Describes possible highlight colors
///
public enum KindleHighlightColor: String, Codable, CaseIterable, Identifiable, Sendable {
  public var id: String { rawValue }

  case yellow, red, blue, green, purple
}

/// Describes Kindle getAnnotations JSON response structure
///
public struct KindleGetAnnotationsResponse: Decodable, Sendable {
  public let annotations: [KindleJSONAnnotation]
}

/// Describes annotation types that Kindle API returns
///
public enum KindleAnnotationType: String, Codable, Sendable {
  case note = "kindle.note"
  case highlight = "kindle.highlight"
  case bookmark = "kindle.bookmark"
}

/// Describes the type of position returned by Kindle API
///
public enum KindleAnnotationPositionType: String, Codable, Sendable {
  case mobi7 = "Mobi7"
}

public struct KindleJSONAnnotation: Decodable, Sendable {

  public let highlightText: String
  public let noteText: String?
  public let highlightColor: KindleHighlightColor
  public let annotationType: KindleAnnotationType
  public let position: Int
  public let start: Int
  public let end: Int

  enum CodingKeys: CodingKey {
    case id
    case highlightText
    case color
    case noteText
    case position
    case start
    case end
    case annotationType
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    highlightText = try container.decode(String.self, forKey: .highlightText)
    position = try container.decode(Int.self, forKey: .position)
    start = try container.decode(Int.self, forKey: .start)
    end = try container.decode(Int.self, forKey: .end)
    noteText = try? container.decode(String.self, forKey: .noteText)
    annotationType = try container.decode(KindleAnnotationType.self, forKey: .annotationType)
    highlightColor = try container.decode(KindleHighlightColor.self, forKey: .color)
  }
}

public struct KindleHTMLAnnotation: Sendable {

  public let kindleHighlightID: String
  public let highlightText: String
  public let noteText: String?
  public let highlightColor: KindleHighlightColor
  public let annotationType: KindleAnnotationType
  public let position: Int?
  public let page: Int?

  /// Makes a new annotation for a given ``Book`` model with given HTML markup
  ///
  public init(from markup: SwiftSoup.Element) throws {
    self.kindleHighlightID = markup.id()

    // If the note text is present and is not empty, this highlight is actually a note.
    // save the type = .note and the noteText.
    let highlightText = try markup.select("#highlight").first()?.text().trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    let noteText = try markup.select("#note").first()?.text().trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    let bookmarkMarker = try Self.hasBookmarkMarker(in: markup)
    guard (highlightText?.isEmpty == false) || (noteText?.isEmpty == false) || bookmarkMarker else {
      throw KindleError.htmlDecodingError(nil)
    }

    self.highlightText = highlightText ?? ""

    if let noteText, !noteText.isEmpty {
      self.annotationType = .note
      self.noteText = noteText
    } else if bookmarkMarker || self.highlightText.isEmpty {
      self.annotationType = .bookmark
      self.noteText = nil
    } else {
      self.annotationType = .highlight
      self.noteText = nil
    }

    // Parse highlight color
    let highlightContainer = try markup.select(".kp-notebook-highlight").first()
    let colorClass = try highlightContainer?.className() ?? ""
    let colorComponents = colorClass.components(separatedBy: " ")
    let colorString =
      colorComponents.first(where: { $0.hasPrefix("kp-notebook-highlight-") })?
      .replacingOccurrences(of: "kp-notebook-highlight-", with: "") ?? "yellow"

    self.highlightColor = KindleHighlightColor.init(rawValue: colorString) ?? .yellow

    // Parse page number
    let headerElement = try markup.select("#annotationHighlightHeader").first()
    let headerText = try headerElement?.text() ?? ""
    let pageRange = headerText.range(of: "Page:\\s*", options: .regularExpression)
    if let pageRange = pageRange {
      let pageString = headerText[pageRange.upperBound...].trimmingCharacters(
        in: .whitespaces)
      self.page = Int(String(pageString))
    } else {
      self.page = nil
    }

    // Parse position
    let locationValue = try markup.select("#kp-annotation-location").first()?.val()
    self.position = Int(locationValue ?? "0") ?? 0
  }

  public static func parseFromHTML(markup: String) throws -> [KindleHTMLAnnotation] {
    let page = try SwiftSoup.parse(markup)

    let allAnnotations = try page.select("#kp-notebook-annotations > div")

    // If making any one particular annotation fails, ignore it and move on
    let highlights = allAnnotations.compactMap { try? KindleHTMLAnnotation(from: $0) }
    return highlights
  }

  private static func hasBookmarkMarker(in markup: SwiftSoup.Element) throws -> Bool {
    let classAndIDStrings = try markup.select("[class], [id]").array().flatMap { element in
      [try element.className(), element.id()]
    }

    if classAndIDStrings.contains(where: { $0.localizedCaseInsensitiveContains("bookmark") }) {
      return true
    }

    let accessibleLabels = try markup.select("[aria-label], [title], img[alt]").array().flatMap {
      element in
      [
        try element.attr("aria-label"),
        try element.attr("title"),
        try element.attr("alt"),
      ]
    }

    return accessibleLabels.contains(where: { $0.localizedCaseInsensitiveContains("bookmark") })
  }
}
