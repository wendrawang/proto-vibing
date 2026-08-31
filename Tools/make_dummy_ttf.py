#!/usr/bin/env python3
"""Generator TTF dummy untuk memverifikasi mekanisme registrasi font DesignKit.

Setiap glyph adalah kotak berongga. Kalau font berhasil diregistrasi, teks
tampil sebagai deretan kotak; kalau gagal, iOS fallback ke font sistem dan
teksnya terbaca normal. Sinyal visual biner, tanpa perlu menebak.
"""
import struct, sys

FAMILY   = "PlaygroundDummy"
SUBFAM   = "Regular"
PSNAME   = "PlaygroundDummy-Regular"
UPM      = 1000
ASC, DESC = 800, -200
STROKE   = 70
FIRST, LAST = 0x20, 0x7E

u16 = lambda v: struct.pack(">H", v & 0xFFFF)
s16 = lambda v: struct.pack(">h", v)
u32 = lambda v: struct.pack(">I", v & 0xFFFFFFFF)

def metrics(ch):
    """(advance, x0, y0, x1, y1); y1 == y0 berarti glyph kosong."""
    if ch == " ":
        return (500, 0, 0, 0, 0)
    if ch in ".,:;'\"`":
        adv, lo, hi = 320, 0, 200
    elif ch in "-_=+*^~<>":
        adv, lo, hi = 500, 220, 480
    elif ch.isupper() or ch.isdigit() or ch in "!?#$%&@()[]{}/\\|":
        adv, lo, hi = 620, 0, 700
    elif ch in "bdfhklt":
        adv, lo, hi = 560, 0, 700
    elif ch in "gjpqy":
        adv, lo, hi = 560, -200, 500
    else:
        adv, lo, hi = 560, 0, 500
    return (adv, 60, lo, adv - 60, hi)

def simple_glyph(contours):
    if not contours:
        return b""
    xs = [p[0] for c in contours for p in c]
    ys = [p[1] for c in contours for p in c]
    out = s16(len(contours)) + s16(min(xs)) + s16(min(ys)) + s16(max(xs)) + s16(max(ys))
    end = -1
    for c in contours:
        end += len(c)
        out += u16(end)
    out += u16(0)                                   # instructionLength
    out += bytes([0x01]) * sum(len(c) for c in contours)  # semua on-curve, delta int16
    for idx in (0, 1):
        prev = 0
        for c in contours:
            for p in c:
                out += s16(p[idx] - prev)
                prev = p[idx]
    return out

def hollow_box(x0, y0, x1, y1):
    if y1 <= y0:
        return []
    # Kontur luar searah jarum jam (koordinat font, y ke atas).
    outer = [(x0, y0), (x0, y1), (x1, y1), (x1, y0)]
    ix0, iy0, ix1, iy1 = x0 + STROKE, y0 + STROKE, x1 - STROKE, y1 - STROKE
    if ix1 - ix0 < 50 or iy1 - iy0 < 50:
        return [outer]
    # Kontur dalam berlawanan arah jarum jam supaya jadi lubang.
    inner = [(ix0, iy0), (ix1, iy0), (ix1, iy1), (ix0, iy1)]
    return [outer, inner]

chars = [chr(c) for c in range(FIRST, LAST + 1)]
glyphs = [(620, hollow_box(60, 0, 560, 700))]           # gid 0 = .notdef
for ch in chars:
    adv, x0, y0, x1, y1 = metrics(ch)
    glyphs.append((adv, hollow_box(x0, y0, x1, y1)))
num_glyphs = len(glyphs)

# --- glyf + loca -------------------------------------------------------------
glyf, loca = b"", [0]
for _, contours in glyphs:
    d = simple_glyph(contours)
    d += b"\0" * ((4 - len(d) % 4) % 4)
    glyf += d
    loca.append(len(glyf))
loca_tbl = b"".join(u32(o) for o in loca)

# --- hmtx / hhea -------------------------------------------------------------
advances = [g[0] for g in glyphs]
lsbs = [(min(p[0] for c in g[1] for p in c) if g[1] else 0) for g in glyphs]
hmtx = b"".join(u16(a) + s16(l) for a, l in zip(advances, lsbs))
all_pts = [p for g in glyphs for c in g[1] for p in c]
xmin, ymin = min(p[0] for p in all_pts), min(p[1] for p in all_pts)
xmax, ymax = max(p[0] for p in all_pts), max(p[1] for p in all_pts)
hhea = (u32(0x00010000) + s16(ASC) + s16(DESC) + s16(0) + u16(max(advances))
        + s16(xmin) + s16(min(a - x for a, x in zip(advances, [max((p[0] for c in g[1] for p in c), default=0) for g in glyphs])))
        + s16(xmax) + s16(1) + s16(0) + s16(0) + s16(0) * 4 + s16(0) + u16(num_glyphs))

