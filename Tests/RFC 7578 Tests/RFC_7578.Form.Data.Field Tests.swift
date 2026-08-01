import RFC_2045
import RFC_2046
import RFC_2183
import Testing

@testable import RFC_7578

@Suite
struct `RFC_7578 Form Data Field Tests` {

    @Suite
    struct Unit {
        @Test
        func `Creates a field with name and value`() throws {
            let field = try RFC_7578.Form.Data.Field(name: "username", value: "john_doe")
            #expect(field.name == "username")
            #expect(field.value == "john_doe")
        }

        @Test
        func `Fields are equatable and hashable`() throws {
            let a = try RFC_7578.Form.Data.Field(name: "a", value: "1")
            let b = try RFC_7578.Form.Data.Field(name: "a", value: "1")
            #expect(a == b)
            #expect(Set([a, b]).count == 1)
        }
    }

    @Suite
    struct `Edge Case` {
        @Test
        func `Empty field name throws`() {
            #expect(throws: RFC_7578.Form.Data.Error.emptyFieldName) {
                try RFC_7578.Form.Data.Field(name: "", value: "value")
            }
        }

        @Test
        func `Empty value is allowed`() throws {
            let field = try RFC_7578.Form.Data.Field(name: "empty", value: "")
            #expect(field.value.isEmpty)
        }
    }

    @Suite
    struct Integration {}
}
