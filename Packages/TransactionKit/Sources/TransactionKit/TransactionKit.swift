import DesignKit

/// Penanda modul TransactionKit.
///
/// Kontrak sebenarnya (`TransactionStep`, `TransactionState`, `TransactionJourney`)
/// masuk di langkah 8. Untuk sekarang tipe ini hanya membuktikan arah dependensi
/// `TransactionKit -> DesignKit -> RouteContract` bisa dikompilasi.
public enum TransactionKit {
    public static let moduleName = "TransactionKit"

    /// Modul di bawah TransactionKit, dibaca lewat DesignKit — bukan lewat
    /// import langsung ke RouteContract. Membuktikan rantainya transitif.
    public static let dependsOn = DesignKit.moduleName
}
