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
            headers.contentDisposition = RFC_2183.ContentDisposition.formData(name: try fieldName(name))
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
                name: try fieldName(file.fieldName),
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

        let effectiveBoundary: RFC_2046.Boundary
        if let boundary {
            do throws(RFC_2046.Boundary.Error) {
                effectiveBoundary = try RFC_2046.Boundary(boundary)
            } catch {
                throw .invalidFormat("\(error)")
            }
            guard !occurs(effectiveBoundary, in: parts) else {
                throw .invalidFormat("boundary '\(boundary)' occurs in the content of a part")
            }
        } else {
            var candidate = RFC_2046.Boundary.random()
            while occurs(candidate, in: parts) {
                candidate = RFC_2046.Boundary.random()
            }
            effectiveBoundary = candidate
        }

        return try Self(
            subtype: .formData,
            parts: parts,
            boundary: effectiveBoundary
        )
    }

    private static func occurs(
        _ boundary: RFC_2046.Boundary,
        in parts: [RFC_2046.BodyPart]
    ) -> Bool {
        let delimiter = [Byte]("--\(boundary.rawValue)".utf8.map(Byte.init(bitPattern:)))
        return parts.contains { part in
            part.content.rawValue.firstRange(of: delimiter) != nil
        }
    }

    private static func fieldName(_ name: String) throws(Error) -> RFC_2183.ParameterValue {
        do throws(RFC_2183.ParameterValue.Error) {
            return try RFC_2183.ParameterValue(name)
        } catch {
            throw .invalidFormat("\(error)")
        }
    }

    public func formData() throws(RFC_7578.Form.Data.Decoded.Error)
        -> RFC_7578.Form.Data.Decoded
    {
        try RFC_7578.Form.Data.Decoded(self)
    }
}
