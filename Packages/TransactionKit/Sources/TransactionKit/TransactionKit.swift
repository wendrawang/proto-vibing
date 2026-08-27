// Placeholder supaya target tidak kosong — SPM menolak target tanpa file sumber.
//
// Kontrak sebenarnya (`TransactionStep`, `TransactionState`, `TransactionJourney`)
// masuk di langkah 8. Sengaja `internal`: sampai ada yang benar-benar dibutuhkan
// dari luar, modul ini tidak meng-export apa pun.
enum TransactionKitPlaceholder {}
