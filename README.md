# FileCraft

A modern macOS menu-bar utility, floating drop shelf ("Float"), and radial petal conversion wheel for instant file transformations, tools, and actions.

---

## 🚀 Fitur Unggulan FileCraft

1. **Model Aplikasi Aksesori Menu Bar (`LSUIElement = true`)**:
   - Beroperasi sebagai background daemon tanpa memakan dock icon (`ActivationPolicy.accessory`).
   - Menyediakan status menu bar: *"FileCraft is ready"* / *"FileCraft is working"*.
   
2. **Floating Drop Shelf ("Float")**:
   - Shelf melayang berpenampilan *ultra-thin glass material* yang menempel di tepi layar macOS untuk menampung file sementara selama drag-and-drop antar aplikasi, spasi layar penuh, atau Finder.

3. **Radial Petal Fan Wheel ("Conversion Wheel / Tools Wheel / Actions Wheel")**:
   - Muncul di posisi kursor saat drag shortcut (`DragGestureMonitor` membaca modifier key).
   - Menampilkan menu kelopak radial transparan dengan animasi pegas, glow warna, dan umpan balik audio.

4. **Koleksi 26 Alat Kreatif, Media & Privasi**:
   - **Photo Editor**: Pengaturan exposure, contrast, saturation, sharpness, rotasi 90°, flip.
   - **Crop Image**: Pemotongan rasio aspek interaktif (1:1, 4:3, 16:9, 9:16).
   - **Redact Image**: Penyensoran teks/wajah sensitif dengan kotak hitam seketika.
   - **Annotate Image**: Tanda panah, kotak, teks catatan, pensil bebas dengan palet warna.
   - **Mockup Frame Studio**: Kanvas gradien, padding, sudut lengkung, dan bayangan lembut.
   - **Photo Collage**: Penggabungan multi-foto menjadi kolase grid.
   - **Video Tools**: Trim video, Crop video, Mute audio, Snapshot frame, Speed 2x, Split, Join.
   - **Audio Tools**: Normalisasi level peak volume, Stereo to Mono, Ekstraksi audio.
   - **Privacy & Metadata Cleaner**: Menghapus EXIF, GPS location, dan info kamera.
   - **PDF Organizer**: Mengatur urutan halaman, rotasi, split PDF, dan merge PDF.
   - **Batch Format Converter**: Konversi gambar massal (PNG, JPEG, WEBP, HEIC, TIFF, AVIF, BMP, PDF) dengan kompresi kualitas.

---

## 🚀 Cara Menjalankan Aplikasi

Aplikasi telah berhasil dikompilasi ke dalam bundle resmi macOS:
`build/FileCraft.app`

### 1. Menjalankan langsung via Finder / Terminal:
```bash
open build/FileCraft.app
```

### 2. Membangun ulang (Rebuild):
```bash
./bundle.sh
```

---

## ⌨️ Pintasan Keyboard Global

| Shortcut | Aksi |
| :--- | :--- |
| **⌥ ⌘ F** | Buka / Tutup Floating Drop Shelf |
| **⌥ ⌘ W** | Buka Radial Petal Tool Wheel di posisi kursor |
| **⌥ ⌘ I** | Buka Mockup Frame Studio |
| **⌥ ⌘ M** | Buka Privacy & EXIF Metadata Cleaner |
| **⌥ ⌘ P** | Buka PDF Organizer Studio |
| **⌥ ⌘ Q** | Buka QR Code & OCR Studio |
| **⌥ ⌘ C** | Buka Batch Media Converter |
| **⌘ ,** | Buka Pengaturan (Settings) |
| **⌘ Q** | Keluar dari FileCraft |
| **Tahan ⇧ Shift saat Drag** | Otomatis memunculkan **Converter Wheel** (PNG, WEBP, HEIC, TIFF, AVIF, BMP, PDF) — drop langsung konversi in-place seketika! |
| **Tahan ⌘ Command saat Drag** | Otomatis memunculkan **26 Tools Wheel** (Edit, Crop, Redact, Annotate, Compress, Video Tools, PDF Tools, dll.) |
| **Tahan ⌃ Control saat Drag** | Otomatis memunculkan **6 File Actions Wheel** (AirDrop, Float Shelf, Copy, Move, Copy Path, Terminal) |
