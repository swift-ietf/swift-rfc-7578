import Foundation
import RFC_2045
import RFC_2046
import Testing

@testable import RFC_7578

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("Example from source: Creating Form Data with Fields")
    func exampleCreatingFormDataWithFields() throws {
        // From Multipart+FormData.swift lines 19-23 and 39-42
        let formData = try RFC_2046.Multipart.formData(
            fields: [
                "username": "john_doe",
                "email": "john@example.com"
            ]
        )

        #expect(formData.subtype == .formData)
        #expect(formData.parts.count == 2)
    }

    @Test("Example from source: Creating Form Data with File Upload")
    func exampleCreatingFormDataWithFileUpload() throws {
        // From Multipart+FormData.swift lines 43-51
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])  // Mock JPEG header

        let file = try RFC_7578.Form.Data.File(
            fieldName: "avatar",
            filename: "photo.jpg",
            contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
            content: imageData
        )

        let formData = try RFC_2046.Multipart.formData(
            fields: ["username": "john_doe"],
            files: [file]
        )

        #expect(formData.parts.count == 2)  // 1 field + 1 file
        #expect(formData.subtype == .formData)
    }

    @Test("Validation: Empty Field Name Throws Error")
    func validationEmptyFieldNameThrowsError() throws {
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        #expect(throws: RFC_7578.Form.Data.Error.emptyFieldName) {
            try RFC_7578.Form.Data.File(
                fieldName: "",
                filename: "photo.jpg",
                contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
                content: imageData
            )
        }
    }

    @Test("Validation: Empty Filename Throws Error")
    func validationEmptyFilenameThrowsError() throws {
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        #expect(throws: RFC_7578.Form.Data.Error.emptyFilename) {
            try RFC_7578.Form.Data.File(
                fieldName: "avatar",
                filename: "",
                contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
                content: imageData
            )
        }
    }

    @Test("Content-Disposition Escaping: Special Characters in Names")
    func contentDispositionEscaping() throws {
        // Test that field names with quotes are properly escaped
        let formData = try RFC_2046.Multipart.formData(
            fields: ["field\"name": "value"]
        )

        let firstPart = formData.parts.first!
        let disposition = firstPart.headers["Content-Disposition"]!

        #expect(disposition.contains("field\\\"name"))
    }

    @Test("Multiple Files Upload")
    func multipleFilesUpload() throws {
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let textData = Data("test content".utf8)

        let imageFile = try RFC_7578.Form.Data.File(
            fieldName: "avatar",
            filename: "photo.jpg",
            contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
            content: imageData
        )

        let textFile = try RFC_7578.Form.Data.File(
            fieldName: "document",
            filename: "readme.txt",
            contentType: RFC_2045.ContentType(type: "text", subtype: "plain"),
            content: textData
        )

        let formData = try RFC_2046.Multipart.formData(
            fields: ["description": "My files"],
            files: [imageFile, textFile]
        )

        #expect(formData.parts.count == 3)  // 1 field + 2 files
    }
}
