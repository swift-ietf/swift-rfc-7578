extension RFC_7578.Form.Data {
    /// A decoded text form field from a multipart/form-data body
    ///
    /// RFC 7578 Section 4.2: each part MUST have a Content-Disposition header
    /// of type "form-data" carrying a "name" parameter; parts without a
    /// "filename" parameter are text fields.
    ///
    /// The `value` is the part's content decoded to text per the charset rules
    /// of RFC 7578 Section 5.1 (Content-Type charset parameter, else the
    /// `_charset_` field's declared default, else UTF-8).
    ///
    /// ## Example
    ///
    /// ```swift
    /// let field = try RFC_7578.Form.Data.Field(name: "username", value: "john_doe")
    /// ```
    public struct Field: Hashable, Sendable, Codable {
        /// The form field name (the Content-Disposition "name" parameter)
        ///
        /// RFC 7578 Section 4.2 requires this parameter for all form-data parts.
        public let name: String

        /// The decoded text value of the field
        public let value: String

        /// Creates a decoded text form field
        ///
        /// - Parameters:
        ///   - name: Form field name. Must not be empty.
        ///   - value: Decoded text value.
        ///
        /// - Throws: `RFC_7578.Form.Data.Error.emptyFieldName` if name is empty
        public init(
            name: String,
            value: String
        ) throws(RFC_7578.Form.Data.Error) {
            guard !name.isEmpty else {
                throw RFC_7578.Form.Data.Error.emptyFieldName
            }

            self.name = name
            self.value = value
        }
    }
}
