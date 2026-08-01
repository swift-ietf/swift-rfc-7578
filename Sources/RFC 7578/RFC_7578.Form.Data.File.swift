public import RFC_2045
public import RFC_2183

extension RFC_7578.Form.Data {
    /// Represents a file upload in multipart/form-data
    ///
    /// RFC 7578: File uploads SHOULD include a filename parameter.
    /// For text form fields (no file), use the `fields` parameter in `.formData()` instead.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let imageData: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]  // JPEG header
    ///
    /// let file = try RFC_7578.Form.Data.File(
    ///     fieldName: "avatar",
    ///     filename: try RFC_2183.Filename("photo.jpg"),
    ///     contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
    ///     content: imageData
    /// )
    /// ```
    public struct File: Hashable, Sendable, Codable {
        /// The form field name (required per RFC 7578)
        ///
        /// This is the value of the "name" parameter in the Content-Disposition header.
        /// RFC 7578 Section 4.2 requires this parameter for all form-data parts.
        public let fieldName: String

        /// The filename (required for file uploads per RFC 7578)
        ///
        /// Uses RFC 2183's validated Filename type to prevent security issues
        /// like path traversal and control character injection.
        public let filename: RFC_2183.Filename

        /// The content type (optional but recommended for files)
        public let contentType: RFC_2045.ContentType?

        /// The file content (binary data)
        ///
        /// RFC 7578 Section 4.7: Content-Transfer-Encoding is deprecated for HTTP contexts.
        /// HTTP supports binary data natively, so no encoding is applied.
        public let content: [UInt8]

        /// Creates a form file upload
        ///
        /// - Parameters:
        ///   - fieldName: Form field name (e.g., "avatar"). Must not be empty.
        ///   - filename: Validated filename from RFC 2183
        ///   - contentType: MIME type (recommended, e.g., `image/jpeg`)
        ///   - content: File content (binary data, no encoding applied per RFC 7578 §4.7)
        ///
        /// - Throws: `RFC_7578.Form.Data.Error.emptyFieldName` if fieldName is empty
        ///
        /// - Note: RFC 7578 Section 4.7 states that Content-Transfer-Encoding is deprecated
        ///   for HTTP contexts because HTTP supports binary data natively.
        public init(
            fieldName: String,
            filename: RFC_2183.Filename,
            contentType: RFC_2045.ContentType? = nil,
            content: [UInt8]
        ) throws(RFC_7578.Form.Data.Error) {
            guard !fieldName.isEmpty else {
                throw RFC_7578.Form.Data.Error.emptyFieldName
            }

            self.fieldName = fieldName
            self.filename = filename
            self.contentType = contentType
            self.content = content
        }
    }
}
