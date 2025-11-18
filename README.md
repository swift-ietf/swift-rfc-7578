# Swift RFC 7578

[![CI](https://github.com/swift-standards/swift-rfc-7578/workflows/CI/badge.svg)](https://github.com/swift-standards/swift-rfc-7578/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of RFC 7578: Returning Values from Forms - multipart/form-data

## Overview

This package provides a Swift implementation of multipart/form-data as defined in [RFC 7578](https://www.rfc-editor.org/rfc/rfc7578.html). It enables creating multipart/form-data messages for HTTP file uploads with proper Content-Disposition header escaping and binary data support.

RFC 7578 specifies the multipart/form-data media type for submitting forms and uploading files in HTTP requests.

## Features

- **Multipart/Form-Data**: Create form-data messages with fields and file uploads
- **Binary File Support**: Direct binary data support (no encoding needed per RFC 7578 §4.7)
- **Content-Disposition Escaping**: Proper escaping of field names and filenames
- **Type-Safe File Upload**: Validated file upload structure with required field names and filenames
- **RFC Compliant**: Follows RFC 7578 specifications for HTTP form data
- **Swift 6 Support**: Strict concurrency support with full `Sendable` and `Codable` conformance

## Installation

Add swift-rfc-7578 to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-rfc-7578.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 7578", package: "swift-rfc-7578")
    ]
)
```

## Quick Start

### Creating Form Data with Text Fields

```swift
import RFC_2046
import RFC_7578

// Create form data with text fields
let formData = try RFC_2046.Multipart.formData(
    fields: [
        "username": "john_doe",
        "email": "john@example.com"
    ]
)

// Get Content-Type header
let contentType = formData.contentType.headerValue
// "multipart/form-data; boundary=----=_Part_<UUID>"

// Render the complete form data body
let body = formData.render()
```

### Creating Form Data with File Upload

```swift
import RFC_2045
import RFC_2046
import RFC_7578

// Load image data
let imageData = try Data(contentsOf: URL(fileURLWithPath: "photo.jpg"))

// Create file upload
let file = try RFC_7578.FormData.File(
    fieldName: "avatar",
    filename: "photo.jpg",
    contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
    content: imageData
)

// Create form data with fields and files
let formData = try RFC_2046.Multipart.formData(
    fields: [
        "username": "john_doe",
        "email": "john@example.com"
    ],
    files: [file]
)

// Use in HTTP request
let contentType = formData.contentType.headerValue
let body = formData.render()
```

### Multiple File Upload

```swift
let imageFile = try RFC_7578.FormData.File(
    fieldName: "avatar",
    filename: "photo.jpg",
    contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
    content: imageData
)

let documentFile = try RFC_7578.FormData.File(
    fieldName: "document",
    filename: "resume.pdf",
    contentType: RFC_2045.ContentType(type: "application", subtype: "pdf"),
    content: pdfData
)

let formData = try RFC_2046.Multipart.formData(
    fields: ["description": "My files"],
    files: [imageFile, documentFile]
)
```

## Usage

### Type Overview

#### `RFC_7578.FormData.File`

Represents a file upload in multipart/form-data.

```swift
public struct File {
    public let fieldName: String
    public let filename: String
    public let contentType: RFC_2045.ContentType?
    public let content: Data

    public init(
        fieldName: String,
        filename: String,
        contentType: RFC_2045.ContentType? = nil,
        content: Data
    ) throws
}
```

#### `RFC_2046.Multipart.formData(fields:files:boundary:)`

Creates a multipart/form-data message.

```swift
public static func formData(
    fields: [String: String],
    files: [RFC_7578.FormData.File] = [],
    boundary: String? = nil
) throws -> RFC_2046.Multipart
```

#### Content-Disposition Escaping

```swift
// Escape field names and filenames
let escaped = RFC_2046.Multipart.escapeContentDisposition(
    name: "avatar",
    filename: "photo.jpg"
)
// Result: "form-data; name=\"avatar\"; filename=\"photo.jpg\""

// Handles special characters
let escapedWithQuotes = RFC_2046.Multipart.escapeContentDisposition(
    name: "field\"name"
)
// Result: "form-data; name=\"field\\\"name\""
```

### Error Handling

```swift
do {
    let file = try RFC_7578.FormData.File(
        fieldName: "",  // Empty field name
        filename: "photo.jpg",
        content: imageData
    )
} catch RFC_7578.FormData.Error.emptyFieldName {
    print("Field name cannot be empty")
}

do {
    let file = try RFC_7578.FormData.File(
        fieldName: "avatar",
        filename: "",  // Empty filename
        content: imageData
    )
} catch RFC_7578.FormData.Error.emptyFilename {
    print("Filename cannot be empty for file uploads")
}
```

## RFC 7578 Compliance

This implementation follows RFC 7578 specifications:

- **Content-Disposition Headers**: Each part includes proper `Content-Disposition: form-data` headers
- **Field Name Requirements**: Field names are required and properly escaped
- **Filename Parameter**: File uploads include the filename parameter
- **Binary Data Support**: Per RFC 7578 §4.7, Content-Transfer-Encoding is not used because HTTP supports binary data natively
- **Character Escaping**: Proper escaping of quotes in field names and filenames

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+ / tvOS 17.0+ / watchOS 10.0+

## Related Packages

### Dependencies
- [swift-rfc-2045](https://github.com/swift-standards/swift-rfc-2045) - MIME fundamentals (Content-Type, Content-Transfer-Encoding)
- [swift-rfc-2046](https://github.com/swift-standards/swift-rfc-2046) - MIME multipart media types

### Related
- [swift-rfc-2388](https://github.com/swift-standards/swift-rfc-2388) - Returning Values from Forms: multipart/form-data encoding

## License

This library is released under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
