# swift-rfc-7578

Use this package when you build or read a `multipart/form-data` body, such as an HTML form submission with file uploads. To build one, call `RFC_2046.Multipart.formData(fields:files:boundary:)` with `RFC_7578.Form.Data.File` values for the uploads. To read one, start from `RFC_7578.Form.Data.Decoded`, which splits the parts into text fields and files. For other multipart subtypes, use swift-rfc-2046 directly. For `Codable`, add the `RFC 7578 Foundation Integration` product.

## Laws

- When building, text fields are written first, sorted by name, each as `text/plain` in UTF-8. Files follow in the order given.
- Without an explicit boundary, the boundary is built from the number of parts and the first part's media type. It is not random, so pass your own when the content could contain it.
- When reading, every part must have a `form-data` Content-Disposition with a non-empty name. A part with a filename becomes a file and keeps its bytes as they are. Every other part becomes a text field.
- A text field is decoded with the charset of its own Content-Type. If it has none, the value of a `_charset_` field is used, and otherwise UTF-8. The `_charset_` field is still returned as a field.
- The charsets understood are UTF-8, US-ASCII, ISO-8859-1 and UTF-16 (BE, LE, or with a byte order mark, big-endian when there is none). Text that isn't valid in its charset fails, rather than being repaired.
- Fields and files keep the order of the parts, including repeated names. `RFC_7578.Form.Data.Decoded` subscripted by name returns the first value.
- With `RFC 7578 Foundation Integration`, a field encodes as its `name` and `value`, a file as its `fieldName`, `filename`, optional `contentType` and `content` bytes, and a decoded form as its `fields` and `files`. An empty name or an unsafe filename such as `../x` fails to decode.
