internal import RFC_2045
public import RFC_2046
internal import RFC_2183

extension RFC_7578.Form.Data {
    /// The decoded projection of a multipart/form-data body
    ///
    /// **RFC 7578** - Returning Values from Forms: multipart/form-data
    ///
    /// Given the parsed parts of a `multipart/form-data` body (headers + body
    /// bytes), projects them into named text `fields` and named `files`
    /// per RFC 7578 Section 4.2:
    ///
    /// - Every part must carry `Content-Disposition: form-data` with a
    ///   non-empty `name` parameter.
    /// - Parts with a `filename` parameter are files; all other parts are
    ///   text fields.
    ///
    /// Text field content is decoded per RFC 7578 Section 5.1: the part's own
    /// Content-Type `charset` parameter wins; otherwise the default charset
    /// declared by a `_charset_` field (Section 5.1.1) applies; otherwise
    /// UTF-8 is assumed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let multipart = try RFC_2046.Multipart(binary: bodyBytes, boundary: boundary)
    /// let decoded = try RFC_7578.Form.Data.Decoded(multipart)
    /// let username = decoded["username"]           // String?
    /// let avatar = decoded.file(named: "avatar")   // RFC_7578.Form.Data.File?
    /// ```
    public struct Decoded: Hashable, Sendable, Codable {
        /// The decoded text form fields, in part order
        ///
        /// Duplicate names are preserved: HTML forms may submit multiple
        /// values per name (RFC 7578 §5.2 advises supplying multiple parts
        /// sharing a name for multiple-file fields and, by extension,
        /// multi-valued fields).
        public let fields: [Field]

        /// The decoded file uploads, in part order
        public let files: [File]

        /// Creates a decoded form-data projection from already-projected
        /// fields and files
        public init(fields: [Field], files: [File]) {
            self.fields = fields
            self.files = files
        }
    }
}

// MARK: - Decoding from a parsed multipart body

extension RFC_7578.Form.Data.Decoded {
    /// Projects a parsed multipart body into named fields and files
    ///
    /// - Parameter multipart: A parsed `multipart/form-data` body
    /// - Throws: `RFC_7578.Form.Data.Decoded.Error` if a part violates
    ///   RFC 7578 §4.2 or its text content cannot be decoded per §5.1
    public init(_ multipart: RFC_2046.Multipart) throws(Error) {
        try self.init(multipart.parts)
    }

    /// Projects parsed body parts into named fields and files
    ///
    /// - Parameter parts: Parsed body parts (headers + body bytes)
    /// - Throws: `RFC_7578.Form.Data.Decoded.Error` if a part violates
    ///   RFC 7578 §4.2 or its text content cannot be decoded per §5.1
    public init(_ parts: [RFC_2046.BodyPart]) throws(Error) {
        // RFC 7578 §5.1.1: a "_charset_" field, when present, supplies the
        // default charset for text parts that carry no explicit charset.
        let defaultCharset = try Self.defaultCharset(of: parts)

        var fields: [RFC_7578.Form.Data.Field] = []
        var files: [RFC_7578.Form.Data.File] = []

        for part in parts {
            let (name, filename) = try Self.disposition(of: part)

            if let filename {
                // RFC 7578 §4.2: parts with a filename parameter are files.
                // File content stays binary; no charset applies (§4.7: no
                // Content-Transfer-Encoding in HTTP contexts).
                let file: RFC_7578.Form.Data.File
                do throws(RFC_7578.Form.Data.Error) {
                    file = try RFC_7578.Form.Data.File(
                        fieldName: name,
                        filename: filename,
                        contentType: part.headers.contentType,
                        // swift-linter:disable:next raw value access
                        // REASON: no typed byte accessor exposed by `RFC_2046.BodyPart.Content`; `.rawValue` is its only projection.
                        // swift-linter:disable:next chained rawvalue access
                        // REASON: no typed byte accessor exposed by `RFC_2046.BodyPart.Content`; `.rawValue` is its only projection.
                        content: part.content.rawValue.map(\.underlying)
                    )
                } catch {
                    // File's only failure is an empty field name (§4.2).
                    throw .missingFieldName
                }
                files.append(file)
            } else {
                // RFC 7578 §5.1: per-part charset parameter wins, then the
                // "_charset_" default, then UTF-8.
                let charset =
                    part.headers.contentType?.charset
                    ?? defaultCharset
                    ?? .utf8
                guard let value = Self.text(part.content.rawValue, charset: charset)
                else {
                    if Self.isSupported(charset) {
                        throw .invalidTextContent(fieldName: name)
                    } else {
                        throw .unsupportedCharset(charset.rawValue)
                    }
                }
                let field: RFC_7578.Form.Data.Field
                do throws(RFC_7578.Form.Data.Error) {
                    field = try RFC_7578.Form.Data.Field(name: name, value: value)
                } catch {
                    // Field's only failure is an empty name (§4.2).
                    throw .missingFieldName
                }
                fields.append(field)
            }
        }

        self.init(fields: fields, files: files)
    }
}

