extension RFC_7578.Form.Data.Decoded {
    /// Errors that can occur when decoding a multipart body as form-data
    ///
    /// RFC 7578 Section 4.2 (Content-Disposition requirements) and
    /// Section 5.1 (charset of text parts).
    public enum Error: Swift.Error, Hashable, Sendable {
        /// A part lacks the mandatory Content-Disposition header (RFC 7578 §4.2)
        case missingContentDisposition

        /// A part's Content-Disposition type is not "form-data" (RFC 7578 §4.2)
        case invalidDispositionType(String)

        /// A part's Content-Disposition lacks the mandatory "name" parameter,
        /// or the parameter is empty (RFC 7578 §4.2)
        case missingFieldName

        /// A text part declares a charset this implementation cannot decode
        /// (RFC 7578 §5.1.1)
        case unsupportedCharset(String)

        /// A text part's content bytes are not valid in the effective charset
        /// (RFC 7578 §5.1)
        case invalidTextContent(fieldName: String)
    }
}

// MARK: - CustomStringConvertible Conformance

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
