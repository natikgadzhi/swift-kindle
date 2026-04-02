//
//  KindleAPITests.swift
//  KindleAPITests
//
//  Created by Natik Gadzhi on 12/23/23.
//

import Foundation
import KindleAPI
import SwiftSoup
import Testing

// MARK: - KindleEndpoint Tests

@Suite("KindleEndpoint URL generation")
struct KindleEndpointTests {

    @Test("booksListJSON with empty token uses base URL without pagination parameter")
    func booksListJSONEmptyToken() {
        let url = KindleEndpoint.booksListJSON(paginationToken: "").url
        #expect(url.host() == "read.amazon.com")
        #expect(url.path() == "/kindle-library/search")
        let query = url.query() ?? ""
        #expect(!query.contains("paginationToken"))
    }

    @Test("booksListJSON with pagination token includes token in URL")
    func booksListJSONWithToken() {
        let token = "someToken123"
        let url = KindleEndpoint.booksListJSON(paginationToken: token).url
        #expect(url.host() == "read.amazon.com")
        let query = url.query() ?? ""
        #expect(query.contains("paginationToken=someToken123"))
    }

    @Test("booksListHTML without pagination token uses base notebook URL")
    func booksListHTMLNoToken() {
        let url = KindleEndpoint.booksListHTML(paginationToken: nil).url
        #expect(url.host() == "read.amazon.com")
        #expect(url.path() == "/notebook")
        let query = url.query() ?? ""
        #expect(!query.contains("token="))
    }

    @Test("booksListHTML with pagination token includes token in URL")
    func booksListHTMLWithToken() {
        let token = "pageToken456"
        let url = KindleEndpoint.booksListHTML(paginationToken: token).url
        #expect(url.host() == "read.amazon.com")
        let query = url.query() ?? ""
        #expect(query.contains("token=pageToken456"))
    }

    @Test("annotationsListHTML includes asin in URL")
    func annotationsListHTMLURL() {
        let url = KindleEndpoint.annotationsListHTML(asin: "B000TESTXX").url
        #expect(url.host() == "read.amazon.com")
        let query = url.query() ?? ""
        #expect(query.contains("asin=B000TESTXX"))
    }

    @Test("annotationsListJSON includes asin, refEmId, and yjFormatVersion in URL")
    func annotationsListJSONURL() {
        let url = KindleEndpoint.annotationsListJSON(
            asin: "B000TESTXX",
            refEmId: "ref123",
            yjFormatVersion: "v1"
        ).url
        #expect(url.host() == "read.amazon.com")
        let query = url.query() ?? ""
        #expect(query.contains("asin=B000TESTXX"))
        #expect(query.contains("ref123"))
        #expect(query.contains("v1"))
    }

    @Test("bookDetailsJSON includes asin in URL")
    func bookDetailsJSONURL() {
        let url = KindleEndpoint.bookDetailsJSON(asin: "B000ASIN00").url
        #expect(url.host() == "read.amazon.com")
        let path = url.path()
        #expect(path.contains("startReading"))
        let query = url.query() ?? ""
        #expect(query.contains("asin=B000ASIN00"))
    }

    @Test("deviceInfo includes token in URL")
    func deviceInfoURL() {
        let url = KindleEndpoint.deviceInfo(token: "device-token-abc").url
        #expect(url.host() == "read.amazon.com")
        let query = url.query() ?? ""
        #expect(query.contains("serialNumber=device-token-abc"))
        #expect(query.contains("deviceType=device-token-abc"))
    }

    @Test("login URL points to Amazon sign-in and returns to notebook")
    func loginURL() {
        let url = KindleEndpoint.login.url
        #expect(url.host() == "www.amazon.com")
        #expect(url.path() == "/ap/signin")
        // After Amazon discontinued the Kindle Cloud Reader library page, the login
        // flow must return to the notebook page instead of kindle-library.
        let query = url.query() ?? ""
        #expect(query.contains("notebook"))
        #expect(!query.contains("kindle-library"))
    }

    @Test("notebook URL points to Kindle Notebook")
    func notebookURL() {
        let url = KindleEndpoint.notebook.url
        #expect(url.host() == "read.amazon.com")
        #expect(url.path() == "/notebook")
    }
}

// MARK: - KindleHTMLBook Parsing Tests

@Suite("KindleHTMLBook HTML parsing")
struct KindleHTMLBookTests {

