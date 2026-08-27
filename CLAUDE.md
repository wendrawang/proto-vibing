# CLAUDE.md

Konteks dan aturan untuk repo ini. Baca sebelum menulis kode apa pun.

---

## Apa ini

Prototype SDK untuk modernisasi aplikasi mobile banking. Dua deliverable:

1. **DesignKit** — design system SwiftUI
2. **TransactionKit** — pipeline transaksi generik (amount → summary → pin → receipt)

Divalidasi dengan merakit ulang satu layar nyata: **transfer landing** (list penerima dengan pagination), lalu satu flow transaksi lengkap.

Target: iOS 16+. Pure SwiftUI. NavigationStack.

**Ini prototype.** Tujuannya membuktikan arsitektur dan menghasilkan angka effort — bukan rilis. Tapi package-nya adalah deliverable: kalau disetujui, app produksi menambahkan dependency, bukan menulis ulang.

---

## Non-goals

Jangan kerjakan ini, walaupun terlihat berguna:

- Komponen yang belum punya pengguna nyata di repo ini
- Dukungan iOS di bawah 16
- Networking layer, caching, persistence — pakai data dummy
- Lokalisasi
- Implementasi dark mode (sediakan sumbunya, jangan isi)
- Generalisasi sebelum ada tiga pemakai berbeda

Kalau ragu apakah sesuatu masuk scope: tanya, jangan bangun.

---

## Struktur package

Tiga package terpisah, bukan satu package tiga target. Arah dependensi jadi
dijaga SPM sendiri: siklus ditolak saat resolve, bukan saat review.

```
Packages/
├── DesignKit/Sources/DesignKit/
│   ├── Tokens/        generated — JANGAN diedit tangan
│   ├── Theme/         resolver + Environment + adapter SwiftUI
│   ├── Foundation/    typography, spacing, radius, shadow
│   ├── Primitives/    komponen atom
│   ├── Patterns/      komposisi dari primitives
│   ├── Fonts/         DesignKitFonts.register()
│   └── Resources/Fonts/   .process di Package.swift
│
├── TransactionKit/Sources/TransactionKit/   pipeline generik + kontrak data
│
└── RouteContract/Sources/RouteContract/     enum Route, protocol AppNavigator

HostApp/               app kecil untuk menjalankan & mendemokan package
Tools/                 generator font dummy — hapus saat font asli masuk
```

**HostApp memakai lifecycle UIKit** (`AppDelegate` + `SceneDelegate` +
`UIHostingController`), bukan `@main struct App`, supaya titik integrasinya sama
dengan app produksi yang sudah ada: font diregistrasi di
`didFinishLaunchingWithOptions`, window dimiliki `SceneDelegate`. Di sinilah nanti
`AppRoot` dipasang — lihat bagian Overlay.

Dipakai `@main`, bukan `@UIApplicationMain`: atribut lama itu sudah deprecated dan
bikin warning di toolchain sekarang. Perilakunya identik.

Sub-folder `Tokens/`, `Theme/`, dst. ada di dalam `Sources/<nama-target>/`
mengikuti konvensi SPM. Menaruhnya langsung di akar package memaksa
`path:`/`sources:` eksplisit di manifest dan pecah tiap kali folder baru
ditambah — tidak sepadan.

Arah dependensi:

```
HostApp ──→ Feature ──→ TransactionKit ──→ DesignKit
   │           │              ┆
   └───────────┴──────────────┴──→ RouteContract
```

Tidak boleh terbalik, tidak boleh melingkar.

