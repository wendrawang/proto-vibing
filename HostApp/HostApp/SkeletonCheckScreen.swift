import DesignKit
import SwiftUI

/// Layar verifikasi langkah 1 & 2.
///
/// Bukan layar produk — tugasnya membuktikan dua hal yang gampang gagal diam-diam:
/// rantai dependensi package benar-benar ter-link, dan font dari `Bundle.module`
/// benar-benar terdaftar.
///
/// Warna sengaja memakai warna sistem, bukan token. Adapter theme baru masuk di
/// langkah 3, dan hanya `Theme/` yang boleh menyentuh `*ColorConstants`.
struct SkeletonCheckScreen: View {

    let fontRegistration: [DesignKitFonts.RegistrationResult]

    private let sampleText = "Halo Playground 123"

    var body: some View {
        NavigationStack {
            List {
                registrationSection
                comparisonSection
                hostSection
                howToReadSection
            }
            .navigationTitle("Skeleton Check")
        }
    }

    private var registrationSection: some View {
        Section("Registrasi font") {
            ForEach(fontRegistration, id: \.fontName) { result in
                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text(result.fontName)
                            .font(.subheadline.monospaced())
                    } icon: {
                        Image(systemName: result.isRegistered ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.isRegistered ? Color.green : Color.red)
                    }

                    if let reason = result.failureReason {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("dikenali UIKit: \(DesignKitFonts.isRegistered(result.fontName) ? "ya" : "tidak")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var comparisonSection: some View {
        Section("Bukti visual") {
            // Nama font diambil dari hasil registrasi, bukan diketik ulang:
            // string yang salah ketik akan fallback ke font sistem dan justru
            // membuat layar ini melaporkan sukses palsu.
            ForEach(fontRegistration, id: \.fontName) { result in
                sampleRow(result.fontName, font: .custom(result.fontName, size: 24))
            }
            sampleRow("Font sistem", font: .system(size: 24))
        }
    }

    private var hostSection: some View {
        Section {
            // HostApp sengaja memakai lifecycle UIKit, bukan `@main struct App`,
            // supaya titik integrasinya sama dengan app produksi yang sudah ada.
            hostRow("Lifecycle", value: "AppDelegate + SceneDelegate")
            hostRow("Root", value: "UIHostingController")
            hostRow("Registrasi font", value: "didFinishLaunchingWithOptions")
        } header: {
            Text("Host")
        } footer: {
            Text("DesignKit tidak bergantung ke RouteContract — design system "
                 + "tidak boleh tahu tujuan navigasi. RouteContract dipakai "
                 + "lapisan yang memang mengurus routing.")
        }
    }

    private var howToReadSection: some View {
        Section("Cara baca") {
            Text("Baris ber-nama-font di atas harus tampil sebagai deretan kotak. "
                 + "Kalau teksnya terbaca normal, font gagal diregistrasi dan iOS "
                 + "diam-diam fallback ke font sistem.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private func sampleRow(_ caption: String, font: Font) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(sampleText)
                .font(font)
        }
        .padding(.vertical, 2)
    }

    private func hostRow(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
            Spacer(minLength: 12)
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview("Font terdaftar") {
    SkeletonCheckScreen(fontRegistration: DesignKitFonts.register())
}

#Preview("Font gagal") {
    SkeletonCheckScreen(
        fontRegistration: [
            .init(
                fontName: "TidakAdaFont-Regular",
                isRegistered: false,
                failureReason: "TidakAdaFont-Regular.ttf tidak ada di Bundle.module"
            )
        ]
    )
}
