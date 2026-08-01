extension RFC_7578.Form.Data {
    /// Errors that can occur when working with form-data
    public enum Error: Swift.Error, Hashable, Sendable {
        case emptyFieldName
    }
}

// MARK: - CustomStringConvertible Conformance

extension RFC_7578.Form.Data.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyFieldName:
            return "Form field name must not be empty (RFC 7578)"
        }
    }
}
