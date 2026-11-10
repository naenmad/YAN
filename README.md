# YAN — YAN Another Notch

> **Virtual Dynamic Notch** interaktif untuk Mac tanpa notch fisik (khususnya MacBook Air M1/M2/M3).

---

## ✨ Fitur v0.1 (MVP)

- 🖥️ **Virtual Notch Canvas:** Overlay hitam pekat (*true black*) dengan lengkungan sudut halus (*continuous corner curvature*) menempel di bagian atas layar.
- 🎚️ **Kustomisasi Geometri:** Atur lebar (*Width*), tinggi (*Height*), *Corner Radius*, dan *Top Ear Radius* secara langsung dengan live preview.
- 🎯 **Interaksi Responsif:**
  - **Hover Expand:** Notch mengembang dinamis saat kursor mouse menyentuhnya (dengan animasi *spring* fluid).
  - **Click Expand:** Opsi ekspansi saat diklik.
- 👻 **Stealth & Clean:** **Tanpa ikon di Menu Bar** dan **tanpa Dock icon** (`LSUIElement = true`).
- ⚙️ **Akses Cepat Pengaturan (Settings):**
  - **Double-click** pada Notch
  - **Right-click** pada Notch -> pilih *Settings...*
  - **Global Shortcut:** `Cmd + Shift + ,`
- 🌌 **Multi-Space Adhesion:** Menggunakan AppKit `NSPanel` dengan `.canJoinAllSpaces` sehingga tetap menempel statis saat swipe antar Desktop Spaces.

---

## 🚀 Cara Menjalankan

### Melalui Terminal / Makefile
```bash
# Build dan jalankan aplikasi YAN
make build
make run

# Buka project di Xcode
make open
```

### Melalui Swift Package Manager
```bash
swift run YAN
```

---

## 📖 Dokumentasi Arsitektur

Dokumentasi lengkap hasil framework **C.L.E.A.R** tersedia di folder [`docs/`](./docs/):
- [00-index.md](./docs/00-index.md) — Master Index & Architecture Overview
- [01-prd.md](./docs/01-prd.md) — Product Requirements Document
- [02-user-personas.md](./docs/02-user-personas.md) — User Persona & Journey Map
- [03-system-architecture.md](./docs/03-system-architecture.md) — Technical Specifications & AppKit/SwiftUI Architecture
- [04-database-schema.md](./docs/04-database-schema.md) — Local Persistence & State Schema
- [05-design-guidelines.md](./docs/05-design-guidelines.md) — Visual Anatomy & Design Tokens
- [06-implementation-roadmap.md](./docs/06-implementation-roadmap.md) — Sprint Checklist & Execution Roadmap