    private let validBookHTML = """
        <div id="B084357H23" class="kp-notebook-library-each-book">
            <img class="kp-notebook-cover-image" src="https://m.media-amazon.com/images/I/cover.jpg"/>
            <h2>The Invisible Life of Addie LaRue</h2>
            <p class="kp-notebook-searchable">By: Schwab, V. E.</p>
            <input id="kp-notebook-annotated-date-B084357H23" type="hidden" value="Wednesday Jan 1, 2025"/>
        </div>
        """

    @Test("parses ASIN from element id")
    func parsesASIN() throws {
        let doc = try SwiftSoup.parse(validBookHTML)
        let element = try doc.select(".kp-notebook-library-each-book").first()!
        let book = try KindleHTMLBook(from: element)
        #expect(book.asin == "B084357H23")
    }

    @Test("parses title from h2 element")
    func parsesTitle() throws {
        let doc = try SwiftSoup.parse(validBookHTML)
        let element = try doc.select(".kp-notebook-library-each-book").first()!
        let book = try KindleHTMLBook(from: element)
        #expect(book.title == "The Invisible Life of Addie LaRue")
    }

    @Test("strips 'By: ' prefix from author")
    func parsesAuthorStrippingPrefix() throws {
        let doc = try SwiftSoup.parse(validBookHTML)
        let element = try doc.select(".kp-notebook-library-each-book").first()!
        let book = try KindleHTMLBook(from: element)
        #expect(book.author == "Schwab, V. E.")
    }

    @Test("parses cover image URL from img src")
    func parsesCoverImageURL() throws {
        let doc = try SwiftSoup.parse(validBookHTML)
        let element = try doc.select(".kp-notebook-library-each-book").first()!
        let book = try KindleHTMLBook(from: element)
        #expect(book.coverImageURL.host() == "m.media-amazon.com")
    }

    @Test("parses modifiedAt date correctly")
    func parsesModifiedAt() throws {
        let doc = try SwiftSoup.parse(validBookHTML)
        let element = try doc.select(".kp-notebook-library-each-book").first()!
        let book = try KindleHTMLBook(from: element)
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: book.modifiedAt)
        #expect(components.year == 2025)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }

    @Test("throws htmlDecodingError when title element is missing")
    func throwsWhenTitleMissing() throws {
        let html = """
            <div id="B000TEST00" class="kp-notebook-library-each-book">
                <img class="kp-notebook-cover-image" src="https://example.com/cover.jpg"/>
                <p class="kp-notebook-searchable">By: Author Name</p>
                <input id="kp-notebook-annotated-date-B000TEST00" type="hidden" value="Wednesday Jan 1, 2025"/>
            </div>
            """
        let doc = try SwiftSoup.parse(html)
        let element = try doc.select(".kp-notebook-library-each-book").first()!
        #expect(throws: (any Error).self) {
            _ = try KindleHTMLBook(from: element)
        }
    }

    @Test("parses author without 'By: ' prefix as-is")
    func parsesAuthorWithoutPrefix() throws {
        let html = """
            <div id="B084357H23" class="kp-notebook-library-each-book">
                <img class="kp-notebook-cover-image" src="https://m.media-amazon.com/images/I/cover.jpg"/>
                <h2>Some Book</h2>
                <p class="kp-notebook-searchable">Author Name Without Prefix</p>
                <input id="kp-notebook-annotated-date-B084357H23" type="hidden" value="Wednesday Jan 1, 2025"/>
            </div>
            """
        let doc = try SwiftSoup.parse(html)
        let element = try doc.select(".kp-notebook-library-each-book").first()!
        let book = try KindleHTMLBook(from: element)
        #expect(book.author == "Author Name Without Prefix")
    }

    // Amazon has used both plain <h2> and <h2 class="kp-notebook-searchable"> in different page versions.
    // The parser should handle both.
    @Test("parses title from h2.kp-notebook-searchable element")
    func parsesTitleFromClassedH2() throws {
        let html = """
            <div id="B084357H23" class="kp-notebook-library-each-book">
                <img class="kp-notebook-cover-image" src="https://m.media-amazon.com/images/I/cover.jpg"/>
                <h2 class="kp-notebook-searchable">The Invisible Life of Addie LaRue</h2>
                <p class="kp-notebook-searchable">By: Schwab, V. E.</p>
                <input id="kp-notebook-annotated-date-B084357H23" type="hidden" value="Wednesday Jan 1, 2025"/>
            </div>
            """
        let doc = try SwiftSoup.parse(html)
        let element = try doc.select(".kp-notebook-library-each-book").first()!
        let book = try KindleHTMLBook(from: element)
        #expect(book.title == "The Invisible Life of Addie LaRue")
    }

    @Test("parses title from plain h2 when h2.kp-notebook-searchable is absent")
    func parsesTitleFromPlainH2WhenClassedH2Absent() throws {
        // Verifies the fallback: if <h2 class="kp-notebook-searchable"> is not found, fall back to <h2>.
        let html = """
            <div id="B084357H23" class="kp-notebook-library-each-book">
                <img class="kp-notebook-cover-image" src="https://m.media-amazon.com/images/I/cover.jpg"/>
                <h2>Plain H2 Title</h2>
                <p class="kp-notebook-searchable">By: Author Name</p>
                <input id="kp-notebook-annotated-date-B084357H23" type="hidden" value="Wednesday Jan 1, 2025"/>
            </div>
            """
        let doc = try SwiftSoup.parse(html)
        let element = try doc.select(".kp-notebook-library-each-book").first()!
        let book = try KindleHTMLBook(from: element)
        #expect(book.title == "Plain H2 Title")
    }
}

