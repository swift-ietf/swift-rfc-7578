public import RFC_2045
public import RFC_2183

extension RFC_7578.Form.Data {

    public struct File: Hashable, Sendable, Codable {

        public let fieldName: String

        public let filename: RFC_2183.Filename

        public let contentType: RFC_2045.ContentType?

        public let content: [UInt8]

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
