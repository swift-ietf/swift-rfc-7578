extension RFC_7578.Form.Data {

    public struct Field: Hashable, Sendable, Codable {

        public let name: String

        public let value: String

        public init(
            name: String,
            value: String
        ) throws(RFC_7578.Form.Data.Error) {
            guard !name.isEmpty else {
                throw RFC_7578.Form.Data.Error.emptyFieldName
            }

            self.name = name
            self.value = value
        }
    }
}
