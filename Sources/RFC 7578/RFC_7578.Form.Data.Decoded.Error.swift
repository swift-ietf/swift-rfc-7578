extension RFC_7578.Form.Data.Decoded {

    public enum Error: Swift.Error, Hashable, Sendable {

        case missingContentDisposition

        case invalidDispositionType(String)

        case missingFieldName

        case unsupportedCharset(String)

        case invalidTextContent(fieldName: String)
    }
}

extension RFC_7578.Form.Data.Decoded.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .missingContentDisposition:
            return
                "Form-data part must have a Content-Disposition header (RFC 7578 §4.2)"

        case .invalidDispositionType(let type):
            return
                "Form-data part must have Content-Disposition type \"form-data\", got \"\(type)\" (RFC 7578 §4.2)"

        case .missingFieldName:
            return
                "Form-data part must have a non-empty \"name\" parameter in its Content-Disposition header (RFC 7578 §4.2)"

        case .unsupportedCharset(let charset):
            return
                "Unsupported charset \"\(charset)\" for form-data text part (RFC 7578 §5.1.1)"

        case .invalidTextContent(let fieldName):
            return
                "Content of form field \"\(fieldName)\" is not valid text in its effective charset (RFC 7578 §5.1)"
        }
    }
}
