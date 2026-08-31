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

    private let sampleText = "Hello Playground 123"

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
        Section("Font registration") {
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
                        Text("resolved by UIKit: \(DesignKitFonts.isRegistered(result.fontName) ? "yes" : "no")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var comparisonSection: some View {
        Section("Visual proof") {
            // Nama font diambil dari hasil registrasi, bukan diketik ulang:
            // string yang salah ketik akan fallback ke font sistem dan justru
            // membuat layar ini melaporkan sukses palsu.
            ForEach(fontRegistration, id: \.fontName) { result in
                sampleRow(result.fontName, font: .custom(result.fontName, size: 24))
            }
            sampleRow("System font", font: .system(size: 24))
        }
    }

    private var hostSection: some View {
        Section {
            // HostApp sengaja memakai lifecycle UIKit, bukan `@main struct App`,
            // supaya titik integrasinya sama dengan app produksi yang sudah ada.
            hostRow("Lifecycle", value: "AppDelegate + SceneDelegate")
            hostRow("Root", value: "UIHostingController")
            hostRow("Font registration", value: "didFinishLaunchingWithOptions")
        } header: {
            Text("Host")
        } footer: {
            Text("DesignKit does not depend on RouteContract — a design system "
                 + "must not know navigation destinations. RouteContract belongs to "
                 + "the layers that actually handle routing.")
        }
    }

    private var howToReadSection: some View {
        Section("How to read this") {
            Text("The font-named rows above must render as a row of boxes. "
                 + "If the text reads normally, registration failed and iOS "
                 + "silently fell back to the system font.")
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

#Preview("Font registered") {
    SkeletonCheckScreen(fontRegistration: DesignKitFonts.register())
}

#Preview("Font failed") {
    SkeletonCheckScreen(
        fontRegistration: [
            .init(
                fontName: "MissingFont-Regular",
                isRegistered: false,
                failureReason: "MissingFont-Regular.ttf is missing from Bundle.module"
            )
        ]
    )
}
