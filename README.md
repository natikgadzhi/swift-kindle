# KindleAPI

A Swift library for interacting with Amazon Kindle services. This package provides a type-safe interface to access your Kindle library, book metadata, and annotations through Kindle's internal web APIs.

## Features

- Type-safe API client
- Async/await based API
- Support for Kindle JSON and HTML notebook endpoints
- Secure credential handling
- Configurable logging
- Swift 6 sendability annotations
- Minimal dependencies

## Installation

Add this package to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/natikgadzhi/swift-kindle.git", branch: "main")
]
```

## Usage

```swift
import KindleAPI

// Initialize the client with authentication session
let client = KindleAPI(secrets: authSession)

// Fetch your library (returns [KindleJSONBook])
let books = try await client.getBooks()

// Get book details and metadata
let (details, metadata) = try await client.getBookMetadata(asin: "B001234567")

// Get annotations for a book
let annotations = try await client.getAnnotations(
    for: details.asin,
    refEmId: metadata.refEmId,
    yjFormatVersion: details.yjFormatVersion
)

// Alternative: fetch books from HTML notebook (returns [KindleHTMLBook])
// This returns a _different_ list of books — not just the books
// you _currently own_ in Kindle, but all the books that you have any annotations for.
let htmlBooks = try await client.getHTMLBooks()
```

## Supported Methods

- `getBooks()` - fetch the Kindle library JSON list
- `getBookMetadata(asin:)` - fetch book details and metadata
- `getAnnotations(for:refEmId:yjFormatVersion:)` - fetch Kindle JSON annotations for a book
- `getHTMLBooks()` - fetch the Kindle Notebook HTML book list
- `getHTMLAnnotations(for:)` - fetch Kindle Notebook HTML annotations for a book

## Security Note

Kindle does not provide an actual public-facing API. This package uses internal Amazon Kindle endpoints. They are not supported by Amazon, and may change or be removed at any time.

`KindleAPI` takes a set of Amazon Kindle authentication secrets (4 cookies that expire in a year, and a special device token). The package does not provide the code to fetch or update the secrets.

## License

MIT License. See [LICENSE](LICENSE) file for details. 
