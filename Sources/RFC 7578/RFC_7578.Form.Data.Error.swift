extension RFC_7578.Form.Data {

    public enum Error: Swift.Error, Hashable, Sendable {
        case emptyFieldName
    }
}

extension RFC_7578.Form.Data.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyFieldName:
            return "Form field name must not be empty (RFC 7578)"
        }
    }
}
