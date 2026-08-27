import DesignKit
import SwiftUI

@main
struct HostAppApp: App {

    /// Hasil registrasi font, dipegang supaya layar verifikasi bisa menampilkan
    /// kegagalan sebagai status — bukan diam-diam fallback ke font sistem.
    private let fontRegistration: [DesignKitFonts.RegistrationResult]

    init() {
        // Font dari SPM package tidak terdaftar otomatis. Sekali, di sini.
        fontRegistration = DesignKitFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            SkeletonCheckScreen(fontRegistration: fontRegistration)
        }
    }
}
