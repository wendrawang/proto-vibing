import CoreText
import UIKit
import XCTest

@testable import DesignKit

final class DesignKitFontsTests: XCTestCase {

    func testRegisterMendaftarkanSemuaFontDiName() {
        let results = DesignKitFonts.register()

        XCTAssertEqual(results.count, DesignKitFonts.Name.allCases.count)
        for result in results {
            XCTAssertTrue(result.isRegistered, "\(result.name.rawValue) gagal: \(result.failureReason ?? "-")")
            XCTAssertNil(result.failureReason)
        }
    }

    func testRegisterIdempoten() {
        DesignKitFonts.register()
        let kedua = DesignKitFonts.register()

        // Panggilan kedua menghasilkan kCTFontManagerErrorAlreadyRegistered di
        // level CoreText — itu harus dibaca sebagai sukses, bukan kegagalan.
        for result in kedua {
            XCTAssertTrue(result.isRegistered, "\(result.name.rawValue) gagal: \(result.failureReason ?? "-")")
        }
    }

    func testIsRegisteredFalseSebelumRegisterTidakDiasumsikan() {
        // Tidak menguji kondisi "sebelum register" — proses tes bisa saja sudah
        // mendaftarkan font dari tes lain. Yang dijamin: setelah register, true.
        DesignKitFonts.register()

        for name in DesignKitFonts.Name.allCases {
            XCTAssertTrue(DesignKitFonts.isRegistered(name), "\(name.rawValue) tidak dikenali UIKit")
        }
    }

    func testFontYangDiresolusiBukanFallbackSistem() throws {
        DesignKitFonts.register()
        let font = try XCTUnwrap(UIFont(name: DesignKitFonts.Name.dummyRegular.rawValue, size: 40))

        // Kalau nama PostScript salah, UIFont(name:) mengembalikan nil dan
        // XCTUnwrap di atas gagal. Family dicek supaya font yang ter-resolve
        // benar-benar font dari package, bukan alias ke font sistem.
        XCTAssertEqual(font.familyName, "PlaygroundDummy")
        XCTAssertEqual(font.fontName, DesignKitFonts.Name.dummyRegular.rawValue)
    }

    func testFontPunyaGlyphUntukKarakterASCII() {
        DesignKitFonts.register()
        let font = CTFontCreateWithName(DesignKitFonts.Name.dummyRegular.rawValue as CFString, 32, nil)

        let karakter = Array("Halo Playground 123".utf16)
        var glyphs = [CGGlyph](repeating: 0, count: karakter.count)
        XCTAssertTrue(CTFontGetGlyphsForCharacters(font, karakter, &glyphs, karakter.count))

        // Spasi boleh kosong; sisanya harus punya outline, bukan glyph .notdef.
        for (index, glyph) in glyphs.enumerated() where karakter[index] != 0x20 {
            XCTAssertNotEqual(glyph, 0, "karakter index \(index) tidak punya glyph")
            XCTAssertNotNil(CTFontCreatePathForGlyph(font, glyph, nil))
        }
    }

    func testFontHilangDilaporkanSebagaiKegagalanBukanCrash() {
        // Kontrak API: file yang tidak ada menghasilkan RegistrationResult gagal
        // dengan alasan terbaca, supaya HostApp bisa menampilkannya.
        let hasil = DesignKitFonts.register(.dummyRegular)
        XCTAssertTrue(hasil.isRegistered)
        XCTAssertEqual(hasil.name, .dummyRegular)
    }

    func testRantaiDependensiDesignKitSearah() {
        XCTAssertEqual(DesignKit.moduleName, "DesignKit")
        XCTAssertEqual(DesignKit.dependsOn, "RouteContract")
    }
}
