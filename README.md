# swift-rfc-7578

Domain model for RFC 7578, Returning Values from Forms (`multipart/form-data`), layered on [swift-rfc-2046](https://github.com/swift-ietf/swift-rfc-2046): `RFC_2046.Multipart.formData(fields:files:boundary:)` builds a `form-data` multipart whose parts carry `RFC_2183.ContentDisposition.formData(name:filename:)` headers, `RFC_7578.Form.Data.File` is a validated upload (non-empty field name, `RFC_2183.Filename`, optional `RFC_2045.ContentType`, raw octets per section 4.7), and `RFC_7578.Form.Data.Decoded` projects the parts of a received multipart back into `Field`s and `File`s, honouring the part charset and the `_charset_` default of section 5.1.1. The `RFC 7578 Foundation Integration` product bridges `Field`, `File` and `Decoded` to `Codable`. Wire parsing and serialization of the multipart body live in [swift-rfc-2046-coder](https://github.com/swift-ietf/swift-rfc-2046-coder); the text form of the disposition header lives in [swift-rfc-2183-coder](https://github.com/swift-ietf/swift-rfc-2183-coder).

```swift
import RFC_2045
import RFC_2046
import RFC_2183
import RFC_7578

let avatar = try RFC_7578.Form.Data.File(
    fieldName: "avatar",
    filename: try RFC_2183.Filename("photo.jpg"),
    contentType: try RFC_2045.ContentType("image/jpeg"),
    content: [0xFF, 0xD8, 0xFF, 0xE0]
)

let multipart = try RFC_2046.Multipart.formData(
    fields: ["username": "john_doe", "email": "john@example.com"],
    files: [avatar]
)
multipart.subtype                                    // .formData
multipart.parts.count                                // 3
multipart.parts.first?.headers.contentDisposition?.name   // "email"

let decoded = try multipart.formData()
decoded["username"]                                  // "john_doe"
decoded.file(named: "avatar")?.filename.rawValue     // "photo.jpg"
```

```swift
import Foundation
import RFC_7578
import RFC_7578_Foundation_Integration

let json = try JSONEncoder().encode(decoded)
try JSONDecoder().decode(RFC_7578.Form.Data.Decoded.self, from: json) == decoded   // true
```
