import DesignKit
import UIKit

/// Entry point UIKit, meniru struktur app produksi yang sudah ada.
///
/// Bukan `@main struct App` SwiftUI — HostApp sengaja memakai lifecycle lama
/// supaya titik integrasi yang diuji di sini sama dengan titik integrasi di app
/// sebenarnya nanti.
///
/// Dipakai `@main`, bukan `@UIApplicationMain`: atribut lama itu sudah
/// deprecated dan bikin warning di toolchain sekarang. Perilakunya identik.
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Font dari SPM package tidak terdaftar otomatis. Sekali, di sini —
        // sebelum window pertama dibuat, supaya tidak ada frame yang telanjur
        // digambar dengan font fallback.
        //
        // Hasilnya dibuang: app sebenarnya tidak punya keperluan menyimpannya.
        DesignKitFonts.register()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
