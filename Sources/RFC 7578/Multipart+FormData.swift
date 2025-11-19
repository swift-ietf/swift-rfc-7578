public import RFC_2045
public import RFC_2046
public import RFC_2183

// MARK: - RFC 7578: Multipart/Form-Data

extension RFC_2046.Multipart.Subtype {
    /// Form data with file uploads
    ///
    /// Used in HTTP POST requests with file uploads.
    /// Each part has a `Content-Disposition: form-data` header
    /// with the form field name.
    ///
    /// **RFC 7578** - Returning Values from Forms: multipart/form-data
    ///
    /// ## Example
    ///
    /// ```swift
    /// let formData = try RFC_2046.Multipart.formData(
    ///     fields: ["username": "john_doe"],
    ///     files: [...]
    /// )
    /// ```
    public static let formData = RFC_2046.Multipart.Subtype(rawValue: "form-data")
}

extension RFC_2046.Multipart {
    /// Creates a multipart/form-data message
    ///
    /// Used for HTTP POST requests with file uploads.
    /// Each part should have a Content-Disposition header with the form field name.
    ///
    /// **RFC 7578** - Returning Values from Forms: multipart/form-data
    ///
    /// ## Example
    ///
    /// ```swift
    /// let formData = try RFC_2046.Multipart.formData(
    ///     fields: [
    ///         "username": "john_doe",
    ///         "email": "john@example.com"
    ///     ],
    ///     files: [
    ///         try RFC_7578.Form.Data.File(
    ///             fieldName: "avatar",
    ///             filename: "photo.jpg",
    ///             contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
    ///             content: imageData
    ///         )
    ///     ]
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - fields: Text form fields
    ///   - files: File upload parts (optional)
    ///   - boundary: Custom boundary (auto-generated if nil)
    /// - Throws: `RFC_2046.Multipart.Error` if validation fails
    public static func formData(
        fields: [String: String],
        files: [RFC_7578.Form.Data.File] = [],
        boundary: String? = nil
    ) throws -> Self {
        var parts: [RFC_2046.BodyPart] = []

        // Add text fields
        for (name, value) in fields.sorted(by: { $0.key < $1.key }) {
            parts.append(
                RFC_2046.BodyPart(
                    headers: .formDataTextField(name: name),
                    text: value
                )
            )
        }

        // Add file uploads
        for file in files {
            // Note: Content-Transfer-Encoding not added per RFC 7578 §4.7
            // HTTP supports binary data natively
            parts.append(
                RFC_2046.BodyPart(
                    headers: .formDataFile(
                        name: file.fieldName,
                        filename: file.filename,
                        contentType: file.contentType
                    ),
                    content: file.content
                )
            )
        }

        return try Self(
            subtype: .formData,
            parts: parts,
            boundary: boundary
        )
    }

    /// Escapes Content-Disposition field value per RFC 2183/RFC 2231
    ///
    /// - Parameters:
    ///   - name: Form field name
    ///   - filename: Optional filename
    /// - Returns: Complete Content-Disposition header value for form-data
    ///
    /// - Deprecated: Use `RFC_2183.ContentDisposition.formData(name:filename:).headerValue` instead
    @available(*, deprecated, message: "Use RFC_2183.ContentDisposition.formData(name:filename:).headerValue instead")
    public static func escapeContentDisposition(name: String, filename: RFC_2183.Filename? = nil) -> String {
        RFC_2183.ContentDisposition.formData(name: name, filename: filename).headerValue
    }
}

// MARK: - Convenience Accessor

extension RFC_7578.Form.Data {
    /// Escapes Content-Disposition field value per RFC 2183/RFC 2231
    ///
    /// - Parameters:
    ///   - name: Form field name
    ///   - filename: Optional filename
    /// - Returns: Escaped Content-Disposition header value
    ///
    /// - Deprecated: Use `RFC_2183.ContentDisposition.formData(name:filename:).headerValue` instead
    @available(*, deprecated, message: "Use RFC_2183.ContentDisposition.formData(name:filename:).headerValue instead")
    public static func escapeContentDisposition(name: String, filename: RFC_2183.Filename? = nil) -> String {
        RFC_2183.ContentDisposition.formData(name: name, filename: filename).headerValue
    }
}

// MARK: - RFC 7578 Namespace

public enum RFC_7578 {}

extension RFC_7578 {
    public enum Form {}
}

extension RFC_7578.Form {
    public enum Data {}
}

extension RFC_7578.Form.Data {
    /// Errors that can occur when working with form-data
    public enum Error: Swift.Error, Hashable, Sendable {
        case emptyFieldName
    }
}

// MARK: - CustomStringConvertible Conformance

extension RFC_7578.Form.Data.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyFieldName:
            return "Form field name must not be empty (RFC 7578)"
        }
    }
}

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
        ) throws {
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

// MARK: - Form Field Extraction

extension RFC_2046.Multipart {
    /// Extracts form field values from multipart/form-data
    ///
    /// Parses Content-Disposition headers to extract field names and values
    /// per RFC 7578 specification.
    ///
    /// - Returns: Dictionary mapping field names to their text values
    /// - Note: Only extracts text fields, ignores file uploads
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let multipart = try RFC_2046.Multipart.parse(string, boundary: "---boundary")
    /// let fields = multipart.extractFormFields()
    /// // fields = ["name": "value", ...]
    /// ```
    public func extractFormFields() -> [String: String] {
        var fields: [String: String] = [:]

        for part in parts {
            // Use typed Content-Disposition header
            guard let disposition = part.typedHeaders.contentDisposition,
                  disposition.type == .formData,
                  let fieldName = disposition.name,
                  let textContent = part.textContent else {
                continue
            }

            // Skip file uploads (have filename parameter)
            if disposition.filename != nil {
                continue
            }

            fields[fieldName] = textContent
        }

        return fields
    }
}
