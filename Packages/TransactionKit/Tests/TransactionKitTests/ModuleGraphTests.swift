import XCTest

@testable import TransactionKit

final class ModuleGraphTests: XCTestCase {

    /// Langkah 1 hanya membuktikan arah dependensi. Kontrak transaksi dan tes
    /// `nextStep` menyusul di langkah 8.
    func testTransactionKitMelihatDesignKitSecaraTransitif() {
        XCTAssertEqual(TransactionKit.moduleName, "TransactionKit")
        XCTAssertEqual(TransactionKit.dependsOn, "DesignKit")
    }
}
