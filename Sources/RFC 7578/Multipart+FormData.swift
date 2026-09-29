import Byte
import RFC_2045
public import RFC_2046
import RFC_2183

extension RFC_2046.Multipart {

    public static func formData(
        fields: [String: String],
        files: [RFC_7578.Form.Data.File] = [],
        boundary: String? = nil
    ) throws(Error) -> Self {
        var parts: [RFC_2046.BodyPart] = []

        for (name, value) in fields.sorted(by: { $0.key < $1.key }) {
            var headers = RFC_2046.BodyPart.Headers()
            headers.contentDisposition = RFC_2183.ContentDisposition.formData(name: name)
            headers.contentType = .textPlainUTF8
            parts.append(
                RFC_2046.BodyPart(
                    headers: headers,
                    content: RFC_2046.BodyPart.Content(value.utf8.map(Byte.init(bitPattern:)))
                )
            )
        }

        for file in files {

            var headers = RFC_2046.BodyPart.Headers()
            headers.contentDisposition = RFC_2183.ContentDisposition.formData(
                name: file.fieldName,
                filename: file.filename
            )
            headers.contentType = file.contentType
            parts.append(
                RFC_2046.BodyPart(
                    headers: headers,
                    content: RFC_2046.BodyPart.Content(file.content.map(Byte.init(bitPattern:)))
                )
            )
        }

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

    public func formData() throws(RFC_7578.Form.Data.Decoded.Error)
        -> RFC_7578.Form.Data.Decoded
    {
        try RFC_7578.Form.Data.Decoded(self)
    }
}

extension RFC_2046.Multipart {

    public func extractFormFields() -> [String: String] {
        var fields: [String: String] = [:]

        for part in parts {

            guard let disposition = part.headers.contentDisposition,
                disposition.type == RFC_2183.DispositionType.formData,
                let fieldName = disposition.name
            else {
                continue
            }

            if disposition.filename != nil {
                continue
            }

            fields[fieldName] = part.content.description
        }

        return fields
    }
}
