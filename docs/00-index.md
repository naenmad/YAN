# YAN (YAN Another Notch) — Documentation Master Index

**Project Name:** YAN (*YAN Another Notch*)  
**Platform:** macOS 13.0+ (Ventura, Sonoma, Sequoia & later)  
**Target Hardware:** Mac tanpa physical notch (e.g., MacBook Air M1/M2/M3) & Mac dengan notch fisik  
**Tech Stack:** Native Swift & SwiftUI (AppKit `NSPanel` Floating Engine)  
**Status:** Inception & Architectural Blueprint  
**Last Updated:** 2026-11-10  

---

## 📌 Executive Summary

**YAN** (*YAN Another Notch*) adalah aplikasi utilitas macOS *lightweight* dan *stealthy* yang menghadirkan **Virtual Dynamic Notch** interaktif pada Mac tanpa notch fisik (khususnya MacBook Air M1). 

Berbeda dari aplikasi menu bar pada umumnya, YAN dirancang **tanpa ikon menu bar** (*zero status bar clutter*). Notch bertindak sebagai kanvas dinamis yang menempel statis di bagian tengah atas layar, melintasi Desktop Spaces tanpa bergeser, dan dapat merespons gesture hover, klik, atau shortcut keyboard global. Di fase MVP, YAN fokus pada fondasi rendering notch yang presisi (lebar, tinggi, kelengkungan sudut), interaksi ekspansi yang mulus (*spring physics*), serta panel pengaturan (*Settings*) yang komprehensif.

---

## 📚 Document Registry

Klik tautan di bawah ini untuk mengakses detail spesifikasi arsitektur:

1. [01-prd.md](file:///Users/mac/Developer/YAN%20Another%20Notch/docs/01-prd.md)  
   *Product Requirements Document*: Latar belakang, batasan MVP, user stories, functional & non-functional requirements.
2. [02-user-personas.md](file:///Users/mac/Developer/YAN%20Another%20Notch/docs/02-user-personas.md)  
   *Target User & Journey*: Persona kreator/power-user, skenario penggunaan harian, dan mapping interaksi.
3. [03-system-architecture.md](file:///Users/mac/Developer/YAN%20Another%20Notch/docs/03-system-architecture.md)  
   *Technical Architecture*: Arsitektur AppKit `NSPanel`, integrasi SwiftUI `NSHostingView`, tracking mouse, window level, dan event loop.
4. [04-database-schema.md](file:///Users/mac/Developer/YAN%20Another%20Notch/docs/04-database-schema.md)  
   *State & Storage Schema*: Struktur data preferensi pengguna (`NotchPreferences`), reactive store via `@AppStorage` / `UserDefaults`, dan Swift models.
5. [05-design-guidelines.md](file:///Users/mac/Developer/YAN%20Another%20Notch/docs/05-design-guidelines.md)  
   *Design Guidelines & UI Tokens*: Geometri notch (*continuous corner curvature*), bezier path math, spring animation tokens, dan layout jendela Settings.
6. [06-implementation-roadmap.md](file:///Users/mac/Developer/YAN%20Another%20Notch/docs/06-implementation-roadmap.md)  
   *Execution Checklist*: Langkah demi langkah implementasi teknis mulai dari inisialisasi Xcode project hingga rilis internal v0.1.

---

## 🏗️ Quick Tech Stack Matrix

| Layer | Pilihan Teknologi | Alasan Pemilihan |
| :--- | :--- | :--- |
| **Language** | Swift 5.9+ / Swift 6 | Memory safe, zero overhead, performa native Apple Silicon |
| **UI Framework** | SwiftUI | UI deklaratif, *smooth layout transitions*, modern state bindings |
| **Window System** | AppKit (`NSPanel`, `NSWindow`) | Dukungan *non-activating panel*, `.canJoinAllSpaces`, `.screenSaver` / `.mainMenu` window level |
| **Interaction** | `NSTrackingArea` / `NSEvent.addLocalMonitor` | Tracking presisi mouse hover di tepi atas layar tanpa lag |
| **State Storage** | `UserDefaults` + `@Observable` / `@AppStorage` | Ringan, reaktif, tanpa dependensi database eksternal |
| **App Footprint** | Background Agent (`LSUIElement = true`) | Tanpa dock icon & tanpa menu bar icon (dibuka via gesture/hotkey) |
