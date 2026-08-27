import CoreText
import UIKit
import XCTest

@testable import DesignKit

final class DesignKitFontsTests: XCTestCase {

    func testRegistersEveryDeclaredFont() {
        let results = DesignKitFonts.register()

        XCTAssertEqual(results.count, DesignKitFonts.Name.allCases.count)
        for result in results {
            XCTAssertTrue(result.isRegistered, "\(result.name.rawValue) gagal: \(result.failureReason ?? "-")")
            XCTAssertNil(result.failureReason)
        }
    }

    func testRegisterIsIdempotent() {
        DesignKitFonts.register()
        let secondRun = DesignKitFonts.register()

        // Panggilan kedua menghasilkan kCTFontManagerErrorAlreadyRegistered di
        // level CoreText — itu harus dibaca sebagai sukses, bukan kegagalan.
        for result in secondRun {
            XCTAssertTrue(result.isRegistered, "\(result.name.rawValue) gagal: \(result.failureReason ?? "-")")
        }
    }

    func testIsRegisteredAfterRegister() {
        // Kondisi "sebelum register" tidak diuji: proses tes bisa saja sudah
        // mendaftarkan font dari tes lain. Yang dijamin: setelah register, true.
        DesignKitFonts.register()

        for name in DesignKitFonts.Name.allCases {
            XCTAssertTrue(DesignKitFonts.isRegistered(name), "\(name.rawValue) tidak dikenali UIKit")
        }
    }

    func testResolvedFontIsNotFallback() throws {
        DesignKitFonts.register()
        let font = try XCTUnwrap(UIFont(name: DesignKitFonts.Name.dummyRegular.rawValue, size: 40))

        // Kalau nama PostScript salah, UIFont(name:) mengembalikan nil dan
        // XCTUnwrap di atas gagal. Family dicek supaya font yang ter-resolve
        // benar-benar font dari package, bukan alias ke font sistem.
        XCTAssertEqual(font.familyName, "PlaygroundDummy")
        XCTAssertEqual(font.fontName, DesignKitFonts.Name.dummyRegular.rawValue)
    }

    func testFontHasGlyphsForASCII() {
        DesignKitFonts.register()
        let font = CTFontCreateWithName(DesignKitFonts.Name.dummyRegular.rawValue as CFString, 32, nil)

        let characters = Array("Halo Playground 123".utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        XCTAssertTrue(CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count))

        // Spasi boleh kosong; sisanya harus punya outline, bukan glyph .notdef.
        for (index, glyph) in glyphs.enumerated() where characters[index] != 0x20 {
            XCTAssertNotEqual(glyph, 0, "karakter index \(index) tidak punya glyph")
            XCTAssertNotNil(CTFontCreatePathForGlyph(font, glyph, nil))
        }
    }

    func testRegisterSingleFontOverload() {
        // Overload satu-font dipakai HostApp lewat register() jamak, tapi API-nya
        // publik jadi diuji sendiri. Jalur gagal (file tidak ada di bundle) belum
        // bisa diuji: Name hanya berisi font yang memang di-bundle.
        let result = DesignKitFonts.register(.dummyRegular)

        XCTAssertEqual(result.name, .dummyRegular)
        XCTAssertTrue(result.isRegistered)
    }

    func testDesignKitModuleName() {
        XCTAssertEqual(DesignKit.moduleName, "DesignKit")
    }
}
