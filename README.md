# 🎹 FL Studio Wine Font Fix

[![Wine](https://img.shields.io/badge/Wine-11.0-722F37)](https://www.winehq.org/)
[![FL Studio](https://img.shields.io/badge/FL%20Studio-2025-FF6600)](https://www.image-line.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Fix missing musical symbols (♭ ♮ ♯) in FL Studio running under Wine**

## 🎵 The Problem

When running FL Studio under Wine, **flat symbols (♭)** appear as tofu boxes (□), while **sharp symbols (♯)** display correctly.

| Before | After |
|--------|-------|
| ![Before](screenshots/before.png) | ![After](screenshots/after.png) |
| `E add□9`, `A□`, `B□` | `E add♭9`, `A♭`, `B♭` |

## 🔍 Root Cause

After extensive debugging, we discovered:

| Font | ♭ Flat (U+266D) | ♯ Sharp (U+266F) |
|------|-----------------|------------------|
| **Segoe UI** | ❌ MISSING | ✅ Present |
| Segoe UI Symbol | ✅ Present | ✅ Present |

**Segoe UI contains the sharp symbol but NOT the flat symbol!**

Normally, Wine's font fallback would find the missing glyph in another font. However, FL Studio uses low-level DirectWrite APIs (`GetGlyphIndices`) that bypass font fallback entirely.

## ✅ The Solution

This fix copies the missing glyphs from **Segoe UI Symbol** into **Segoe UI**, so FL Studio finds them directly.

### Quick Install

```bash
# Clone the repo
git clone https://github.com/giang17/flstudio-wine-font-fix.git
cd flstudio-wine-font-fix

# Run the fix (uses default WINEPREFIX ~/.wine)
./fix-flat-symbol.sh

# Or specify a custom WINEPREFIX
./fix-flat-symbol.sh /path/to/your/wineprefix
```

### Requirements

- Python 3
- python3-fonttools

```bash
# Ubuntu/Debian
sudo apt install python3-fonttools

# Or via pip
pip3 install fonttools
```

### Manual Installation

If you prefer to run the Python script directly:

```bash
python3 patch-segoeui.py ~/.wine
```

## 🔄 Restore Original Font

The script automatically creates a backup. To restore:

```bash
cp ~/.wine/drive_c/windows/Fonts/segoeui.ttf.backup \
   ~/.wine/drive_c/windows/Fonts/segoeui.ttf
```

## 📋 What Gets Patched

| Symbol | Unicode | Name |
|--------|---------|------|
| ♭ | U+266D | MUSIC FLAT SIGN |
| ♮ | U+266E | MUSIC NATURAL SIGN |

The sharp symbol (♯ U+266F) is already present in Segoe UI, so no patching is needed.

## 🔧 Technical Details

### Why Font Fallback Doesn't Work

FL Studio uses these DirectWrite APIs:
- ✅ `IDWriteFontFace::GetGlyphIndices` (direct glyph lookup)
- ✅ `IDWriteFactory::CreateGlyphRunAnalysis` (direct rendering)

FL Studio does **NOT** use:
- ❌ `IDWriteTextLayout`
- ❌ `IDWriteFontFallback::MapCharacters`

Without calling `MapCharacters`, Wine's font fallback system is never triggered.

### Environment Tested

- **Wine**: 11.0
- **OS**: Ubuntu 24.04 LTS
- **FL Studio**: 2025 (FL64.exe)
- **Fonts**: Segoe UI, Segoe UI Symbol

## 🐛 Related

- [Wine Bug #59252](https://bugs.winehq.org/show_bug.cgi?id=59252) - Original bug report

## 📁 Files

| File | Description |
|------|-------------|
| `fix-flat-symbol.sh` | All-in-one bash script |
| `patch-segoeui.py` | Python patching script |
| `screenshots/` | Before/after screenshots |

## 🤝 Contributing

Found another missing symbol? Have a fix for a different font? PRs welcome!

## 📜 License

MIT License - See [LICENSE](LICENSE)

## 🙏 Acknowledgments

- Wine developers for DirectWrite implementation
- Nikolay Sivov for DirectWrite expertise
- The Wine and FL Studio community

---

**Made with ♭♮♯ for the music production community**