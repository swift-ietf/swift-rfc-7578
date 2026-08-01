public import RFC_2183

extension RFC_7578.Form {
    public enum Data {}
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