// MARK: - Named Projection Accessors

extension RFC_7578.Form.Data.Decoded {
    /// The value of the first text field with the given name, if any
    public subscript(_ name: String) -> String? {
        fields.first(where: { $0.name == name })?.value
    }

    /// All text fields with the given name, in part order
    public func fields(named name: String) -> [RFC_7578.Form.Data.Field] {
        fields.filter { $0.name == name }
    }

    /// The first file whose field name matches, if any
    public func file(named name: String) -> RFC_7578.Form.Data.File? {
        files.first(where: { $0.fieldName == name })
    }

    /// All files whose field name matches, in part order
    ///
    /// RFC 7578 §4.3: multiple files for one form field are supplied as
    /// multiple parts sharing a field name.
    public func files(named name: String) -> [RFC_7578.Form.Data.File] {
        files.filter { $0.fieldName == name }
    }
}

// MARK: - RFC 7578 §4.2 Disposition Projection

extension RFC_7578.Form.Data.Decoded {
    /// Extracts the mandatory form-data disposition of a part (RFC 7578 §4.2)
    private static func disposition(
        of part: RFC_2046.BodyPart
    ) throws(Error) -> (name: String, filename: RFC_2183.Filename?) {
        guard let disposition = part.headers.contentDisposition else {
            throw .missingContentDisposition
        }
        guard disposition.type == RFC_2183.DispositionType.formData else {
            // swift-linter:disable:next raw value access
            // REASON: no typed accessor exposed by `RFC_2183.DispositionType`; `.rawValue` is its only projection, needed here for the error payload.
            throw .invalidDispositionType(disposition.type.rawValue)
        }
        guard let name = disposition.name, !name.isEmpty else {
            throw .missingFieldName
        }
        return (name, disposition.filename)
    }
}

// MARK: - RFC 7578 §5.1 Charset Handling

extension RFC_7578.Form.Data.Decoded {
    /// The name of the default-charset field (RFC 7578 §5.1.1)
    private static let charsetFieldName = "_charset_"

    /// Finds the default charset declared by a `_charset_` field, if any
    /// (RFC 7578 §5.1.1)
    ///
    /// The `_charset_` field's own content is a charset label and is always
    /// ASCII-compatible, so it is read as UTF-8.
    private static func defaultCharset(
        of parts: [RFC_2046.BodyPart]
    ) throws(Error) -> RFC_2045.Charset? {
        for part in parts {
            guard
                let disposition = part.headers.contentDisposition,
                disposition.type == RFC_2183.DispositionType.formData,
                disposition.name == charsetFieldName,
                disposition.filename == nil
            else {
                continue
            }
            // swift-linter:disable:next raw value access
            // REASON: no typed byte accessor exposed by `RFC_2046.BodyPart.Content`; `.rawValue` is its only projection.
            guard let label = text(part.content.rawValue, charset: .utf8) else {
                throw .invalidTextContent(fieldName: charsetFieldName)
            }
            return RFC_2045.Charset(label)
        }
        return nil
    }

