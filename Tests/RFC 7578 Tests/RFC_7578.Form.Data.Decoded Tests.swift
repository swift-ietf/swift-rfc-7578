import RFC_2045
import RFC_2046
import RFC_2183
import Testing

@testable import RFC_7578

@Suite
struct `RFC_7578 Form Data Decoded Tests` {

    // MARK: - Helpers

    static func fieldPart(
        name: String,
        content: [UInt8],
        contentType: RFC_2045.ContentType? = nil
    ) -> RFC_2046.BodyPart {
        var headers = RFC_2046.BodyPart.Headers()
        headers.contentDisposition = RFC_2183.ContentDisposition.formData(name: name)
        headers.contentType = contentType
        return RFC_2046.BodyPart(
            headers: headers,
            content: RFC_2046.BodyPart.Content(content.map { Byte($0) })
        )
    }

    static func fieldPart(
        name: String,
        value: String,
        contentType: RFC_2045.ContentType? = nil
    ) -> RFC_2046.BodyPart {
        fieldPart(name: name, content: Array(value.utf8), contentType: contentType)
    }

    static func filePart(
        name: String,
        filename: String,
        contentType: RFC_2045.ContentType? = nil,
        content: [UInt8]
    ) throws -> RFC_2046.BodyPart {
        var headers = RFC_2046.BodyPart.Headers()
        headers.contentDisposition = RFC_2183.ContentDisposition.formData(
            name: name,
            filename: try RFC_2183.Filename(filename)
        )
        headers.contentType = contentType
        return RFC_2046.BodyPart(
            headers: headers,
            content: RFC_2046.BodyPart.Content(content.map { Byte($0) })
        )
    }

    // MARK: - Unit

