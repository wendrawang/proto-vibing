// Tetap bersarang di `DesignKitFonts` supaya nama pemakainya tidak berubah,
// tapi tinggal di file sendiri: satu tipe, satu file.
extension DesignKitFonts {

    /// Hasil satu registrasi font.
    ///
    /// Inilah bedanya dengan `_ = CTFontManagerRegisterFontsForURL(...)`: font
    /// yang gagal terdaftar tidak melempar apa pun dan tidak menghentikan app —
    /// dia cuma jadi teks yang diam-diam memakai font sistem. Kalau hasilnya
    /// dibuang, tidak ada satu pun sinyal bahwa itu terjadi.
    public struct RegistrationResult: Equatable, Sendable {
        public let fontName: String
        public let isRegistered: Bool
        /// Alasan gagal; `nil` kalau berhasil.
        public let failureReason: String?

        public init(fontName: String, isRegistered: Bool, failureReason: String?) {
            self.fontName = fontName
            self.isRegistered = isRegistered
            self.failureReason = failureReason
        }
    }
}