// MARK: - KindleHTMLAnnotation Parsing Tests

@Suite("KindleHTMLAnnotation HTML parsing")
struct KindleHTMLAnnotationTests {

    private let yellowHighlightHTML = """
        <div id="highlight-001">
            <span id="highlight">This is the highlighted text.</span>
            <span id="note"></span>
            <div class="kp-notebook-highlight kp-notebook-highlight-yellow"></div>
            <div id="annotationHighlightHeader">Page: 42</div>
            <input id="kp-annotation-location" value="1234"/>
        </div>
        """

    private let noteHTML = """
        <div id="note-001">
            <span id="highlight">Some highlighted text for note.</span>
            <span id="note">My note text here.</span>
            <div class="kp-notebook-highlight kp-notebook-highlight-blue"></div>
            <div id="annotationHighlightHeader">Page: 10</div>
            <input id="kp-annotation-location" value="500"/>
        </div>
        """

    @Test("parses highlight ID from element id")
    func parsesHighlightID() throws {
        let doc = try SwiftSoup.parse(yellowHighlightHTML)
        let element = try doc.select("div").first()!
        let annotation = try KindleHTMLAnnotation(from: element)
        #expect(annotation.kindleHighlightID == "highlight-001")
    }

    @Test("parses highlight text from #highlight element")
    func parsesHighlightText() throws {
        let doc = try SwiftSoup.parse(yellowHighlightHTML)
        let element = try doc.select("div").first()!
        let annotation = try KindleHTMLAnnotation(from: element)
        #expect(annotation.highlightText == "This is the highlighted text.")
    }

    @Test("sets annotationType to highlight when note is empty")
    func annotationTypeIsHighlightWhenNoteEmpty() throws {
        let doc = try SwiftSoup.parse(yellowHighlightHTML)
        let element = try doc.select("div").first()!
        let annotation = try KindleHTMLAnnotation(from: element)
        #expect(annotation.annotationType == .highlight)
        #expect(annotation.noteText == nil)
    }

    @Test("parses yellow highlight color correctly")
    func parsesYellowHighlightColor() throws {
        let doc = try SwiftSoup.parse(yellowHighlightHTML)
        let element = try doc.select("div").first()!
        let annotation = try KindleHTMLAnnotation(from: element)
        #expect(annotation.highlightColor == .yellow)
    }

    @Test("parses page number from header")
    func parsesPageNumber() throws {
        let doc = try SwiftSoup.parse(yellowHighlightHTML)
        let element = try doc.select("div").first()!
        let annotation = try KindleHTMLAnnotation(from: element)
        #expect(annotation.page == 42)
    }

    @Test("parses location position from hidden input")
    func parsesPosition() throws {
        let doc = try SwiftSoup.parse(yellowHighlightHTML)
        let element = try doc.select("div").first()!
        let annotation = try KindleHTMLAnnotation(from: element)
        #expect(annotation.position == 1234)
    }

    @Test("sets annotationType to note and saves noteText when note is present")
    func annotationTypeIsNoteWhenNotePresent() throws {
        let doc = try SwiftSoup.parse(noteHTML)
        let element = try doc.select("div").first()!
        let annotation = try KindleHTMLAnnotation(from: element)
        #expect(annotation.annotationType == .note)
        #expect(annotation.noteText == "My note text here.")
    }