    @Suite
    struct Unit {
        @Test
        func `Projects text parts to named fields`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(name: "username", value: "john_doe"),
                fieldPart(name: "email", value: "john@example.com"),
            ])

            #expect(decoded.fields.count == 2)
            #expect(decoded.files.isEmpty)
            #expect(decoded["username"] == "john_doe")
            #expect(decoded["email"] == "john@example.com")
        }

        @Test
        func `Projects parts with filename to files`() throws {
            let bytes: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
            let decoded = try RFC_7578.Form.Data.Decoded([
                try filePart(
                    name: "avatar",
                    filename: "photo.jpg",
                    contentType: try RFC_2045.ContentType("image/jpeg"),
                    content: bytes
                )
            ])

            #expect(decoded.fields.isEmpty)
            let file = try #require(decoded.file(named: "avatar"))
            #expect(file.fieldName == "avatar")
            #expect(String(file.filename) == "photo.jpg")
            #expect(file.contentType?.type == "image")
            #expect(file.contentType?.subtype == "jpeg")
            #expect(file.content == bytes)
        }

        @Test
        func `Preserves duplicate field names in part order`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(name: "tag", value: "swift"),
                fieldPart(name: "tag", value: "rfc7578"),
            ])

            #expect(decoded.fields(named: "tag").map(\.value) == ["swift", "rfc7578"])
            #expect(decoded["tag"] == "swift")
        }

        @Test
        func `Projects multiple files sharing a field name`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                try filePart(name: "attachments", filename: "a.txt", content: [0x61]),
                try filePart(name: "attachments", filename: "b.txt", content: [0x62]),
            ])

            let files = decoded.files(named: "attachments")
            #expect(files.count == 2)
            #expect(files.map { String($0.filename) } == ["a.txt", "b.txt"])
        }

        @Test
        func `Decodes text per explicit ISO-8859-1 charset parameter`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(
                    name: "city",
                    content: [0x4C, 0x69, 0xE8, 0x67, 0x65],  // "Liège" in Latin-1
                    contentType: try RFC_2045.ContentType("text/plain; charset=ISO-8859-1")
                )
            ])

            #expect(decoded["city"] == "Liège")
        }

        @Test
        func `Decodes text per explicit UTF-16BE charset parameter`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(
                    name: "greeting",
                    content: [0x00, 0x48, 0x00, 0x69],  // "Hi" UTF-16BE
                    contentType: try RFC_2045.ContentType("text/plain; charset=UTF-16BE")
                )
            ])

            #expect(decoded["greeting"] == "Hi")
        }

        @Test
        func `Applies the _charset_ field as default charset per section 5-1-1`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(name: "_charset_", value: "ISO-8859-1"),
                fieldPart(name: "city", content: [0xE9]),  // "é" in Latin-1
            ])

            #expect(decoded["city"] == "é")
            #expect(decoded["_charset_"] == "ISO-8859-1")
        }

        @Test
        func `Explicit charset parameter overrides the _charset_ default`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(name: "_charset_", value: "UTF-16BE"),
                fieldPart(
                    name: "name",
                    value: "plain",
                    contentType: try RFC_2045.ContentType("text/plain; charset=UTF-8")
                ),
            ])

            #expect(decoded["name"] == "plain")
        }

        @Test
        func `Defaults to UTF-8 when no charset is declared`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(name: "emoji", value: "héllo ✓")
            ])

            #expect(decoded["emoji"] == "héllo ✓")
        }

        @Test
        func `Multipart formData decode entry projects fields and files`() throws {
            let multipart = try RFC_2046.Multipart.formData(
                fields: ["username": "john_doe"]
            )

            let decoded = try multipart.formData()
            #expect(decoded["username"] == "john_doe")
        }
    }

    // MARK: - Edge Case

    @Suite
    struct `Edge Case` {
        @Test
        func `Part without Content-Disposition throws`() throws {
            let part = RFC_2046.BodyPart(
                headers: RFC_2046.BodyPart.Headers(),
                content: RFC_2046.BodyPart.Content("orphan")
            )

            #expect(throws: RFC_7578.Form.Data.Decoded.Error.missingContentDisposition) {
                try RFC_7578.Form.Data.Decoded([part])
            }
        }

        @Test
        func `Part with non-form-data disposition throws`() throws {
            var headers = RFC_2046.BodyPart.Headers()
            headers.contentDisposition = RFC_2183.ContentDisposition.attachment(
                filename: try RFC_2183.Filename("a.txt")
            )
            let part = RFC_2046.BodyPart(
                headers: headers,
                content: RFC_2046.BodyPart.Content("a")
            )

            #expect(
                throws: RFC_7578.Form.Data.Decoded.Error.invalidDispositionType("attachment")
            ) {
                try RFC_7578.Form.Data.Decoded([part])
            }
        }

        @Test
        func `Part without a name parameter throws`() throws {
            var headers = RFC_2046.BodyPart.Headers()
            headers.contentDisposition = try RFC_2183.ContentDisposition("form-data")
            let part = RFC_2046.BodyPart(
                headers: headers,
                content: RFC_2046.BodyPart.Content("nameless")
            )

            #expect(throws: RFC_7578.Form.Data.Decoded.Error.missingFieldName) {
                try RFC_7578.Form.Data.Decoded([part])
            }
        }

        @Test
        func `Invalid UTF-8 content throws invalidTextContent`() throws {
            let part = fieldPart(name: "broken", content: [0xC3, 0x28])  // invalid UTF-8

            #expect(
                throws: RFC_7578.Form.Data.Decoded.Error.invalidTextContent(
                    fieldName: "broken"
                )
            ) {
                try RFC_7578.Form.Data.Decoded([part])
            }
        }

        @Test
        func `Non-ASCII bytes under US-ASCII charset throw invalidTextContent`() throws {
            let part = fieldPart(
                name: "ascii",
                content: [0xE9],
                contentType: try RFC_2045.ContentType("text/plain; charset=US-ASCII")
            )

            #expect(
                throws: RFC_7578.Form.Data.Decoded.Error.invalidTextContent(
                    fieldName: "ascii"
                )
            ) {
                try RFC_7578.Form.Data.Decoded([part])
            }
        }

        @Test
        func `Unsupported charset throws unsupportedCharset`() throws {
            let part = fieldPart(
                name: "legacy",
                content: [0x61],
                contentType: try RFC_2045.ContentType("text/plain; charset=KOI8-R")
            )

            #expect(
                throws: RFC_7578.Form.Data.Decoded.Error.unsupportedCharset("KOI8-R")
            ) {
                try RFC_7578.Form.Data.Decoded([part])
            }
        }

        @Test
        func `Unsupported _charset_ default throws when applied`() throws {
            #expect(
                throws: RFC_7578.Form.Data.Decoded.Error.unsupportedCharset("EBCDIC")
            ) {
                try RFC_7578.Form.Data.Decoded([
                    fieldPart(name: "_charset_", value: "EBCDIC"),
                    fieldPart(name: "field", content: [0x61]),
                ])
            }
        }

        @Test
        func `UTF-16 honors a little-endian BOM`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(
                    name: "bom",
                    content: [0xFF, 0xFE, 0x48, 0x00, 0x69, 0x00],  // BOM + "Hi" LE
                    contentType: try RFC_2045.ContentType("text/plain; charset=UTF-16")
                )
            ])

            #expect(decoded["bom"] == "Hi")
        }

        @Test
        func `UTF-16 without BOM defaults to big-endian`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(
                    name: "nobom",
                    content: [0x00, 0x48, 0x00, 0x69],  // "Hi" BE
                    contentType: try RFC_2045.ContentType("text/plain; charset=UTF-16")
                )
            ])

            #expect(decoded["nobom"] == "Hi")
        }

        @Test
        func `Odd-length UTF-16 content throws invalidTextContent`() throws {
            let part = fieldPart(
                name: "odd",
                content: [0x00, 0x48, 0x00],
                contentType: try RFC_2045.ContentType("text/plain; charset=UTF-16BE")
            )

            #expect(
                throws: RFC_7578.Form.Data.Decoded.Error.invalidTextContent(fieldName: "odd")
            ) {
                try RFC_7578.Form.Data.Decoded([part])
            }
        }

        @Test
        func `Empty part list decodes to empty projection`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([])
            #expect(decoded.fields.isEmpty)
            #expect(decoded.files.isEmpty)
        }

        @Test
        func `Empty field content decodes to empty string`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(name: "empty", content: [])
            ])
            #expect(decoded["empty"]?.isEmpty == true)
        }

        @Test
        func `Missing field or file lookups return nil`() throws {
            let decoded = try RFC_7578.Form.Data.Decoded([
                fieldPart(name: "present", value: "yes")
            ])
            #expect(decoded["absent"] == nil)
            #expect(decoded.file(named: "absent") == nil)
            #expect(decoded.fields(named: "absent").isEmpty)
            #expect(decoded.files(named: "absent").isEmpty)
        }
    }

    // MARK: - Integration

    @Suite
    struct Integration {
        @Test
        func `Encode-decode round-trip preserves fields and files`() throws {
            let imageBytes: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
            let file = try RFC_7578.Form.Data.File(
                fieldName: "avatar",
                filename: try RFC_2183.Filename("photo.jpg"),
                contentType: try RFC_2045.ContentType("image/jpeg"),
                content: imageBytes
            )

            let multipart = try RFC_2046.Multipart.formData(
                fields: [
                    "username": "john_doe",
                    "email": "john@example.com",
                ],
                files: [file]
            )

            let decoded = try multipart.formData()

            #expect(decoded["username"] == "john_doe")
            #expect(decoded["email"] == "john@example.com")
            #expect(decoded.file(named: "avatar") == file)
        }

        @Test
        func `Decoded projection replaces JSON-round-trip extraction (B2-09)`() throws {
            // The retired downstream path projected fields via a
            // JSONSerialization/JSONDecoder round-trip; the typed projection
            // must yield the same field mapping directly from parts.
            let multipart = try RFC_2046.Multipart.formData(
                fields: ["a": "1", "b": "two", "c": "✓"]
            )

            let decoded = try multipart.formData()
            let mapping = Dictionary(
                decoded.fields.map { ($0.name, $0.value) },
                uniquingKeysWith: { first, _ in first }
            )
            #expect(mapping == ["a": "1", "b": "two", "c": "✓"])
            #expect(mapping == multipart.extractFormFields())
        }
    }
}
