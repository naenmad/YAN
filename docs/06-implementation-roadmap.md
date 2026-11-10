# Implementation Roadmap & Sprint Checklist

**Project Name:** YAN (*YAN Another Notch*)  
**Target Milestone:** MVP Release v0.1  
**Estimated Timeframe:** 4 Sprints (Bertahap)  

---

## Phase 1: Foundation & Project Setup
Fokus: Membangun fondasi project macOS native, AppKit lifecycle, dan background daemon configuration.

- [ ] Inisialisasi Git repository dan struktur direktori project.
- [ ] Buat project Xcode macOS (Swift App) atau Swift Package executable.
- [ ] Konfigurasi `Info.plist`: Set `Application is agent (UIElement)` / `LSUIElement` ke `YES` (menghilangkan Dock Icon & Menu Bar Icon).
- [ ] Setup `AppDelegate` sebagai entry point siklus hidup aplikasi tanpa window bawaan Storyboard/Scene standar.
- [ ] Implementasi data store preferensi `NotchSettingsStore.swift` dengan penyimpanan `UserDefaults`.

---

## Phase 2: Core Notch Overlay & Bezier Rendering
Fokus: Membuat jendela transparan melayang (*floating overlay panel*) yang menempel di bagian atas layar MacBook Air M1.

- [ ] Buat subclass `NotchPanel: NSPanel` dengan konfigurasi:
  - Style mask: `[.borderless, .nonactivatingPanel]`
  - Window level: `.mainMenu + 1`
  - Collection behavior: `[.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`
  - Background: `NSColor.clear` & `isOpaque = false`
- [ ] Implementasi kalkulasi posisi tepat di tengah atas layar aktif (`NSScreen.main`).
- [ ] Buat `NotchShape.swift` menggunakan SwiftUI `Shape` & `Path` (Bezier curve kontinu untuk kelengkungan sudut bawah).
- [ ] Hubungkan dimensi notch (`width`, `height`, `cornerRadius`) ke `NotchSettingsStore`.
- [ ] Pasang `NSHostingView` ke dalam `NotchPanel` dan pastikan rendering visual hitam pekat tampil sempurna di layar.

---

## Phase 3: Interaction Engine (Hover, Click & Shortcuts)
Fokus: Menghidupkan interaksi notch agar dinamis dan responsif terhadap pergerakan mouse.

- [ ] Implementasi hover tracking:
  - Pasang `NSTrackingArea` atau SwiftUI `onHover` di area kanvas notch.
  - Tambahkan debouncing / slight delay (100–120ms) agar tidak memicu ekspansi saat kursor lewat sekilas.
- [ ] Tambahkan animasi ekspansi *Spring Animation* (`.spring(response: 0.35, dampingFraction: 0.7)`):
  - Skala lebar mengembang (+20% s/d +30%).
  - Skala tinggi mengembang (+30% s/d +50%).
- [ ] Tambahkan gesture click:
  - Left click: toggle expand / collapse.
  - Right click: Context menu untuk membuka *Settings* atau *Quit YAN*.
  - Double click: Shortcut instan membuka jendela Settings.
- [ ] Registrasi Global Hotkey (`Cmd + Shift + ,`) untuk membuka panel preferensi dari mana saja.

---

## Phase 4: Settings Window & System Integration
Fokus: Menghadirkan antarmuka kustomisasi yang nyaman digunakan pengguna.

- [ ] Buat `SettingsWindowController.swift` (`NSWindowController`) standar macOS untuk menampilkan form preferensi.
- [ ] Bangun UI `SettingsView.swift`:
  - Section Geometri: Slider Lebar (100–360px), Tinggi (20–54px), Corner Radius (4–28px).
  - Section Interaksi: Toggle *Expand on Hover*, Toggle *Expand on Click*.
  - Section Monitor: Toggle *Full Screen Behavior*, Toggle *Multi-Monitor Support*.
  - Tombol *Reset to Default* dan *Keluar / Quit*.
- [ ] Pasang observer notifikasi `NSApplication.didChangeScreenParametersNotification` agar notch otomatis menyesuaikan posisi jika resolusi layar atau susunan monitor berubah.
- [ ] Implementasi logika multi-monitor (jika opsi diaktifkan, buat instance `NotchPanel` di setiap monitor sekunder).

---

## Phase 5: Verification, Polish & Dogfooding
Fokus: Optimasi performa bare-metal, pengujian multi-space, dan pembersihan kode.

- [ ] **Memory & CPU Profiling:** Pastikan penggunaan CPU idle tetap < 0.2% di Instruments / Activity Monitor.
- [ ] **Desktop Spaces Verification:** Uji swipe Mission Control 3/4 jari; pastikan notch tetap statis tanpa flicker.
- [ ] **Fullscreen Mode Verification:** Uji saat aplikasi seperti Safari / Xcode masuk mode native fullscreen.
- [ ] Dokumentasikan petunjuk build (`README.md`) dan shortcut operasional.