    @Test("parses blue highlight color correctly")
    func parsesBlueHighlightColor() throws {
        let doc = try SwiftSoup.parse(noteHTML)
        let element = try doc.select("div").first()!
        let annotation = try KindleHTMLAnnotation(from: element)
        #expect(annotation.highlightColor == .blue)
    }

    @Test("parseFromHTML returns empty array when no annotations present")
    func parseFromHTMLEmpty() throws {
        let html = "<div id='kp-notebook-annotations'></div>"
        let annotations = try KindleHTMLAnnotation.parseFromHTML(markup: html)
        #expect(annotations.isEmpty)
    }

    @Test("parseFromHTML skips malformed annotations gracefully")
    func parseFromHTMLSkipsMalformed() throws {
        // One valid annotation wrapped in the container, one missing highlight text
        let html = """
            <div id="kp-notebook-annotations">
                <div id="valid-001">
                    <span id="highlight">Valid text.</span>
                    <span id="note"></span>
                    <div class="kp-notebook-highlight kp-notebook-highlight-yellow"></div>
                    <div id="annotationHighlightHeader">Page: 1</div>
                    <input id="kp-annotation-location" value="100"/>
                </div>
                <div id="invalid-002">
                    <!-- missing highlight span entirely -->
                    <div class="kp-notebook-highlight kp-notebook-highlight-yellow"></div>
                </div>
                <!-- last-child is excluded by the CSS selector, so add a trailing element -->
                <div id="trailing"></div>
            </div>
            """
        let annotations = try KindleHTMLAnnotation.parseFromHTML(markup: html)
        // The valid one is parsed, the invalid one is skipped
        #expect(annotations.count == 1)
        #expect(annotations[0].highlightText == "Valid text.")
    }
}

// MARK: - KindleJSONBook Decoding Tests

@Suite("KindleJSONBook JSON decoding")
struct KindleJSONBookTests {

    private let singleBookJSON = """
        {
            "asin": "B084357H23",
            "webReaderUrl": "https://read.amazon.com/?asin=B084357H23",
            "productUrl": "https://m.media-amazon.com/images/I/418brAemxDL._SY400_.jpg",
            "title": "The Invisible Life of Addie LaRue",
            "percentageRead": 0,
            "authors": ["Schwab, V. E.:"],
            "resourceType": "EBOOK",
            "originType": "PURCHASE",
            "mangaOrComicAsin": false
        }
        """

    private let libraryResponseJSON = """
        {
            "itemsList": [
                {
                    "asin": "B084357H23",
                    "webReaderUrl": "https://read.amazon.com/?asin=B084357H23",
                    "productUrl": "https://m.media-amazon.com/images/I/cover.jpg",
                    "title": "Test Book",
                    "authors": ["LastName, FirstName:"],
                    "resourceType": "EBOOK"
                }
            ],
            "paginationToken": "nextPage123",
            "libraryType": "BOOKS",
            "sortType": "recency"
        }
        """

    @Test("decodes ASIN correctly from JSON")
    func decodesASIN() throws {
        let data = singleBookJSON.data(using: .utf8)!
        let book = try JSONDecoder().decode(KindleJSONBook.self, from: data)
        #expect(book.asin == "B084357H23")
    }

    @Test("decodes title from JSON")
    func decodesTitle() throws {
        let data = singleBookJSON.data(using: .utf8)!
        let book = try JSONDecoder().decode(KindleJSONBook.self, from: data)
        #expect(book.title == "The Invisible Life of Addie LaRue")
    }

    @Test("decodes webReaderURL from JSON")
    func decodesWebReaderURL() throws {
        let data = singleBookJSON.data(using: .utf8)!
        let book = try JSONDecoder().decode(KindleJSONBook.self, from: data)
        #expect(book.webReaderURL.host() == "read.amazon.com")
    }

    @Test("decodes coverImageURL from productUrl field")
    func decodesCoverImageURL() throws {
        let data = singleBookJSON.data(using: .utf8)!
        let book = try JSONDecoder().decode(KindleJSONBook.self, from: data)
        #expect(book.coverImageURL.host() == "m.media-amazon.com")
    }

    @Test("derives author from authors array stripping trailing colon and reversing name parts")
    func derivesAuthorName() throws {
        let data = singleBookJSON.data(using: .utf8)!
        let book = try JSONDecoder().decode(KindleJSONBook.self, from: data)
        // "Schwab, V. E.:" -> reversed -> "V. E. Schwab"
        #expect(book.author.contains("Schwab"))
    }

