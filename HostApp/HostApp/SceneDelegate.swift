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
            // `register()` idempoten. Panggilan kedua ini tidak mendaftarkan
            // ulang, hanya mengembalikan hasil yang sama — termasuk alasan gagal
            // kalau ada. Jadi layar diagnostik dapat detailnya tanpa AppDelegate
            // perlu menyimpan state yang app sebenarnya tidak butuh.
            rootView: SkeletonCheckScreen(fontRegistration: DesignKitFonts.register())
        )
        window.makeKeyAndVisible()
        self.window = window
    }
}
