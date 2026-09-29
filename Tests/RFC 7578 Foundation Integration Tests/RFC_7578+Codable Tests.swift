import Foundation
import RFC_2045
import RFC_2183
import RFC_7578
import RFC_7578_Foundation_Integration
import Testing

@Suite
struct `RFC_7578+Codable Tests` {

    @Test
    func `a field codes as its name and value`() throws {
        let field = try RFC_7578.Form.Data.Field(name: "username", value: "john_doe")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(field)

        #expect(
            String(decoding: encoded, as: UTF8.self)
                == #"{"name":"username","value":"john_doe"}"#
        )
        #expect(try JSONDecoder().decode(RFC_7578.Form.Data.Field.self, from: encoded) == field)
    }

    @Test
    func `a decoded form round-trips through JSON with its files`() throws {
        let decoded = RFC_7578.Form.Data.Decoded(
            fields: [try RFC_7578.Form.Data.Field(name: "username", value: "john_doe")],
            files: [
                try RFC_7578.Form.Data.File(
                    fieldName: "avatar",
                    filename: try RFC_2183.Filename("photo.jpg"),
                    contentType: try RFC_2045.ContentType("image/jpeg"),
                    content: [0xFF, 0xD8, 0xFF, 0xE0]
                )
            ]
        )

        let encoded = try JSONEncoder().encode(decoded)

        #expect(
            try JSONDecoder().decode(RFC_7578.Form.Data.Decoded.self, from: encoded) == decoded
        )
    }

    @Test
    func `a field with an empty name fails to decode`() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                RFC_7578.Form.Data.Field.self,
                from: Data(#"{"name":"","value":"x"}"#.utf8)
            )
        }
    }

    @Test
    func `a file with an invalid filename fails to decode`() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                RFC_7578.Form.Data.File.self,
                from: Data(#"{"fieldName":"avatar","filename":"../x","content":[]}"#.utf8)
            )
        }
    }
}