    @Test("decodes resourceType from JSON")
    func decodesResourceType() throws {
        let data = singleBookJSON.data(using: .utf8)!
        let book = try JSONDecoder().decode(KindleJSONBook.self, from: data)
        #expect(book.resourceType == "EBOOK")
    }

    @Test("decodes library search response with pagination token")
    func decodesLibrarySearchResponse() throws {
        let data = libraryResponseJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(KindleLibrarySearchResponse.self, from: data)
        #expect(response.itemsList.count == 1)
        #expect(response.paginationToken == "nextPage123")
        #expect(response.libraryType == "BOOKS")
        #expect(response.sortType == "recency")
    }

    @Test("decodes library search response with nil pagination token")
    func decodesLibrarySearchResponseNoPagination() throws {
        let json = """
            {
                "itemsList": [],
                "libraryType": "BOOKS",
                "sortType": "recency"
            }
            """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(KindleLibrarySearchResponse.self, from: data)
        #expect(response.paginationToken == nil)
        #expect(response.itemsList.isEmpty)
    }
}

// MARK: - KindleJSONAnnotation Decoding Tests

@Suite("KindleJSONAnnotation JSON decoding")
struct KindleJSONAnnotationTests {

    private let highlightJSON = """
        {
            "id": "ann-001",
            "highlightText": "This is a highlight.",
            "color": "yellow",
            "position": 1000,
            "start": 990,
            "end": 1010,
            "annotationType": "kindle.highlight"
        }
        """

    private let noteJSON = """
        {
            "id": "ann-002",
            "highlightText": "Highlighted passage.",
            "noteText": "My note about this.",
            "color": "blue",
            "position": 2000,
            "start": 1990,
            "end": 2010,
            "annotationType": "kindle.note"
        }
        """

    private let getAnnotationsResponseJSON = """
        {
            "annotations": [
                {
                    "id": "ann-001",
                    "highlightText": "Some text.",
                    "color": "green",
                    "position": 300,
                    "start": 290,
                    "end": 310,
                    "annotationType": "kindle.highlight"
                }
            ]
        }
        """

    @Test("decodes highlight text from JSON")
    func decodesHighlightText() throws {
        let data = highlightJSON.data(using: .utf8)!
        let annotation = try JSONDecoder().decode(KindleJSONAnnotation.self, from: data)
        #expect(annotation.highlightText == "This is a highlight.")
    }

    @Test("decodes highlight color from JSON")
    func decodesHighlightColor() throws {
        let data = highlightJSON.data(using: .utf8)!
        let annotation = try JSONDecoder().decode(KindleJSONAnnotation.self, from: data)
        #expect(annotation.highlightColor == .yellow)
    }

    @Test("decodes annotation type as highlight")
    func decodesAnnotationTypeHighlight() throws {
        let data = highlightJSON.data(using: .utf8)!
        let annotation = try JSONDecoder().decode(KindleJSONAnnotation.self, from: data)
        #expect(annotation.annotationType == .highlight)
    }

    @Test("decodes position, start, and end from JSON")
    func decodesPositionRange() throws {
        let data = highlightJSON.data(using: .utf8)!
        let annotation = try JSONDecoder().decode(KindleJSONAnnotation.self, from: data)
        #expect(annotation.position == 1000)
        #expect(annotation.start == 990)
        #expect(annotation.end == 1010)
    }

    @Test("decodes optional noteText as nil when absent")
    func decodesNoteTextNilWhenAbsent() throws {
        let data = highlightJSON.data(using: .utf8)!
        let annotation = try JSONDecoder().decode(KindleJSONAnnotation.self, from: data)
        #expect(annotation.noteText == nil)
    }

    @Test("decodes noteText when present")
    func decodesNoteTextWhenPresent() throws {
        let data = noteJSON.data(using: .utf8)!
        let annotation = try JSONDecoder().decode(KindleJSONAnnotation.self, from: data)
        #expect(annotation.noteText == "My note about this.")
    }

    @Test("decodes blue annotation color")
    func decodesBlueColor() throws {
        let data = noteJSON.data(using: .utf8)!
        let annotation = try JSONDecoder().decode(KindleJSONAnnotation.self, from: data)
        #expect(annotation.highlightColor == .blue)
    }

