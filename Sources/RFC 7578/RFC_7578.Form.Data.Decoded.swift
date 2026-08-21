internal import RFC_2045
public import RFC_2046
internal import RFC_2183

extension RFC_7578.Form.Data {

    public struct Decoded: Hashable, Sendable, Codable {

        public let fields: [Field]

        public let files: [File]

        public init(fields: [Field], files: [File]) {
            self.fields = fields
            self.files = files
        }
    }
}

extension RFC_7578.Form.Data.Decoded {

    public init(_ multipart: RFC_2046.Multipart) throws(Error) {
        try self.init(multipart.parts)
    }

    public init(_ parts: [RFC_2046.BodyPart]) throws(Error) {

        let defaultCharset = try Self.defaultCharset(of: parts)

        var fields: [RFC_7578.Form.Data.Field] = []
        var files: [RFC_7578.Form.Data.File] = []

        for part in parts {
            let (name, filename) = try Self.disposition(of: part)

            if let filename {

                let file: RFC_7578.Form.Data.File
                do throws(RFC_7578.Form.Data.Error) {
                    file = try RFC_7578.Form.Data.File(
                        fieldName: name,
                        filename: filename,
                        contentType: part.headers.contentType,

                        content: part.content.rawValue.map(\.underlying)
                    )
                } catch {

                    throw .missingFieldName
                }
                files.append(file)
            } else {

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

                    throw .missingFieldName
                }
                fields.append(field)
            }
        }

        self.init(fields: fields, files: files)
    }
}

extension RFC_7578.Form.Data.Decoded {

    public subscript(_ name: String) -> String? {
        fields.first(where: { $0.name == name })?.value
    }

    public func fields(named name: String) -> [RFC_7578.Form.Data.Field] {
        fields.filter { $0.name == name }
    }

    public func file(named name: String) -> RFC_7578.Form.Data.File? {
        files.first(where: { $0.fieldName == name })
    }

    public func files(named name: String) -> [RFC_7578.Form.Data.File] {
        files.filter { $0.fieldName == name }
    }
}

extension RFC_7578.Form.Data.Decoded {

    private static func disposition(
        of part: RFC_2046.BodyPart
    ) throws(Error) -> (name: String, filename: RFC_2183.Filename?) {
        guard let disposition = part.headers.contentDisposition else {
            throw .missingContentDisposition
        }
        guard disposition.type == RFC_2183.DispositionType.formData else {

            throw .invalidDispositionType(disposition.type.rawValue)
        }
        guard let name = disposition.name, !name.isEmpty else {
            throw .missingFieldName
        }
        return (name, disposition.filename)
    }
}

extension RFC_7578.Form.Data.Decoded {

    private static let charsetFieldName = "_charset_"

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

            guard let label = text(part.content.rawValue, charset: .utf8) else {
                throw .invalidTextContent(fieldName: charsetFieldName)
            }
            return RFC_2045.Charset(label)
        }
        return nil
    }

    private static func isSupported(_ charset: RFC_2045.Charset) -> Bool {

        switch charset.rawValue.uppercased() {
        case "UTF-8", "US-ASCII", "ASCII", "ISO-8859-1", "LATIN1",
            "UTF-16", "UTF-16BE", "UTF-16LE":
            return true

        default:
            return false
        }
    }

    private static func text(
        _ bytes: [Byte],
        charset: RFC_2045.Charset
    ) -> String? {
        let octets = bytes.map(\.underlying)

        switch charset.rawValue.uppercased() {
        case "UTF-8":
            return String(validating: octets, as: UTF8.self)

        case "US-ASCII", "ASCII":
            guard octets.allSatisfy({ $0 < 0x80 }) else { return nil }
            return String(validating: octets, as: UTF8.self)

        case "ISO-8859-1", "LATIN1":

            return String(
                String.UnicodeScalarView(
                    octets.lazy.compactMap { Unicode.Scalar(UInt32($0)) }
                )
            )

        case "UTF-16":

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
