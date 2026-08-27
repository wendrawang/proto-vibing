import DesignKit
import SwiftUI
import TransactionKit

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

    private let contoh = "Halo Playground 123"

    var body: some View {
        NavigationStack {
            List {
                fontSection
                bandinganSection
                modulSection
                hostSection
                catatanSection
            }
            .navigationTitle("Skeleton Check")
        }
    }

    private var fontSection: some View {
        Section("Registrasi font") {
            ForEach(fontRegistration, id: \.name.rawValue) { hasil in
                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text(hasil.name.rawValue)
                            .font(.subheadline.monospaced())
                    } icon: {
                        Image(systemName: hasil.isRegistered ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(hasil.isRegistered ? Color.green : Color.red)
                    }

                    if let alasan = hasil.failureReason {
                        Text(alasan)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("dikenali UIKit: \(DesignKitFonts.isRegistered(hasil.name) ? "ya" : "tidak")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var bandinganSection: some View {
        Section("Bukti visual") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Font DesignKit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(contoh)
                    .font(.custom(DesignKitFonts.Name.dummyRegular.rawValue, size: 24))
            }
            .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Font sistem")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(contoh)
                    .font(.system(size: 24))
            }
            .padding(.vertical, 2)
        }
    }

    private var modulSection: some View {
        Section("Rantai modul") {
            // Dibaca berantai, bukan tiga import terpisah: kalau salah satu
            // panah dependensi putus, baris ini tidak akan terkompilasi.
            barisModul(TransactionKit.moduleName, turun: TransactionKit.dependsOn)
            barisModul(DesignKit.moduleName, turun: DesignKit.dependsOn)
            barisModul(DesignKit.dependsOn, turun: nil)
        }
    }

    private var hostSection: some View {
        Section("Host") {
            // HostApp sengaja memakai lifecycle UIKit, bukan `@main struct App`,
            // supaya titik integrasinya sama dengan app produksi yang sudah ada.
            barisHost("Lifecycle", nilai: "AppDelegate + SceneDelegate")
            barisHost("Root", nilai: "UIHostingController")
            barisHost("Registrasi font", nilai: "didFinishLaunchingWithOptions")
        }
    }

    private var catatanSection: some View {
        Section("Cara baca") {
            Text("Baris \"Font DesignKit\" harus tampil sebagai deretan kotak. "
                 + "Kalau teksnya terbaca normal, font gagal diregistrasi dan iOS "
                 + "diam-diam fallback ke font sistem.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private func barisHost(_ label: String, nilai: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
            Spacer(minLength: 12)
            Text(nilai)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func barisModul(_ nama: String, turun: String?) -> some View {
        HStack {
            Text(nama)
                .font(.subheadline.monospaced())
            Spacer()
            if let turun {
                Text("→ \(turun)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Font terdaftar") {
    DesignKitFonts.register()
    return SkeletonCheckScreen(
        fontRegistration: DesignKitFonts.Name.allCases.map {
            .init(name: $0, isRegistered: true, failureReason: nil)
        }
    )
}

#Preview("Font gagal") {
    SkeletonCheckScreen(
        fontRegistration: DesignKitFonts.Name.allCases.map {
            .init(name: $0, isRegistered: false, failureReason: "file tidak ada di Bundle.module")
        }
    )
}
