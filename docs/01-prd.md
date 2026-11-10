# Product Requirements Document (PRD)

**Project Name:** YAN (*YAN Another Notch*)  
**Status:** Approved for Implementation (MVP v0.1)  
**Version:** 0.1.0-alpha  
**Date:** 2026-11-10  
**Author:** Pair Programming Lead Architect & System Engineer  

---

## 1. Problem Statement & Background

### 1.1 The Problem
Lini MacBook berbasis layar standar tanpa notch fisik (khususnya MacBook Air M1) memiliki bezel atas datar konvensional. Pengguna kehilangan potensi area atas layar sebagai jangkar visual dan hub interaktif serbaguna yang biasanya dimiliki oleh MacBook generasi notch atau konsep Dynamic Island. Banyak utilitas pihak ketiga yang ada di pasaran terlalu gemuk (*bloated*), membebani resource CPU/RAM, atau mewajibkan penempatan ikon di Menu Bar yang membuat status bar pengguna semakin penuh sesak.

### 1.2 The Solution
**YAN** menghadirkan simulator notch virtual mandiri yang:
1. Berjalan sebagai overlay elegan di bagian tengah atas layar monitor utama MacBook Air M1.
2. Dimensinya dapat diatur bebas (lebar, tinggi, kelengkungan sudut) agar sesuai dengan selera estetika pengguna.
3. Memiliki perilaku interaktif: mengembang (*expand*) saat disentuh kursor mouse (*hover*), saat diklik, atau saat shortcut ditekan.
4. Sepenuhnya *stealth*—tidak memakan tempat di menu bar macOS, dan jendela pengaturan (*Settings*) dapat dipanggil melalui klik kanan pada notch atau kombinasi tombol.

---

## 2. Goals & Success Metrics

### 2.1 Goals
1. Menghadirkan *Virtual Dynamic Notch* yang stabil, presisi, dan melekat statis di bagian atas layar melintasi seluruh Desktop Spaces.
2. Memberikan kebebasan kustomisasi visual (width, height, corner radius) melalui UI Settings yang intuitif.
3. Menjamin zero battery drain dan pemakaian memori yang sangat rendah (< 35 MB RAM saat idle).

### 2.2 Key Success Metrics (KPIs)
- **Idle CPU Usage:** < 0.2% CPU saat kursor diam di luar notch.
- **Hover Latency:** Respon ekspansi notch < 16ms (60–120 FPS tanpa frame drop di layar ProMotion/Retina).
- **Space Transition Persistence:** Notch tidak berkedip (*no flicker*) dan tidak bergeser saat gesture swipe 3/4 jari antar Desktop Spaces.

---

## 3. Scope & Non-Goals

### 3.1 In Scope (MVP v0.1)
- **Virtual Notch Overlay Canvas:** Rendering bentuk notch hitam pekat (*true black*) dengan lengkungan bezier halus di layar utama.
- **Geometry Customization:**
  - Slider Lebar (*Width*): Rentang dinamis 120px – 320px.
  - Slider Tinggi (*Height*): Rentang dinamis 24px – 48px (standar notch Apple ~32-34px).
  - Slider Kelengkungan Sudut (*Corner Radius*): 8px – 24px.
- **Interactivity Engine:**
  - Hover detection: Notch melebar (*smooth spring expansion*) saat pointer mendekat/berada di area notch.
  - Collapse on exit: Kembali ke ukuran *resting* saat mouse meninggalkan area.
  - Pilihan mode trigger di Settings: Hover, Click, atau Shortcut Keyboard.
- **Independent Settings Window:**
  - UI Pengaturan SwiftUI untuk mengatur ukuran, mode trigger, multi-monitor, dan toggle fullscreen.
  - Cara akses Settings: Klik kanan atau Double-click pada Notch, atau shortcut default `Cmd + Shift + ,`.
- **System Behavior Settings:**
  - Multi-Monitor Toggle: Hanya layar primer vs semua monitor.
  - Fullscreen Visibility Toggle: Tetap tampil atau sembunyikan saat aplikasi lain fullscreen.

### 3.2 Non-Goals (Ditunda untuk Fase Mendatang)
- ❌ Integrasi Now Playing Media Player (Spotify/Apple Music) — *Direncanakan v0.2*.
- ❌ File Drop Shelf / Clipboard History — *Direncanakan v0.3*.
- ❌ Toko tema / plugin pihak ketiga.
- ❌ Sinkronisasi Cloud (seluruh preferensi disimpan lokal via `UserDefaults`).

---

## 4. User Stories & Acceptance Criteria

### US-01: Mengatur Dimensi Notch Virtual
- **As an** pengguna MacBook Air M1,
- **I want to** mengatur lebar, tinggi, dan kelengkungan sudut notch melalui slider di Settings,
- **So that** bentuk notch tampak proporsional dan nyaman di mata saya.

**Acceptance Criteria:**
- Perubahan slider di Settings langsung terlihat secara *real-time* (live preview) pada notch overlay di layar.
- Nilai ukuran tersimpan secara persisten dan tidak kembali ke default saat aplikasi di-restart.

### US-02: Interaksi Hover & Expand
- **As an** pengguna,
- **I want to** notch mengembang halus saat kursor mouse menyentuhnya dan menciut kembali saat kursor pergi,
- **So that** notch terasa hidup (*dynamic & responsive*).

**Acceptance Criteria:**
- Notch mendeteksi kursor masuk (*mouseEntered*) dan keluar (*mouseExited*) dengan akurat.
- Transisi menggunakan interpolasi animasi *spring* yang lembut tanpa lag atau stutter.

### US-03: Akses Pengaturan Tanpa Menu Bar Icon
- **As an** pengguna yang menyukai kesederhanaan,
- **I want to** membuka jendela Settings dengan klik kanan pada notch atau menekan shortcut,
- **So that** menu bar macOS saya tetap bersih tanpa sampah ikon tambahan.

**Acceptance Criteria:**
- Menekan tombol kanan mouse di area notch memunculkan jendela Settings (atau context menu sederhana: Settings & Quit).
- Kombinasi hotkey global dapat memanggil jendela Settings kapan saja.

---

## 5. Functional Requirements

| ID | Fitur | Deskripsi Teknis |
| :--- | :--- | :--- |
| **FR-01** | Notch Window Lifecycle | Aplikasi berjalan sebagai background daemon (`LSUIElement = true`). Jendela overlay berstatus `NSPanel` transparan non-activating. |
| **FR-02** | Multi-Space Adhesion | Window collection behavior diset ke `.canJoinAllSpaces` dan `.stationary` sehingga tidak terpengaruh swipe Mission Control. |
| **FR-03** | Live Geometry Control | Menyediakan binding 2 arah antara `@AppStorage` dan slider geometri di antarmuka Settings. |
| **FR-04** | Hit-Testing & Hover Area | Menggunakan `NSTrackingArea` dengan opsi `.mouseEnteredAndExited` dan `.activeAlways`. |
| **FR-05** | Screen Re-anchoring | Memantau `NSApplication.didChangeScreenParametersNotification` untuk memusatkan kembali notch jika resolusi layar berubah. |

---

## 6. Non-Functional Requirements

- **Resource Consumption:** Penggunaan RAM di bawah 40MB dan CPU < 0.2% saat idle.
- **Rendering Performance:** 60 FPS pada layar standar, 120 FPS pada layar ProMotion.
- **Usability:** Antarmuka Settings menggunakan styling asli macOS (Human Interface Guidelines).
- **Code Quality:** Arsitektur modular menggunakan Swift Modern Concurrency & Model-View decoupling.
