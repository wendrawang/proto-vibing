import CoreText
import Testing
import UIKit

@testable import DesignKit

/// Registrasi font memodifikasi state CoreText milik seluruh proses, jadi suite
/// ini `.serialized` — tes paralel akan saling mendaftarkan font yang sama dan
/// membuat kode error CoreText tidak bisa ditebak.
@Suite("Registrasi font DesignKit", .serialized)
struct DesignKitFontsTests {

    @Test("register() mendaftarkan semua font yang dideklarasikan di Name")
    func registersEveryDeclaredFont() {
        let results = DesignKitFonts.register()

        #expect(results.count == DesignKitFonts.Name.allCases.count)
        for result in results {
            #expect(result.isRegistered, "\(result.name.rawValue) gagal: \(result.failureReason ?? "-")")
            #expect(result.failureReason == nil)
        }
    }

    @Test("register() idempoten — panggilan kedua tetap sukses")
    func registerIsIdempotent() {
        DesignKitFonts.register()
        let secondRun = DesignKitFonts.register()

        // Panggilan kedua menghasilkan kCTFontManagerErrorAlreadyRegistered di
        // level CoreText — itu harus dibaca sebagai sukses, bukan kegagalan.
        for result in secondRun {
            #expect(result.isRegistered, "\(result.name.rawValue) gagal: \(result.failureReason ?? "-")")
        }
    }

    @Test("UIKit mengenali font setelah register()", arguments: DesignKitFonts.Name.allCases)
    func isRegisteredAfterRegister(name: DesignKitFonts.Name) {
        // Kondisi "sebelum register" tidak diuji: proses tes bisa saja sudah
        // mendaftarkan font dari tes lain. Yang dijamin: setelah register, true.
        DesignKitFonts.register()

        #expect(DesignKitFonts.isRegistered(name), "\(name.rawValue) tidak dikenali UIKit")
    }

    @Test("Font yang ter-resolve bukan fallback font sistem")
    func resolvedFontIsNotFallback() throws {
        DesignKitFonts.register()
        let font = try #require(UIFont(name: DesignKitFonts.Name.dummyRegular.rawValue, size: 40))

        // Kalau nama PostScript salah, UIFont(name:) mengembalikan nil dan
        // #require di atas gagal. Family dicek supaya font yang ter-resolve
        // benar-benar font dari package, bukan alias ke font sistem.
        #expect(font.familyName == "PlaygroundDummy")
        #expect(font.fontName == DesignKitFonts.Name.dummyRegular.rawValue)
    }

    @Test("Setiap karakter ASCII punya glyph, bukan .notdef")
    func fontHasGlyphsForASCII() {
        DesignKitFonts.register()
        let font = CTFontCreateWithName(DesignKitFonts.Name.dummyRegular.rawValue as CFString, 32, nil)

        let characters = Array("Halo Playground 123".utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        #expect(CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count))

        // Spasi boleh kosong; sisanya harus punya outline, bukan glyph .notdef.
        for (index, glyph) in glyphs.enumerated() where characters[index] != 0x20 {
            #expect(glyph != 0, "karakter index \(index) tidak punya glyph")
            #expect(CTFontCreatePathForGlyph(font, glyph, nil) != nil)
        }
    }

    @Test("Overload satu-font mengembalikan nama yang diminta")
    func registerSingleFontOverload() {
        // Jalur gagal (file tidak ada di bundle) belum bisa diuji: Name hanya
        // berisi font yang memang di-bundle.
        let result = DesignKitFonts.register(.dummyRegular)

        #expect(result.name == .dummyRegular)
        #expect(result.isRegistered)
    }
}
