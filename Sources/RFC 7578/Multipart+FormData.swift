import RFC_2045
public import RFC_2046
public import RFC_2183

// MARK: - RFC 7578: Multipart/Form-Data
// Note: .formData subtype is defined in RFC_2046.Multipart.Subtype

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
    ) throws(Error) -> Self {
        var parts: [RFC_2046.BodyPart] = []

        // Add text fields
        for (name, value) in fields.sorted(by: { $0.key < $1.key }) {
            var headers = RFC_2046.BodyPart.Headers()
            headers.contentDisposition = RFC_2183.ContentDisposition.formData(name: name)
            headers.contentType = .textPlainUTF8
            parts.append(
                RFC_2046.BodyPart(
                    headers: headers,
                    content: RFC_2046.BodyPart.Content(Array(value.utf8).map { Byte($0) })
                )
            )
        }

        // Add file uploads
        for file in files {
            // Note: Content-Transfer-Encoding not added per RFC 7578 §4.7
            // HTTP supports binary data natively
            var headers = RFC_2046.BodyPart.Headers()
            headers.contentDisposition = RFC_2183.ContentDisposition.formData(
                name: file.fieldName,
                filename: file.filename
            )
            headers.contentType = file.contentType
            parts.append(
                RFC_2046.BodyPart(
                    headers: headers,
                    content: RFC_2046.BodyPart.Content(file.content.map { Byte($0) })
                )
            )
        }

        // Generate boundary if not provided
        let effectiveBoundaryString =
            boundary
            ?? "----FormData\(parts.count)\(parts.first?.headers.contentType?.type ?? "data")"
        let effectiveBoundary: RFC_2046.Boundary
        do throws(RFC_2046.Boundary.Error) {
            effectiveBoundary = try RFC_2046.Boundary(effectiveBoundaryString)
        } catch {
            throw .invalidFormat("\(error)")
        }

        return try Self(
            subtype: .formData,
            parts: parts,
            boundary: effectiveBoundary
        )
    }

    /// Decodes this multipart body as multipart/form-data
    ///
    /// The decode counterpart of `formData(fields:files:boundary:)`: projects
    /// the parsed parts into named text fields and files per RFC 7578 §4.2,
    /// applying the §5.1 charset rules to text parts.
    ///
    /// **RFC 7578** - Returning Values from Forms: multipart/form-data
    ///
    /// ## Example
    ///
    /// ```swift
    /// let decoded = try multipart.formData()
    /// let username = decoded["username"]           // String?
    /// let avatar = decoded.file(named: "avatar")   // RFC_7578.Form.Data.File?
    /// ```
    ///
    /// - Returns: The decoded field/file projection
    /// - Throws: `RFC_7578.Form.Data.Decoded.Error` if a part violates
    ///   RFC 7578 §4.2 or its text content cannot be decoded per §5.1
    public func formData() throws(RFC_7578.Form.Data.Decoded.Error)
        -> RFC_7578.Form.Data.Decoded
    {
        try RFC_7578.Form.Data.Decoded(self)
    }

    /// Escapes Content-Disposition field value per RFC 2183/RFC 2231
    ///
    /// - Parameters:
    ///   - name: Form field name
    ///   - filename: Optional filename
    /// - Returns: Complete Content-Disposition header value for form-data
    ///
    /// - Deprecated: Use `String(RFC_2183.ContentDisposition.formData(name:filename:))` instead
    @available(
        *,
        deprecated,
        message: "Use String(RFC_2183.ContentDisposition.formData(name:filename:)) instead"
    )
    public static func escapeContentDisposition(
        name: String,
        filename: RFC_2183.Filename? = nil
    ) -> String {
        String(RFC_2183.ContentDisposition.formData(name: name, filename: filename))
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
            guard let disposition = part.headers.contentDisposition,
                disposition.type == RFC_2183.DispositionType.formData,
                let fieldName = disposition.name
            else {
                continue
            }

            // Skip file uploads (have filename parameter)
            if disposition.filename != nil {
                continue
            }

            // Get text content from raw bytes
            let textContent = String(part.content)
            fields[fieldName] = textContent
        }

        return fields
    }
}
