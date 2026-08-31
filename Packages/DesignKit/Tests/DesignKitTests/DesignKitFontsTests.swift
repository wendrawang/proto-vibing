import CoreText
import Testing
import UIKit

@testable import DesignKit

/// Registrasi font memodifikasi state CoreText milik seluruh proses, jadi suite
/// ini `.serialized` — tes paralel akan saling mendaftarkan font yang sama dan
/// membuat kode error CoreText tidak bisa ditebak.
@Suite("DesignKit font registration", .serialized)
struct DesignKitFontsTests {

    /// Font dummy yang di-bundle sekarang. Ganti saat font asli masuk.
    private let dummyFontName = "PlaygroundDummy-Regular"

    @Test("register() registers every bundled font")
    func registersEveryBundledFont() {
        let results = DesignKitFonts.register()

        #expect(results.count == DesignKitFonts.bundledFontNames.count)
        for result in results {
            #expect(result.isRegistered, "\(result.fontName) failed: \(result.failureReason ?? "-")")
            #expect(result.failureReason == nil)
        }
    }

    @Test("register() is idempotent — a second call still succeeds")
    func registerIsIdempotent() {
        DesignKitFonts.register()
        let secondRun = DesignKitFonts.register()

        // Panggilan kedua menghasilkan kCTFontManagerErrorAlreadyRegistered di
        // level CoreText — itu harus dibaca sebagai sukses, bukan kegagalan.
        for result in secondRun {
            #expect(result.isRegistered, "\(result.fontName) failed: \(result.failureReason ?? "-")")
        }
    }

    @Test("UIKit resolves the font after register()", arguments: DesignKitFonts.bundledFontNames)
    func isRegisteredAfterRegister(fontName: String) {
        // Kondisi "sebelum register" tidak diuji: proses tes bisa saja sudah
        // mendaftarkan font dari tes lain. Yang dijamin: setelah register, true.
        DesignKitFonts.register()

        #expect(DesignKitFonts.isRegistered(fontName), "\(fontName) is not resolvable by UIKit")
    }

    @Test("A name missing from the bundle is reported, not swallowed")
    func missingFontReportsFailure() {
        let result = DesignKitFonts.register(fontName: "MissingFont-Regular")

        // Justru ini alasan register() mengembalikan hasil: kegagalan font tidak
        // melempar apa pun dan tidak menghentikan app.
        #expect(result.isRegistered == false)
        #expect(result.failureReason != nil)
        #expect(DesignKitFonts.isRegistered("MissingFont-Regular") == false)
    }

    @Test("The resolved font is not a system fallback")
    func resolvedFontIsNotFallback() throws {
        DesignKitFonts.register()
        let font = try #require(UIFont(name: dummyFontName, size: 40))

        // Kalau nama PostScript salah, UIFont(name:) mengembalikan nil dan
        // #require di atas gagal. Family dicek supaya font yang ter-resolve
        // benar-benar font dari package, bukan alias ke font sistem.
        #expect(font.familyName == "PlaygroundDummy")
        #expect(font.fontName == dummyFontName)
    }

    @Test("Every ASCII character has a glyph, not .notdef")
    func fontHasGlyphsForASCII() {
        DesignKitFonts.register()
        let font = CTFontCreateWithName(dummyFontName as CFString, 32, nil)

        let characters = Array("Hello Playground 123".utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        #expect(CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count))

        // Spasi boleh kosong; sisanya harus punya outline, bukan glyph .notdef.
        for (index, glyph) in glyphs.enumerated() where characters[index] != 0x20 {
            #expect(glyph != 0, "character at index \(index) has no glyph")
            #expect(CTFontCreatePathForGlyph(font, glyph, nil) != nil)
        }
    }
}
