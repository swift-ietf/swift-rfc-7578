import RFC_2045
import RFC_2046
import RFC_2183
import Testing

@testable import RFC_7578

@Suite
struct `README Verification` {

    @Test
    func `Example from source: Creating Form Data with Fields`() throws {
        // From Multipart+FormData.swift lines 19-23 and 39-42
        let formData = try RFC_2046.Multipart.formData(
            fields: [
                "username": "john_doe",
                "email": "john@example.com",
            ]
        )

        #expect(formData.subtype == .formData)
        #expect(formData.parts.count == 2)
    }

    @Test
    func `Example from source: Creating Form Data with File Upload`() throws {
        // From Multipart+FormData.swift lines 43-51
        let imageData: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]  // Mock JPEG header

        let file = try RFC_7578.Form.Data.File(
            fieldName: "avatar",
            filename: try RFC_2183.Filename("photo.jpg"),
            contentType: try RFC_2045.ContentType("image/jpeg"),
            content: imageData
        )

        let formData = try RFC_2046.Multipart.formData(
            fields: ["username": "john_doe"],
            files: [file]
        )

        #expect(formData.parts.count == 2)  // 1 field + 1 file
        #expect(formData.subtype == .formData)
    }

    @Test
    func `Validation: Empty Field Name Throws Error`() throws {
        let imageData: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]

        #expect(throws: RFC_7578.Form.Data.Error.emptyFieldName) {
            try RFC_7578.Form.Data.File(
                fieldName: "",
                filename: try RFC_2183.Filename("photo.jpg"),
                contentType: try RFC_2045.ContentType("image/jpeg"),
                content: imageData
            )
        }
    }

    @Test
    func `Validation: Invalid Filename Throws Error`() throws {
        // RFC 2183 Filename validation should reject path traversal
        #expect(throws: RFC_2183.Filename.Error.self) {
            _ = try RFC_2183.Filename("../etc/passwd")
        }
    }

    @Test
    func `Content-Disposition Escaping: Special Characters in Names`() throws {
        // Test that field names with quotes are properly escaped
        let formData = try RFC_2046.Multipart.formData(
            fields: ["field\"name": "value"]
        )

        let firstPart = formData.parts.first!
        let disposition = firstPart.headers.contentDisposition!

        // Check the name contains the expected field name
        #expect(disposition.name == "field\"name")
    }

    @Test
    func `Multiple Files Upload`() throws {
        let imageData: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
        let textData: [UInt8] = Array("test content".utf8)

        let imageFile = try RFC_7578.Form.Data.File(
            fieldName: "avatar",
            filename: try RFC_2183.Filename("photo.jpg"),
            contentType: try RFC_2045.ContentType("image/jpeg"),
            content: imageData
        )

        let textFile = try RFC_7578.Form.Data.File(
            fieldName: "document",
            filename: try RFC_2183.Filename("readme.txt"),
            contentType: try RFC_2045.ContentType("text/plain"),
            content: textData
        )

        let formData = try RFC_2046.Multipart.formData(
            fields: ["description": "My files"],
            files: [imageFile, textFile]
        )

        #expect(formData.parts.count == 3)  // 1 field + 2 files
    }
}
