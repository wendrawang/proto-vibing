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
/// dipakai `CTFontManagerRegisterFontsForURL` — hasilnya sama, tidak deprecated,
/// dan tidak perlu memuat file ke `Data` lebih dulu.
public enum DesignKitFonts {

    /// Nama **PostScript** font yang di-bundle DesignKit.
    ///
    /// Isinya masih satu font dummy berbentuk kotak. Saat font asli masuk:
    /// taruh file-nya di `Resources/Fonts/`, lalu ganti case di sini dengan
    /// nama PostScript-nya — bukan nama file, bukan nama family. Kalau ketiganya
    /// berbeda, `UIFont(name:)` hanya mengenali nama PostScript.
    public enum Name: String, CaseIterable, Sendable {
        case dummyRegular = "PlaygroundDummy-Regular"

        /// Nama file di `Resources/Fonts`, tanpa ekstensi.
        var fileName: String { rawValue }
        var fileExtension: String { "ttf" }
    }

    /// Hasil satu registrasi. Dipakai layar verifikasi HostApp supaya kegagalan
    /// font terlihat sebagai status, bukan cuma teks yang diam-diam fallback.
    public struct RegistrationResult: Equatable, Sendable {
        public let name: Name
        public let isRegistered: Bool
        /// Alasan gagal; `nil` kalau berhasil.
        public let failureReason: String?

        public init(name: Name, isRegistered: Bool, failureReason: String?) {
            self.name = name
            self.isRegistered = isRegistered
            self.failureReason = failureReason
        }
    }

    /// Mendaftarkan seluruh font di `Name` ke proses ini.
    ///
    /// Idempoten — aman dipanggil ulang dari preview atau unit test.
    @discardableResult
    public static func register() -> [RegistrationResult] {
        Name.allCases.map(register(_:))
    }

    /// Mendaftarkan satu font ke proses ini.
    @discardableResult
    public static func register(_ name: Name) -> RegistrationResult {
        guard let url = Bundle.module.url(forResource: name.fileName, withExtension: name.fileExtension) else {
            return RegistrationResult(
                name: name,
                isRegistered: false,
                failureReason: "\(name.fileName).\(name.fileExtension) tidak ada di Bundle.module"
            )
        }

        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            return RegistrationResult(name: name, isRegistered: true, failureReason: nil)
        }

        // Sudah terdaftar bukan kegagalan.
        let cfError = error?.takeRetainedValue()
        if let cfError, CFErrorGetCode(cfError) == CTFontManagerError.alreadyRegistered.rawValue {
            return RegistrationResult(name: name, isRegistered: true, failureReason: nil)
        }

        return RegistrationResult(
            name: name,
            isRegistered: false,
            failureReason: cfError.map { CFErrorCopyDescription($0) as String } ?? "gagal tanpa CFError"
        )
    }

    /// `true` kalau UIKit sudah bisa membuat font dengan nama PostScript ini.
    ///
    /// Ini bukti registrasi yang sebenarnya: `Font.custom` diam-diam fallback ke
    /// font sistem kalau namanya tidak dikenal, jadi tampilan saja tidak cukup.
    public static func isRegistered(_ name: Name) -> Bool {
        UIFont(name: name.rawValue, size: 12) != nil
    }
}
