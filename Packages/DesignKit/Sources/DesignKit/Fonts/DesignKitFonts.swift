import CoreText
import UIKit

/// Registrasi font yang di-bundle di dalam DesignKit.
///
/// Font di dalam SPM package **tidak terdaftar otomatis**. `UIAppFonts` di
/// Info.plist hanya membaca resource milik app target, bukan resource bundle
/// milik package — jadi font harus didaftarkan manual ke CoreText saat runtime.
///
/// Panggil `register()` sekali saat startup HostApp.
///
/// Catatan: CLAUDE.md menyebut `CTFontManagerRegisterGraphicsFont`. API itu
/// deprecated sejak iOS 18 dan memicu warning di SDK sekarang, jadi di sini
/// dipakai `CTFontManagerRegisterFontsForURL` — sama dengan `FontManager` di
/// app produksi, tidak deprecated, dan tidak perlu memuat file ke `Data` dulu.
public enum DesignKitFonts {

    /// Nama **PostScript** font yang di-bundle DesignKit.
    ///
    /// Sengaja `internal`: komponen tidak pernah menyebut nama font — mereka
    /// memakai style tipografi (langkah 3). Yang perlu tahu daftar ini cuma
    /// `register()`.
    ///
    /// Saat font asli masuk, taruh file-nya di `Resources/Fonts/` lalu tambahkan
    /// nama PostScript-nya di sini — bukan nama file, bukan nama family. Kalau
    /// ketiganya berbeda, `UIFont(name:)` hanya mengenali nama PostScript.
    static let bundledFontNames = [
        "PlaygroundDummy-Regular"
    ]

    private static let fileExtension = "ttf"

    /// Hasil satu registrasi.
    ///
    /// Inilah bedanya dengan `_ = CTFontManagerRegisterFontsForURL(...)`: font
    /// yang gagal terdaftar tidak melempar apa pun dan tidak menghentikan app —
    /// dia cuma jadi teks yang diam-diam memakai font sistem. Kalau hasilnya
    /// dibuang, tidak ada satu pun sinyal bahwa itu terjadi.
    public struct RegistrationResult: Equatable, Sendable {
        public let fontName: String
        public let isRegistered: Bool
        /// Alasan gagal; `nil` kalau berhasil.
        public let failureReason: String?

        public init(fontName: String, isRegistered: Bool, failureReason: String?) {
            self.fontName = fontName
            self.isRegistered = isRegistered
            self.failureReason = failureReason
        }
    }

    /// Mendaftarkan seluruh font yang di-bundle ke proses ini.
    ///
    /// Idempoten — aman dipanggil ulang dari preview atau unit test.
    @discardableResult
    public static func register() -> [RegistrationResult] {
        bundledFontNames.map(register(fontName:))
    }

    /// `true` kalau UIKit sudah bisa membuat font dengan nama PostScript ini.
    ///
    /// Ini bukti registrasi yang sebenarnya: `Font.custom` diam-diam fallback ke
    /// font sistem kalau namanya tidak dikenal, jadi tampilan saja tidak cukup.
    public static func isRegistered(_ fontName: String) -> Bool {
        UIFont(name: fontName, size: 12) != nil
    }

    static func register(fontName: String) -> RegistrationResult {
        guard let url = Bundle.module.url(forResource: fontName, withExtension: fileExtension) else {
            return RegistrationResult(
                fontName: fontName,
                isRegistered: false,
                failureReason: "\(fontName).\(fileExtension) tidak ada di Bundle.module"
            )
        }

        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            return RegistrationResult(fontName: fontName, isRegistered: true, failureReason: nil)
        }

        // Sudah terdaftar bukan kegagalan.
        let cfError = error?.takeRetainedValue()
        if let cfError, CFErrorGetCode(cfError) == CTFontManagerError.alreadyRegistered.rawValue {
            return RegistrationResult(fontName: fontName, isRegistered: true, failureReason: nil)
        }

        return RegistrationResult(
            fontName: fontName,
            isRegistered: false,
            failureReason: cfError.map { CFErrorCopyDescription($0) as String } ?? "gagal tanpa CFError"
        )
    }
}
