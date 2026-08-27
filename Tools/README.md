# Tools

## `make_dummy_ttf.py`

Menghasilkan `PlaygroundDummy-Regular.ttf` — font placeholder yang dipakai untuk
memverifikasi mekanisme registrasi font dari `Bundle.module` sebelum font asli
masuk.

```bash
python3 Tools/make_dummy_ttf.py \
  Packages/DesignKit/Sources/DesignKit/Resources/Fonts/PlaygroundDummy-Regular.ttf
```

Setiap glyph sengaja berbentuk kotak berongga: kalau registrasi berhasil teks
tampil sebagai deretan kotak, kalau gagal iOS fallback ke font sistem dan teksnya
terbaca normal. Sinyal biner, tanpa perlu menebak.

**Hapus folder ini** begitu font asli sudah masuk ke `Resources/Fonts` — tidak ada
lagi yang memakainya.