# --- maxp / head / post ------------------------------------------------------
max_pts = max((sum(len(c) for c in g[1]) for g in glyphs), default=0)
max_cnt = max((len(g[1]) for g in glyphs), default=0)
maxp = (u32(0x00010000) + u16(num_glyphs) + u16(max_pts) + u16(max_cnt)
        + u16(0) * 2 + u16(2) + u16(0) * 8)
created = 3849984000  # detik sejak 1904-01-01, tanggal tetap supaya build reproducible
head = (u32(0x00010000) + u32(0x00010000) + u32(0) + u32(0x5F0F3CF5) + u16(0x0003)
        + u16(UPM) + struct.pack(">q", created) + struct.pack(">q", created)
        + s16(xmin) + s16(ymin) + s16(xmax) + s16(ymax)
        + u16(0) + u16(8) + s16(2) + s16(1) + s16(0))
post = u32(0x00030000) + u32(0) + s16(-100) + s16(50) + u32(0) + u32(0) * 4

# --- cmap format 4 (satu segmen ASCII + segmen penutup) ----------------------
seg = [(FIRST, LAST, (1 - FIRST) & 0xFFFF), (0xFFFF, 0xFFFF, 1)]
sub = (u16(4) + u16(0) + u16(0) + u16(len(seg) * 2) + u16(4) + u16(1) + u16(0)
       + b"".join(u16(s[1]) for s in seg) + u16(0)
       + b"".join(u16(s[0]) for s in seg)
       + b"".join(u16(s[2]) for s in seg)
       + b"".join(u16(0) for _ in seg))
sub = sub[:2] + u16(len(sub)) + sub[4:]
cmap = (u16(0) + u16(2)
        + u16(0) + u16(3) + u32(4 + 2 * 8)
        + u16(3) + u16(1) + u32(4 + 2 * 8) + sub)

# --- name --------------------------------------------------------------------
strings = {1: FAMILY, 2: SUBFAM, 3: PSNAME + "; DesignKit placeholder",
           4: FAMILY + " " + SUBFAM, 5: "Version 1.000", 6: PSNAME}
records, storage = [], b""
for plat, enc, lang, encode in ((1, 0, 0, lambda s: s.encode("mac_roman")),
                                (3, 1, 0x409, lambda s: s.encode("utf-16-be"))):
    for nid in sorted(strings):
        b = encode(strings[nid])
        records.append((plat, enc, lang, nid, len(b), len(storage)))
        storage += b
records.sort()
name = u16(0) + u16(len(records)) + u16(6 + 12 * len(records))
name += b"".join(u16(r[0]) + u16(r[1]) + u16(r[2]) + u16(r[3]) + u16(r[4]) + u16(r[5])
                 for r in records)
name += storage

# --- OS/2 v4 -----------------------------------------------------------------
os2 = (u16(4) + s16(sum(advances) // len(advances)) + u16(400) + u16(5) + u16(0)
       + s16(650) + s16(600) + s16(0) + s16(75)
       + s16(650) + s16(600) + s16(0) + s16(350)
       + s16(50) + s16(250) + s16(0)
       + bytes([2, 0, 5, 0, 0, 0, 0, 0, 0, 0])
       + u32(1) + u32(0) + u32(0) + u32(0) + b"PLAY"
       + u16(0x0040) + u16(FIRST) + u16(LAST)
       + s16(ASC) + s16(DESC) + s16(200) + u16(1000) + u16(200)
       + u32(1) + u32(0) + s16(500) + s16(700) + u16(0) + u16(FIRST) + u16(1))

tables = {b"OS/2": os2, b"cmap": cmap, b"glyf": glyf, b"head": head, b"hhea": hhea,
          b"hmtx": hmtx, b"loca": loca_tbl, b"maxp": maxp, b"name": name, b"post": post}

def checksum(d):
    d += b"\0" * ((4 - len(d) % 4) % 4)
    return sum(struct.unpack(">%dI" % (len(d) // 4), d)) & 0xFFFFFFFF

n = len(tables)
sr = (2 ** (n.bit_length() - 1)) * 16
es = n.bit_length() - 1
font = u32(0x00010000) + u16(n) + u16(sr) + u16(es) + u16(n * 16 - sr)
offset = 12 + 16 * n
dirent, body, head_off = b"", b"", None
for tag in sorted(tables):
    d = tables[tag]
    if tag == b"head":
        head_off = offset
    dirent += tag + u32(checksum(d)) + u32(offset) + u32(len(d))
    pad = b"\0" * ((4 - len(d) % 4) % 4)
    body += d + pad
    offset += len(d) + len(pad)
font += dirent + body
adj = (0xB1B0AFBA - checksum(font)) & 0xFFFFFFFF
font = font[:head_off + 8] + u32(adj) + font[head_off + 12:]

open(sys.argv[1], "wb").write(font)
print(f"{sys.argv[1]}: {len(font)} bytes, {num_glyphs} glyphs, PostScript name {PSNAME!r}")
