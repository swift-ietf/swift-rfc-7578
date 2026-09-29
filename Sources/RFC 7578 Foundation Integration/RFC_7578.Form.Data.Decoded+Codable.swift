public import RFC_7578

extension RFC_7578.Form.Data.Decoded: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case fields
        case files
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            fields: try container.decode([RFC_7578.Form.Data.Field].self, forKey: .fields),
            files: try container.decode([RFC_7578.Form.Data.File].self, forKey: .files)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fields, forKey: .fields)
        try container.encode(files, forKey: .files)
    }
}
