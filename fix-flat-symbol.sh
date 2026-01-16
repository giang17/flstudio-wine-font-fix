#!/bin/bash
#
# FL Studio Wine - Flat Symbol Fix
# ================================
# This script fixes the missing flat symbol (♭) in FL Studio running under Wine.
#
# Problem: FL Studio shows tofu boxes (□) instead of flat symbols (♭)
#          while sharp symbols (♯) display correctly.
#
# Cause:   Segoe UI font contains ♯ (U+266F) but NOT ♭ (U+266D).
#          FL Studio uses low-level DirectWrite APIs that bypass font fallback.
#
# Solution: Copy the flat glyph from Segoe UI Symbol into Segoe UI.
#
# Requirements:
#   - Python 3
#   - python3-fonttools (apt install python3-fonttools)
#
# Usage:
#   ./fix-flat-symbol.sh [WINEPREFIX]
#
# If WINEPREFIX is not specified, defaults to ~/.wine
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Determine WINEPREFIX
WINEPREFIX="${1:-$HOME/.wine}"
FONTS_DIR="$WINEPREFIX/drive_c/windows/Fonts"

echo "========================================"
echo "FL Studio Wine - Flat Symbol Fix"
echo "========================================"
echo ""
echo "WINEPREFIX: $WINEPREFIX"
echo "Fonts dir:  $FONTS_DIR"
echo ""

# Check if fonts directory exists
if [ ! -d "$FONTS_DIR" ]; then
    echo -e "${RED}ERROR: Fonts directory not found: $FONTS_DIR${NC}"
    echo "Make sure WINEPREFIX is correct and Wine has been initialized."
    exit 1
fi

# Check for required fonts
SEGOEUI="$FONTS_DIR/segoeui.ttf"
SEGUISYM="$FONTS_DIR/seguisym.ttf"

if [ ! -f "$SEGOEUI" ]; then
    echo -e "${RED}ERROR: Segoe UI not found: $SEGOEUI${NC}"
    echo "You need to install Segoe UI font in your WINEPREFIX."
    exit 1
fi

if [ ! -f "$SEGUISYM" ]; then
    echo -e "${RED}ERROR: Segoe UI Symbol not found: $SEGUISYM${NC}"
    echo "You need to install Segoe UI Symbol font in your WINEPREFIX."
    exit 1
fi

# Check for fonttools
if ! python3 -c "from fontTools.ttLib import TTFont" 2>/dev/null; then
    echo -e "${YELLOW}Installing python3-fonttools...${NC}"
    if command -v apt &> /dev/null; then
        sudo apt install -y python3-fonttools
    elif command -v pip3 &> /dev/null; then
        pip3 install --user fonttools
    else
        echo -e "${RED}ERROR: Cannot install fonttools. Please install manually:${NC}"
        echo "  apt install python3-fonttools"
        echo "  or: pip3 install fonttools"
        exit 1
    fi
fi

# Create backup
if [ ! -f "$SEGOEUI.backup" ]; then
    echo "Creating backup: $SEGOEUI.backup"
    cp "$SEGOEUI" "$SEGOEUI.backup"
else
    echo "Backup already exists: $SEGOEUI.backup"
fi

# Check if already patched
ALREADY_PATCHED=$(python3 -c "
from fontTools.ttLib import TTFont
font = TTFont('$SEGOEUI')
cmap = font.getBestCmap()
print('yes' if 0x266D in cmap else 'no')
font.close()
" 2>/dev/null)

if [ "$ALREADY_PATCHED" = "yes" ]; then
    echo -e "${GREEN}Font is already patched! U+266D (♭) is present in Segoe UI.${NC}"
    exit 0
fi

echo ""
echo "Patching Segoe UI with flat symbol from Segoe UI Symbol..."
echo ""

# Run the Python patch script
python3 << 'PYTHON_SCRIPT'
from fontTools.ttLib import TTFont
import copy
import sys

segoeui_path = sys.argv[1] if len(sys.argv) > 1 else None
seguisym_path = sys.argv[2] if len(sys.argv) > 2 else None

# Use environment or defaults
import os
fonts_dir = os.environ.get('FONTS_DIR', os.path.expanduser('~/.wine/drive_c/windows/Fonts'))
segoeui_path = segoeui_path or os.path.join(fonts_dir, 'segoeui.ttf')
seguisym_path = seguisym_path or os.path.join(fonts_dir, 'seguisym.ttf')
output_path = segoeui_path  # Overwrite original

print(f"Loading Segoe UI: {segoeui_path}")
print(f"Loading Segoe UI Symbol: {seguisym_path}")

segoeui = TTFont(segoeui_path + '.backup')  # Load from backup
seguisym = TTFont(seguisym_path)

FLAT_CODEPOINT = 0x266D
NATURAL_CODEPOINT = 0x266E  # Also add natural sign while we're at it

seguisym_cmap = seguisym.getBestCmap()
glyf_table = segoeui['glyf']
symbol_glyf = seguisym['glyf']

for codepoint, name in [(FLAT_CODEPOINT, 'uni266D'), (NATURAL_CODEPOINT, 'uni266E')]:
    if codepoint not in seguisym_cmap:
        print(f"Warning: U+{codepoint:04X} not in Segoe UI Symbol, skipping")
        continue

    glyph_name_in_symbol = seguisym_cmap[codepoint]
    new_glyph_name = name

    print(f"Copying U+{codepoint:04X} ({chr(codepoint)}) as {new_glyph_name}...")

    # Copy glyph data
    glyph_data = copy.deepcopy(symbol_glyf[glyph_name_in_symbol])
    glyf_table.glyphs[new_glyph_name] = glyph_data

    # Update glyph order
    glyf_table.glyphOrder = segoeui.getGlyphOrder() + [new_glyph_name]
    segoeui.setGlyphOrder(segoeui.getGlyphOrder() + [new_glyph_name])

    # Update cmap tables
    for table in segoeui['cmap'].tables:
        if hasattr(table, 'cmap') and table.cmap is not None:
            table.cmap[codepoint] = new_glyph_name

    # Copy horizontal metrics
    if glyph_name_in_symbol in seguisym['hmtx'].metrics:
        width, lsb = seguisym['hmtx'].metrics[glyph_name_in_symbol]
        segoeui['hmtx'].metrics[new_glyph_name] = (width, lsb)

print(f"Saving patched font to: {output_path}")
segoeui.save(output_path)

segoeui.close()
seguisym.close()

# Verify
print("\nVerifying...")
test_font = TTFont(output_path)
test_cmap = test_font.getBestCmap()
success = True
for cp, sym in [(0x266D, '♭'), (0x266E, '♮'), (0x266F, '♯')]:
    status = "✓" if cp in test_cmap else "✗"
    print(f"  U+{cp:04X} ({sym}): {status}")
    if cp in [0x266D] and cp not in test_cmap:
        success = False
test_font.close()

if success:
    print("\nPatch successful!")
else:
    print("\nPatch may have failed!")
    sys.exit(1)
PYTHON_SCRIPT

echo ""
echo -e "${GREEN}========================================"
echo "Fix applied successfully!"
echo "========================================${NC}"
echo ""
echo "You can now run FL Studio - flat symbols should display correctly."
echo ""
echo "To restore the original font:"
echo "  cp '$SEGOEUI.backup' '$SEGOEUI'"
echo ""
