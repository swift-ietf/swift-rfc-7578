public import RFC_2183

extension RFC_7578.Form {
    public enum Data {}
}

extension RFC_7578.Form.Data {

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