    /// Whether this implementation can decode text in the given charset
    private static func isSupported(_ charset: RFC_2045.Charset) -> Bool {
        // swift-linter:disable:next raw value access
        // REASON: no typed accessor exposed by `RFC_2045.Charset`; `.rawValue` is its only projection.
        // swift-linter:disable:next chained rawvalue access
        // REASON: no typed accessor exposed by `RFC_2045.Charset`; `.rawValue` is its only projection.
        switch charset.rawValue.uppercased() {
        case "UTF-8", "US-ASCII", "ASCII", "ISO-8859-1", "LATIN1",
            "UTF-16", "UTF-16BE", "UTF-16LE":
            return true

        default:
            return false
        }
    }

    /// Decodes content bytes as text in the given charset
    ///
    /// Supported charsets (Foundation-free): UTF-8, US-ASCII, ISO-8859-1,
    /// UTF-16 (BOM-sensitive, default big-endian per RFC 2781), UTF-16BE,
    /// UTF-16LE.
    ///
    /// - Returns: The decoded text, or `nil` if the charset is unsupported or
    ///   the bytes are not valid in that charset
    private static func text(
        _ bytes: [Byte],
        charset: RFC_2045.Charset
    ) -> String? {
        let octets = bytes.map(\.underlying)
        // swift-linter:disable:next raw value access
        // REASON: no typed accessor exposed by `RFC_2045.Charset`; `.rawValue` is its only projection.
        // swift-linter:disable:next chained rawvalue access
        // REASON: no typed accessor exposed by `RFC_2045.Charset`; `.rawValue` is its only projection.
        switch charset.rawValue.uppercased() {
        case "UTF-8":
            return String(validating: octets, as: UTF8.self)

        case "US-ASCII", "ASCII":
            guard octets.allSatisfy({ $0 < 0x80 }) else { return nil }
            return String(validating: octets, as: UTF8.self)

        case "ISO-8859-1", "LATIN1":
            // ISO-8859-1 maps byte values directly to U+0000...U+00FF.
            return String(
                String.UnicodeScalarView(
                    octets.lazy.compactMap { Unicode.Scalar(UInt32($0)) }
                )
            )

        case "UTF-16":
            // RFC 2781 §4.3: honor a BOM when present, else big-endian.
            if octets.count >= 2, octets[0] == 0xFF, octets[1] == 0xFE {
                return utf16Text(octets.dropFirst(2), bigEndian: false)
            }
            if octets.count >= 2, octets[0] == 0xFE, octets[1] == 0xFF {
                return utf16Text(octets.dropFirst(2), bigEndian: true)
            }
            return utf16Text(octets[...], bigEndian: true)

        case "UTF-16BE":
            return utf16Text(octets[...], bigEndian: true)

        case "UTF-16LE":
            return utf16Text(octets[...], bigEndian: false)

        default:
            return nil
        }
    }

    /// Decodes UTF-16 code units from octets with the given byte order
    private static func utf16Text(
        _ octets: ArraySlice<UInt8>,
        bigEndian: Bool
    ) -> String? {
        guard octets.count.isMultiple(of: 2) else { return nil }
        var codeUnits: [UInt16] = []
        codeUnits.reserveCapacity(octets.count / 2)
        var index = octets.startIndex
        while index < octets.endIndex {
            let first = UInt16(octets[index])
            let second = UInt16(octets[octets.index(after: index)])
            codeUnits.append(
                bigEndian ? (first << 8) | second : (second << 8) | first
            )
            index = octets.index(index, offsetBy: 2)
        }
        return String(validating: codeUnits, as: UTF16.self)
    }
}
