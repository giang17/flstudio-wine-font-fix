# 🎹 FL Studio Wine Font Fix

[![Wine](https://img.shields.io/badge/Wine-11.0-722F37)](https://www.winehq.org/)
[![FL Studio](https://img.shields.io/badge/FL%20Studio-2025-FF6600)](https://www.image-line.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Fix missing musical symbols (♭ ♯) in FL Studio running under Wine**

## 🎵 The Problem

When running FL Studio under Wine, **flat (♭) and sharp (♯) symbols** appear as tofu boxes (□) in the Piano Roll chord detection. 

| Before | After |
|--------|-------|
| ![Before](screenshots/before.png) | ![After](screenshots/after.png) |
| `D□`, `G□`, `A□ add6` | `B♭`, `Gdim /B♭` |

## 🔍 Root Cause

FL Studio uses DirectWrite low-level APIs (`GetGlyphIndices`) that bypass Wine's font fallback mechanism. The default fallback font (Cantarell) lacks music symbols.

| Font | ♭ Flat (U+266D) | ♯ Sharp (U+266F) |
|------|-----------------|------------------|
| Cantarell (Wine default) | ❌ Missing | ❌ Missing |
| Segoe UI | ❌ Missing | ✅ Present |
| **DejaVu Sans** | ✅ Present | ✅ Present |

## ✅ The Solution

Use **DejaVu Sans** (open-source, SIL License) renamed to "Segoe UI". No Microsoft fonts needed!

### Quick Install

```bash
# Clone the repo
git clone https://github.com/giang17/flstudio-wine-font-fix.git
cd flstudio-wine-font-fix

# Run the fix (uses default WINEPREFIX ~/.wine)
./fix-dejavu-as-segoeui.sh

# Or specify a custom WINEPREFIX
./fix-dejavu-as-segoeui.sh /path/to/your/wineprefix
```

### Requirements

- Python 3
- python3-fonttools
- DejaVu Sans font

```bash
# Ubuntu/Debian
sudo apt install python3-fonttools fonts-dejavu-core

# Or via pip
pip3 install fonttools
```

## 🔄 Restore Original

To remove the fix:

```bash
rm ~/.wine/drive_c/windows/Fonts/segoeui.ttf
rm ~/.wine/drive_c/windows/Fonts/segoeuib.ttf
```

## 🔧 Why This Works

1. FL Studio requests "Segoe UI" font via DirectWrite
2. Wine finds `segoeui.ttf` in the WINEPREFIX Fonts folder
3. The font's internal name is "Segoe UI" (renamed from DejaVu Sans)
4. DejaVu Sans natively contains both ♭ and ♯ symbols
5. Symbols render correctly!

### What Doesn't Work

We tested these approaches - they do NOT work because DirectWrite bypasses them: 

- ❌ Fontconfig aliases
- ❌ Wine Registry FontSubstitutes
- ❌ Wine dwrite.dll patches (per Wine devs: `GetGlyphIndices` can't do fallback)

### Environment Tested

- **Wine**: 11.0
- **OS**: Ubuntu 24.04 LTS
- **FL Studio**: 2025 (FL64.exe)

## 🐛 Related

- [Wine Bug #59252](https://bugs.winehq.org/show_bug.cgi?id=59252) - Original bug report with full analysis

## 📁 Files

| File | Description |
|------|-------------|
| `fix-dejavu-as-segoeui.sh` | Automated fix script |
| `screenshots/` | Before/after screenshots |

## 🤝 Contributing

Found another missing symbol? Have a fix for a different font? PRs welcome! 

## 📜 License

MIT License - See [LICENSE](LICENSE)

**Font Licensing:**
- This tool uses **DejaVu Sans** (licensed under [SIL Open Font License](https://dejavu-fonts.github.io/License.html)) and renames it to "Segoe UI" for technical compatibility purposes.
- "Segoe UI" is a trademark of Microsoft Corporation.
- The renamed font files are created locally on your system for **personal use only**.
- This project does not distribute any Microsoft fonts or modified font files.

## 🙏 Acknowledgments

- Wine developers for DirectWrite implementation
- Nikolay Sivov for DirectWrite expertise and guidance
- The Wine and FL Studio community
- DejaVu Fonts team for the excellent open-source font

---

**Made with ♭♯ for the music production community**
