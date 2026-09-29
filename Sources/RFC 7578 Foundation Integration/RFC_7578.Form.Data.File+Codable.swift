public import RFC_7578
import RFC_2045
import RFC_2045_Foundation_Integration
import RFC_2183
import RFC_2183_Foundation_Integration

extension RFC_7578.Form.Data.File: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case fieldName
        case filename
        case contentType
        case content
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fieldName = try container.decode(String.self, forKey: .fieldName)
        let filenameString = try container.decode(String.self, forKey: .filename)
        let filename: RFC_2183.Filename
        do throws(RFC_2183.Filename.Error) {
            filename = try RFC_2183.Filename(filenameString)
        } catch {
            throw DecodingError.dataCorruptedError(
                forKey: .filename,
                in: container,
                debugDescription: String(describing: error)
            )
        }
        let contentType = try container.decodeIfPresent(
            RFC_2045.ContentType.self,
            forKey: .contentType
        )
        let content = try container.decode([UInt8].self, forKey: .content)

        do throws(RFC_7578.Form.Data.Error) {
            try self.init(
                fieldName: fieldName,
                filename: filename,
                contentType: contentType,
                content: content
            )
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: String(describing: error)
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fieldName, forKey: .fieldName)
        try container.encode(filename, forKey: .filename)
        try container.encodeIfPresent(contentType, forKey: .contentType)
        try container.encode(content, forKey: .content)
    }
}