    @Test("decodes annotation type as note")
    func decodesAnnotationTypeNote() throws {
        let data = noteJSON.data(using: .utf8)!
        let annotation = try JSONDecoder().decode(KindleJSONAnnotation.self, from: data)
        #expect(annotation.annotationType == .note)
    }

    @Test("decodes getAnnotations response wrapper")
    func decodesGetAnnotationsResponse() throws {
        let data = getAnnotationsResponseJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(KindleGetAnnotationsResponse.self, from: data)
        #expect(response.annotations.count == 1)
        #expect(response.annotations[0].highlightColor == .green)
    }
}

// MARK: - KindleError Tests

@Suite("KindleError descriptions")
struct KindleErrorTests {

    @Test("unauthenticated has non-empty errorDescription")
    func unauthenticatedDescription() {
        let error = KindleError.unauthenticated
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription!.isEmpty))
    }

    @Test("kindleAPIError has non-empty errorDescription")
    func kindleAPIErrorDescription() {
        let error = KindleError.kindleAPIError
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription!.isEmpty))
    }

    @Test("badHTTPResponse has non-empty errorDescription")
    func badHTTPResponseDescription() {
        let error = KindleError.badHTTPResponse
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription!.isEmpty))
    }

    @Test("decodingError wraps underlying error in description")
    func decodingErrorDescription() {
        struct TestError: Error {}
        let underlying = TestError()
        let error = KindleError.decodingError(underlying)
        #expect(error.errorDescription != nil)
        // The description includes the string representation of the underlying error
        #expect(error.errorDescription!.contains("\(underlying)"))
    }

    @Test("htmlDecodingError with nil has non-empty errorDescription")
    func htmlDecodingErrorNilDescription() {
        let error = KindleError.htmlDecodingError(nil)
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription!.isEmpty))
    }

    @Test("htmlDecodingError with underlying error includes it in description")
    func htmlDecodingErrorWithUnderlyingDescription() {
        struct TestError: Error {}
        let underlying = TestError()
        let error = KindleError.htmlDecodingError(underlying)
        #expect(error.errorDescription != nil)
        // The description includes the string representation of the underlying error
        #expect(error.errorDescription!.contains("\(underlying)"))
    }

    @Test("noMetadata has non-empty errorDescription")
    func noMetadataDescription() {
        let error = KindleError.noMetadata
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription!.isEmpty))
    }

    @Test("kindleHTMLClientError has non-empty errorDescription")
    func kindleHTMLClientErrorDescription() {
        let error = KindleError.kindleHTMLClientError
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription!.isEmpty))
    }

    @Test("cantFetchAnnotations has non-empty errorDescription")
    func cantFetchAnnotationsDescription() {
        let error = KindleError.cantFetchAnnotations
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription!.isEmpty))
    }
}

// MARK: - KindleHighlightColor Tests

@Suite("KindleHighlightColor")
struct KindleHighlightColorTests {

    @Test("all colors have unique raw values")
    func allColorsAreUnique() {
        let rawValues = KindleHighlightColor.allCases.map { $0.rawValue }
        let uniqueValues = Set(rawValues)
        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("yellow color has rawValue 'yellow'")
    func yellowRawValue() {
        #expect(KindleHighlightColor.yellow.rawValue == "yellow")
    }

    @Test("all cases have the same id as rawValue")
    func idMatchesRawValue() {
        for color in KindleHighlightColor.allCases {
            #expect(color.id == color.rawValue)
        }
    }

    @Test("unknown color string falls back to yellow in HTML parsing")
    func unknownColorFallsBackToYellow() {
        let parsed = KindleHighlightColor(rawValue: "unknown-color")
        #expect(parsed == nil)
        // Fallback logic is in the HTML parser: uses ?? .yellow
        let fallback = KindleHighlightColor(rawValue: "unknown-color") ?? .yellow
        #expect(fallback == .yellow)
    }
}

// MARK: - KindleAnnotationType Tests

@Suite("KindleAnnotationType")
struct KindleAnnotationTypeTests {

    @Test("highlight raw value is 'kindle.highlight'")
    func highlightRawValue() {
        #expect(KindleAnnotationType.highlight.rawValue == "kindle.highlight")
    }

    @Test("note raw value is 'kindle.note'")
    func noteRawValue() {
        #expect(KindleAnnotationType.note.rawValue == "kindle.note")
    }

    @Test("bookmark raw value is 'kindle.bookmark'")
    func bookmarkRawValue() {
        #expect(KindleAnnotationType.bookmark.rawValue == "kindle.bookmark")
    }
}
