# Design Guidelines & UI Specifications

**Project Name:** YAN (*YAN Another Notch*)  
**Design Philosophy:** Apple Native Stealth, Pure Geometry, Zero Clutter  
**Last Updated:** 2026-11-10  

---

## 1. Design Principles

1. **Native Harmony:** Bentuk notch harus terasa seperti bagian fisik dari hardware MacBook—menggunakan kelengkungan kontinu (*squircle / superellipse*) bukan sudut kaku biasa.
2. **Invisible Utility:** Tidak ada elemen UI yang terlihat saat idle kecuali siluet notch itu sendiri. Tidak ada ikon tray menu bar, tidak ada dock bounce.
3. **Fluid Physics:** Semua transisi ukuran wajib menggunakan kurva *Spring Animation* yang organik dan responsif terhadap gerakan kursor pengguna.

---

## 2. Notch Visual Anatomy

### 2.1 Resting vs. Hover State

```text
[ Resting State: Sesuai Ukuran Bezel Standar ]
┌──────────────────────────────────────────────┐
│  ╭────────────────────────────────────────╮  │ <── Menempel di tepi atas layar (Y=0)
│  │               YAN NOTCH                │  │ <── Height: 32px | Width: 180px
└──╯                                        ╰──┘ <── Continuous Corner Radius: 14px

                         ▼ (Cursor Hover)

[ Expanded State: Mengembang Halus dengan Spring Animation ]
┌────────────────────────────────────────────────────────┐
│  ╭──────────────────────────────────────────────────╮  │
│  │                                                  │  │ <── Height: 48px (+50%)
│  │                   YAN NOTCH                      │  │ <── Width: 260px (+44%)
│  │             (Interactive Canvas)                 │  │
└──╯                                                  ╰──┘
```

### 2.2 Curvature & Bezier Math
Bentuk notch dibuat menggunakan jalur Bezier kustom:
- Sisi atas menempel rata dengan bezel monitor (`originY = screen.maxY`).
- Sudut bawah kiri dan kanan dibentuk dengan kurva `addQuadCurve` atau `addCurve` untuk menghasilkan *bezel ear curve* (telinga notch) yang menyatu alami dengan menu bar macOS.

---

## 3. Color Tokens & Theme

| Token | Nilai Hex / Semantic | Penggunaan |
| :--- | :--- | :--- |
| `Notch.Surface` | `#000000` (True Black) | Warna dasar notch virtual agar menyatu dengan bezel fisik layar |
| `Notch.Border` | `rgba(255, 255, 255, 0.08)` | Garis tepi subtil (0.5pt) saat mode gelap agar notch terlihat tegas |
| `Settings.Background` | `NSColor.windowBackgroundColor` | Latar belakang jendela preferensi (adaptif dark/light mode) |
| `Accent.Color` | `Color.accentColor` (System Blue) | Slider thumb, active switch toggles, dan primary button |
| `Text.Primary` | `Color.primary` | Label pengaturan utama di jendela Settings |
| `Text.Secondary` | `Color.secondary` | Keterangan pembantu di bawah slider |

---

## 4. Typography Scale

Mengikuti Apple Human Interface Guidelines dengan font keluarga sistem:
- **Settings Section Title:** `.headline` (SF Pro Display Semibold, 13pt)
- **Settings Label:** `.body` (SF Pro Text Regular, 13pt)
- **Dimension Value / Badge:** `.callout.monospacedDigit()` (SF Pro 12pt Monospaced, memudahkan pembacaan angka pixel)
- **Caption / Help Text:** `.footnote` (SF Pro Text Regular, 11pt, secondary color)

---

## 5. Settings Window Layout Architecture

Jendela Settings berukuran standar `440px x 380px`, dengan navigasi vertikal atau grouped form yang rapi:

```text
┌──────────────────────────────────────────────────────────────┐
│  ⚙️ YAN Settings                                       [X]  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  GEOMETRI NOTCH                                              │
│  ├─ Lebar (Width)        [───●──────────]  180 px            │
│  ├─ Tinggi (Height)      [─────●────────]   32 px            │
│  └─ Corner Radius        [───●──────────]   14 px            │
│                                                              │
│  INTERAKSI & TRIGGER                                         │
│  ├─ Expand saat Hover    [ Toggle: ON  ]                     │
│  ├─ Expand saat Klik     [ Toggle: OFF ]                     │
│  └─ Shortcut Pengaturan  [ ⌘ + ⇧ + ,   ]                     │
│                                                              │
│  TAMPILAN & MONITOR                                          │
│  ├─ Tampil saat Fullscreen     [ Toggle: ON  ]               │
│  └─ Aktif di Monitor Eksternal [ Toggle: OFF ]               │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  [ Reset Default ]                                [ Keluar ] │
└──────────────────────────────────────────────────────────────┘
```

### Akses Cepat ke Settings
Karena aplikasi tidak memiliki ikon Menu Bar:
1. **Right-Click pada Notch:** Memunculkan context menu popover (*Settings...*, *Quit YAN*).
2. **Double-Click pada Notch:** Langsung membuka jendela Settings.
3. **Global Shortcut:** `Cmd + Shift + ,` untuk membuka jendela kapan pun dari aplikasi apa pun.
