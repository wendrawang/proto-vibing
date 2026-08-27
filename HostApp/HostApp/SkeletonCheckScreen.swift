import DesignKit
import RouteContract
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

    private let sampleText = "Halo Playground 123"

    var body: some View {
        NavigationStack {
            List {
                registrationSection
                comparisonSection
                moduleSection
                hostSection
                howToReadSection
            }
            .navigationTitle("Skeleton Check")
        }
    }

    private var registrationSection: some View {
        Section("Registrasi font") {
            ForEach(fontRegistration, id: \.name.rawValue) { result in
                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text(result.name.rawValue)
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
                        Text("dikenali UIKit: \(DesignKitFonts.isRegistered(result.name) ? "ya" : "tidak")")
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
            sampleRow("Font DesignKit", font: .custom(DesignKitFonts.Name.dummyRegular.rawValue, size: 24))
            sampleRow("Font sistem", font: .system(size: 24))
        }
    }

    private var moduleSection: some View {
        Section {
            // Baris pertama dibaca berantai lewat TransactionKit.dependsOn,
            // bukan dua import terpisah: kalau panah itu putus, baris ini tidak
            // akan terkompilasi.
            moduleRow(TransactionKit.moduleName, dependsOn: TransactionKit.dependsOn)
            moduleRow(DesignKit.moduleName, dependsOn: nil)
            moduleRow(RouteContract.moduleName, dependsOn: nil)
        } header: {
            Text("Rantai modul")
        } footer: {
            Text("DesignKit sengaja tidak bergantung ke RouteContract — design "
                 + "system tidak boleh tahu tujuan navigasi. RouteContract dipakai "
                 + "lapisan yang memang mengurus routing; di sini HostApp langsung.")
        }
    }

    private var hostSection: some View {
        Section("Host") {
            // HostApp sengaja memakai lifecycle UIKit, bukan `@main struct App`,
            // supaya titik integrasinya sama dengan app produksi yang sudah ada.
            hostRow("Lifecycle", value: "AppDelegate + SceneDelegate")
            hostRow("Root", value: "UIHostingController")
            hostRow("Registrasi font", value: "didFinishLaunchingWithOptions")
        }
    }

    private var howToReadSection: some View {
        Section("Cara baca") {
            Text("Baris \"Font DesignKit\" harus tampil sebagai deretan kotak. "
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

    private func moduleRow(_ name: String, dependsOn: String?) -> some View {
        HStack {
            Text(name)
                .font(.subheadline.monospaced())
            Spacer()
            if let dependsOn {
                Text("→ \(dependsOn)")
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
