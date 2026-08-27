import DesignKit
import SwiftUI
import UIKit

/// Pemilik window, meniru struktur app produksi yang sudah ada.
///
/// Di sinilah nanti `AppRoot` dipasang: NavigationStack konten, plus satu
/// `SheetCenter` dan satu `BlockerCenter` (lihat bagian Overlay di CLAUDE.md).
/// Untuk sekarang isinya baru layar verifikasi.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(
            rootView: SkeletonCheckScreen(fontRegistration: fontRegistration)
        )
        window.makeKeyAndVisible()
        self.window = window
    }

    /// Idiom app lama: state milik app diambil lewat `UIApplication.shared.delegate`.
    ///
    /// Fallback-nya aman karena `register()` idempoten — kalau cast gagal, hasilnya
    /// tetap benar, bukan array kosong yang menyesatkan layar verifikasi.
    private var fontRegistration: [DesignKitFonts.RegistrationResult] {
        (UIApplication.shared.delegate as? AppDelegate)?.fontRegistration
            ?? DesignKitFonts.register()
    }
}
