import DesignKit

/// Penanda modul TransactionKit.
///
/// Kontrak sebenarnya (`TransactionStep`, `TransactionState`, `TransactionJourney`)
/// masuk di langkah 8. Untuk sekarang tipe ini hanya membuktikan arah dependensi
/// `TransactionKit -> DesignKit` bisa dikompilasi.
public enum TransactionKit {
    public static let moduleName = "TransactionKit"

    /// Modul di bawah TransactionKit.
    public static let dependsOn = DesignKit.moduleName
}
