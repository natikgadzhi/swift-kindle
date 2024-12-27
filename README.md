# KindleAPI

A Swift cross-platform library for interacting with Amazon Kindle services. This package provides a type-safe interface to access your Kindle library, annotations, and reading progress.

## Features

- Cross-platform support (iOS, macOS, Linux)
- Type-safe API client
- Async/await based API
- Secure credential handling
- Configurable logging
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

## Security Note

Kindle does not provide an actual public-facing API. This package is using internal Amazon Kindle APIs. They're not supported by Amazon, and may change or be removed at any time.

`KindleAPI` takes a set of Amazon Kindle authentication secrets (4 cookies that expire in a year, and a special device token). The package does not provide the code to fetch or update the secrets.

## License

MIT License. See [LICENSE](LICENSE) file for details. 