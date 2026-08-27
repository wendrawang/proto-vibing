import RouteContract

/// Penanda modul DesignKit.
///
/// Theme, primitives, dan patterns menyusul di langkah 3 ke atas.
public enum DesignKit {
    public static let moduleName = "DesignKit"

    /// Modul di bawah DesignKit. Arahnya searah: DesignKit boleh menyebut
    /// RouteContract, tidak sebaliknya.
    public static let dependsOn = RouteContract.moduleName
}