**DesignKit tidak bergantung ke apa pun, RouteContract termasuk.** Design system
tidak boleh tahu tujuan navigasi: tombol tidak pindah layar, tombol memanggil
closure (aturan API #1), dan komponen bermakna domain bukan milik DesignKit
(aturan #6). Kalau panah `DesignKit → RouteContract` ada, tidak ada satu pun
mekanisme yang mencegah `navigator.open(...)` masuk ke dalam `ByonListRow` —
review-lah yang harus menangkapnya, bukan kompiler.

RouteContract adalah leaf, dipakai lapisan yang memang mengurus routing. Panah
putus-putus dari TransactionKit baru ditarik kalau pipeline-nya benar-benar butuh
`AppNavigator` (langkah 8) — jangan ditarik sebelum itu.

---

## Theming

### Kondisi token yang sudah ada

Token **sudah semantik** (`colorsTextSecondary`, `colorsSurfacePrimary`, `colorsButtonActive`) dan **sudah multi-brand**. Bentuknya UIKit:

```swift
public protocol FigmaColorProtocol {
    var colorsSurfacePrimary: UIColor { get }
    var colorsTextSecondary: UIColor { get }
    // ~42 token
}

public struct DefaultColorConstants: FigmaColorProtocol { ... }
public struct PremierColorConstants: FigmaColorProtocol { ... }
public struct PrivateColorConstants: FigmaColorProtocol { ... }
```

`DefaultColorConstants` adalah baseline. Ada juga struct SwiftUI `FigmaColor` — **abaikan, jangan pakai**, itu eksperimen lama yang bocor palet mentah dan tidak sinkron.

Generator tidak diubah. DesignKit menyediakan adapter tipis di atasnya.

### Dua sumbu

```swift
public enum Proposition { case `default`, premier, `private` }
public enum Appearance  { case light, dark }

public struct ThemeResolver {
    public static func resolve(_ p: Proposition, _ a: Appearance) -> FigmaColorProtocol {
        switch p {
        case .premier: return PremierColorConstants()   // abaikan appearance
        case .private: return PrivateColorConstants()   // abaikan appearance
        case .default:
            switch a {
            case .light: return DefaultColorConstants()
            case .dark:  return DefaultColorConstants() // TODO: DefaultDarkColorConstants
            }
        }
    }
}
```

Dark mode belum ada token-nya. Sumbunya tetap ada sejak sekarang supaya penambahannya nanti hanya menyentuh satu baris.

### Aturan keras

- **Warna diresolusi eksplisit.** JANGAN pakai asset catalog dynamic color atau `UIColor { trait in ... }` — screen thematic harus mengabaikan appearance sistem, dan dynamic color menghilangkan kendali itu.
- **Hanya `Theme/` yang boleh menyebut `*ColorConstants` atau `FigmaColorProtocol`.** Komponen tidak pernah menyentuhnya.
- TODO untuk saat dark mode masuk: kunci `.colorScheme(.light)` di subtree thematic, supaya keyboard/alert sistem tidak ikut gelap.

### Environment, bukan parameter

Default Environment adalah `.default` + `.light`. Screen yang thematic **opt-in**, dan keputusannya dipusatkan di dispatcher — bukan di penulis screen:

```swift
private let propositionAwareRoutes: Set<Route> = [.dashboard, .settings]

// RouteScreen
screen(for: route)
    .environment(\.theme, Theme(
        propositionAwareRoutes.contains(route) ? session.proposition : .default,
        .light
    ))
```

Komponen membaca sendiri:

```swift
public struct ByonButton: View {
    @Environment(\.theme) private var theme
    let title: String
    let style: Style
    let action: () -> Void
}
```

**Komponen TIDAK PERNAH menerima `theme` atau `proposition` sebagai parameter.** Komponen yang sama di screen thematic tampil emas, di screen default tampil merah — tanpa satu pun perbedaan di call site.

Override subtree tersedia untuk pengecualian yang disengaja:

```swift
ByonButton(...).proposition(.default)
```

Kalau override ini sering dibutuhkan, pembagian screen thematic-nya yang salah — perbaiki daftarnya, jangan tambal per komponen.

### Style vs theme — jangan dicampur

- **`style`** menentukan **token mana** yang dipakai (`.primary` → `buttonActive`, `.secondary` → `outlineNetral`). Keputusan per pemanggilan.
- **`theme`** menentukan **nilai** token itu. Konteks screen.

Jangan pernah bikin `.primaryPremier` atau `.secondaryDefault`. Itu kombinatorial dan tidak terkelola.

### Penamaan adapter

Kelompokkan, jangan flat. Prefix `colors` dibuang.

```swift
theme.text.secondary        // bukan theme.colorsTextSecondary
theme.surface.primary
theme.icon.disabled
theme.button.active
```

Bangun hanya grup yang dibutuhkan komponen yang sedang ditulis. Jangan petakan 42 token sekaligus.

### Catatan token yang perlu dikonfirmasi

Hanya 4 token yang berbeda antar proposition: `colorsButtonActive`, `colorsButtonHover`, `colorsButtonDisable`, `colorsSurfaceSelected`. Sisanya identik.

`colorsTextBrand`, `colorsOutlineRed`, `colorsIconColored` tetap merah di Premier dan Private — kemungkinan gap di token set, sedang dikonfirmasi ke tim design. Jangan bikin workaround untuk ini.

**`PrivateColorConstants` belum ada di repo.** Yang sudah ditaruh baru
`FigmaColorProtocol`, `DefaultColorConstants`, `PremierColorConstants`, dan
`FigmaColor`. `ThemeResolver` case `.private` tidak bisa ditulis sebelum file itu
masuk — salin keluaran generator ke `Tokens/` sebelum langkah 3.

---

## Aturan API komponen

Aturan keras. Kalau sebuah desain melanggarnya, desainnya yang salah.

1. **Komponen tidak menerima ViewModel.** Terima nilai dan closure.
2. **Tidak ada stored closure di objek yang hidup lebih lama dari view.** Ini penyebab retain cycle di codebase lama.
   ```swift
   // BENAR
   ByonButton(title: "Kirim") { onSubmit() }

   // SALAH
   buttonViewModel.action = self.onSubmit
   ```
3. **Tidak ada `AnyView` di API publik.** Slot memakai `@ViewBuilder` generic.
4. **Tidak ada state internal untuk data.** Toggle menerima `isOn` + `onToggle`. State internal hanya untuk hal presentasional (animasi, fokus).
5. **Potong berdasarkan struktur, bukan makna.** "Tambah Penerima" dan "baris favorit" adalah satu `ByonListRow` dengan slot berbeda, bukan dua komponen.
6. **Komponen bermakna domain bukan milik DesignKit.** `RecipientRow`, `TransferSummaryCard` hidup di package flow. DesignKit menyediakan bentuk; flow menyediakan makna.
7. **Setiap komponen punya `#Preview`** dengan minimal 2 state, dan satu preview dengan `.proposition(.premier)`.

### Definition of done per komponen

- [ ] Tidak menyebut `*ColorConstants` / `FigmaColorProtocol`
- [ ] Tidak menerima ViewModel, theme, atau proposition sebagai parameter
- [ ] Tidak ada `AnyView` di signature publik
- [ ] Punya `#Preview` minimal 2 state + 1 preview premier
- [ ] Dipakai di layar demo, bukan hanya di preview

---

## Font

Font ada di `Sources/DesignKit/Resources/Fonts`, dideklarasikan `.process` di `Package.swift`.

Font dalam SPM package **tidak terdaftar otomatis** — `UIAppFonts` hanya membaca
resource milik app target, bukan resource bundle milik package. Registrasi manual
ada di `Fonts/DesignKitFonts.swift`, dipanggil sekali di `HostAppApp.init()`.

`CTFontManagerRegisterGraphicsFont` **deprecated sejak iOS 18** dan memicu warning
di SDK sekarang. Yang dipakai `CTFontManagerRegisterFontsForURL(url, .process, &error)`
— hasilnya sama, tidak deprecated, dan tidak perlu memuat file ke `Data` dulu.
`kCTFontManagerErrorAlreadyRegistered` dibaca sebagai sukses supaya `register()`
idempoten (preview dan unit test memanggilnya berkali-kali di proses yang sama).

**Nama di `DesignKitFonts.Name` adalah nama PostScript**, bukan nama file dan bukan
nama family. `UIFont(name:)` hanya mengenali nama PostScript; salah isi = nil =
`Font.custom` diam-diam fallback ke font sistem.

Yang di-bundle sekarang masih font dummy berbentuk kotak (lihat `Tools/`). Kalau
teks contoh di HostApp terbaca normal dan bukan deretan kotak, berarti registrasi
gagal.

---

## TransactionKit

Aplikasi ini bukan kumpulan flow terpisah. Sebagian besar flow adalah **pipeline transaksi yang sama dengan ujung berbeda** — hanya layar pertama dan API yang berbeda.

### Kontrak

```swift
public enum TransactionStep: Hashable {
    case currency, recipientDetail, additionalInfo
    case amount, summary, pin, receipt
    case custom(String)          // langkah milik flow tertentu
}

public struct TransactionState {
    public var source: BankAccount?
    public var recipient: Recipient?
    public var amount: Amount?
    public var currency: String?
    public var additionalInfo: AdditionalInfo?
    public var summary: TransactionSummary?
}

public protocol TransactionJourney {
    /// Fungsi murni. Tanpa UI, tanpa efek samping. Wajib punya unit test.
    func nextStep(after: TransactionStep?, state: TransactionState) -> TransactionStep?

    func inquiry(_ state: TransactionState) async throws -> TransactionSummary
    func submit(_ state: TransactionState, pin: String) async throws -> ReceiptModel
}
```

### Aturan

- **Urutan langkah adalah data, bukan struktur.** Pipeline tidak hardcode rantai layar; `nextStep` yang menentukan.
- **Step vs excursion.** Step memajukan transaksi dan masuk `nextStep`. Excursion (ganti rekening sumber, lihat detail fee) adalah push biasa yang kembali dengan `TransactionState` berubah — **bukan** bagian dari urutan. Jangan campur.
- **State dimiliki router**, satu objek. **Tidak ada `@Binding` berantai antar layar.**
- **Layar tidak tahu layar berikutnya.** Layar memanggil `advance()`; router yang memutuskan.
- `custom(String)` disediakan oleh package flow, bukan oleh TransactionKit. Stringly-typed — trade-off yang diterima untuk prototype.

### Model konten generik

`TransactionSummary` dan `ReceiptModel` memakai array section, bukan field per flow:

```swift
public enum ReceiptSection {
    case keyValue([KeyValueRow])
    case image(ImageRef)
    case note(String)
}
```

Case baru ditambahkan saat flow **ketiga** membutuhkannya. Dua flow yang butuh hal sama belum pola.

**Tanda bahaya:** field opsional di model yang hanya diisi satu flow. Kalau muncul, berhenti dan tanya.

---

## Routing

```swift
public protocol AppNavigator {
    func open(_ route: Route)
    func back()
    func backToRoot()
}
```

- Destination didaftarkan **sekali di akar stack** lewat `navigationDestination(for: Route.self)`, bukan di parent tiap layar.
- Layar mana pun boleh `navigator.open(...)` tanpa perlu didaftarkan oleh parent.
- `RouteScreen` dispatcher memetakan `Route` ke view. **Tanpa `AnyView`.**
- Dispatcher juga tempat theme di-inject per route (lihat bagian Theming).

---

## Overlay

Overlay dimiliki app, bukan screen.

```
AppRoot
 ├── NavigationStack (konten)
 ├── SheetCenter        ← satu instance
 └── BlockerCenter      ← satu instance
```

- Screen **meminta**: `sheetCenter.present(...)`, `blockerCenter.show(...)`
- Screen tidak pernah memiliki overlay-nya sendiri
- Blocker memakai `zIndex`, **bukan** `fullScreenCover`
- Antrean eksplisit — dua bottom sheet bersamaan harus mustahil secara struktural

---

## List & pagination

List penerima memakai pagination. Komponen list harus mendukungnya sejak awal:

- Trigger load-more berbasis kemunculan item terakhir, bukan offset scroll
- State: `idle` / `loadingFirstPage` / `loaded` / `loadingNextPage` / `endReached` / `error`
- Loading halaman berikutnya **tidak boleh** mengganti konten yang sudah tampil dengan skeleton
- `ForEach` memakai ID stabil dari data, **jangan** `\.self`, **jangan** `UUID()` di dalam `body`

---

## Gaya kode

Dijaga `.swiftlint.yml`, bukan ingatan.

- **Identifier bahasa Inggris**, 3–35 karakter. Komentar, teks UI, dan pesan
  commit tetap Bahasa Indonesia.
- **Maksimum 50 baris per method.**
- **Maksimum 250 baris per file.**
- **Tes memakai swift-testing** (`import Testing`, `@Test`, `#expect`), bukan
  XCTest. Package memakai `swift-tools-version: 6.0` supaya SPM menautkan
  framework-nya. Deskripsi tes ditulis di `@Test("...")` sehingga nama fungsinya
  tetap pendek — deskripsi bukan alasan untuk nama 50 karakter.

Nama 1–2 huruf tidak menjelaskan apa-apa. Nama di atas 35 karakter hampir selalu
tanda fungsinya kebanyakan tugas — **potong fungsinya, jangan singkat namanya**.
Batas 50 dan 250 baris bekerja dengan cara yang sama: kalau mentok, yang salah
biasanya pembagian tanggung jawabnya, bukan batasnya.

`Tokens/` dikecualikan dari lint. Kalau keluaran generator melanggar aturan ini,
generatornya yang diperbaiki — file-nya jangan disentuh.

Package berjalan di Swift 6 language mode. Konsekuensi yang paling sering
menggigit: **tipe publik tidak dapat `Sendable` otomatis lintas modul** — kalau
sebuah tipe publik dipakai di konteks konkuren (termasuk `arguments:` di
swift-testing), conformance-nya harus ditulis eksplisit.

---

## Larangan yang berlaku di seluruh repo

Pola yang menyebabkan bug di codebase lama. Jangan reproduksi:

- `private let viewModel = SomeViewModel()` di dalam struct View → pakai `@StateObject`
- Memutasi objek observable di dalam `body` (assignment, wiring callback, setup) → pindahkan ke `onAppear`
- `.id(someChangingValue)` untuk memaksa refresh → cari penyebab sebenarnya
- `ZStack` berisi semua cabang lalu disembunyikan → pakai `if`
- `sink` tanpa `[weak self]`
- Mengunci Dynamic Type (`.dynamicTypeSize(.large)`)
- Dynamic color / asset catalog light-dark pair

---

## Cara kerja

- Satu komponen atau satu kontrak per commit
- Jalankan build + test dan preview sebelum menyatakan selesai

  `swift build` **tidak bisa dipakai** di repo ini: token generated meng-import
  UIKit, jadi build host macOS pasti gagal. Selalu lewat destination iOS:

  ```bash
  xcodebuild -scheme HostApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
  xcodebuild test -scheme DesignKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
  ```

  Kalau `xcodebuild` menolak dengan "requires Xcode": jalankan sekali
  `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- Kalau sebuah kebutuhan memaksa melanggar aturan di atas: **berhenti dan tanya**, jangan bikin escape hatch
- Kalau menulis komponen yang belum ada pemakainya: berhenti

---

## Urutan pengerjaan

1. **Package skeleton + HostApp**, `swift build` hijau
2. **Registrasi font** dari `Bundle.module`, diverifikasi tampil di HostApp
3. **Theme** — `ThemeResolver` 2 sumbu, `EnvironmentKey`, adapter SwiftUI. Hanya grup `text`, `surface`, `icon`, `outline`, `button`
4. **`ByonListRow`** dengan slot `@ViewBuilder` + preview (default & premier)
5. **`ByonAvatar`, `ByonChip`, `ByonChipBar`, `ByonSearchField`, `ByonSectionHeader`**
6. **Rakit ulang transfer landing** dari komponen di atas, data dummy + pagination
7. **`Route` + `AppNavigator` + StackRouter minimal** — push pertama
8. **`TransactionKit` kontrak + `nextStep` untuk 3 journey + unit test** — sebelum menulis UI
9. **Pipeline UI**: amount → summary → pin → receipt

**Langkah 6 adalah tes kelulusan DesignKit:** kalau layar itu bisa dirakit tanpa menambah komponen baru di tengah jalan, API-nya benar.

**Langkah 8 adalah tes kelulusan TransactionKit:** kalau tiga journey muat tanpa escape hatch, arsitekturnya benar.

---

## Status

| Langkah | Status |
|---|---|
| 1. Package skeleton + HostApp | **selesai** — build iOS hijau untuk ketiga package |
| 2. Registrasi font dari `Bundle.module` | **selesai** — diregistrasi di `AppDelegate`, terverifikasi tampil di simulator, 6 tes hijau |
| 3. Theme | belum — **terblokir**: `PrivateColorConstants` belum ada di `Tokens/` |
| 4–9 | belum |

Layar `SkeletonCheckScreen` di HostApp adalah bukti langkah 1 & 2: status
registrasi font dan perbandingan visual font DesignKit vs font sistem.

`RouteContract` dan `TransactionKit` masih berisi placeholder `internal` supaya
target-nya tidak kosong, dan **belum ditautkan ke HostApp** — belum ada yang
mengimpornya. Tautkan saat langkah 6/7 benar-benar memakainya, jangan sebelum itu.
