#!/bin/bash
#
# FL Studio Wine Font Fix - Clean Solution
# Uses DejaVu Sans (open-source) renamed to "Segoe UI"
#
# This fixes the missing music symbols (♭ ♯) in FL Studio's Piano Roll
# chord detection when running under Wine.
#
# DejaVu Sans is licensed under the Bitstream Vera / SIL Open Font License
# and contains both flat (U+266D) and sharp (U+266F) symbols natively.
#
# Usage: ./fix-dejavu-as-segoeui.sh [WINEPREFIX]
#        Default WINEPREFIX: ~/.wine
#
# Requirements: python3, python3-fonttools
#   Install: pip install fonttools
#        or: sudo apt install python3-fonttools
#
# GitHub: https://github.com/giang17/flstudio-wine-font-fix
# Wine Bug: https://bugs.winehq.org/show_bug.cgi?id=59252

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  FL Studio Wine Font Fix - DejaVu Sans Solution                ║${NC}"
echo -e "${BLUE}║  Fixes missing ♭ and ♯ symbols in Piano Roll chord display     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Determine and validate WINEPREFIX
WINEPREFIX="${1:-$HOME/.wine}"

# Validate WINEPREFIX path (prevent injection attacks)
if [[ ! "$WINEPREFIX" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
    echo -e "${RED}Error: Invalid WINEPREFIX path. Only alphanumeric, /, _, ., and - allowed.${NC}"
    echo "Usage: $0 [WINEPREFIX]"
    exit 1
fi

# Resolve to absolute path and check existence
WINEPREFIX=$(realpath -s "$WINEPREFIX" 2>/dev/null || echo "")
if [ -z "$WINEPREFIX" ]; then
    echo -e "${RED}Error: Could not resolve WINEPREFIX path${NC}"
    exit 1
fi

if [ ! -d "$WINEPREFIX" ]; then
    echo -e "${RED}Error: WINEPREFIX not found: $WINEPREFIX${NC}"
    echo "Usage: $0 [WINEPREFIX]"
    exit 1
fi

FONTS_DIR="$WINEPREFIX/drive_c/windows/Fonts"

# Check for required tools
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: python3 is required but not installed.${NC}"
    exit 1
fi

if ! command -v file &> /dev/null; then
    echo -e "${YELLOW}Warning: 'file' command not found. Skipping font validation.${NC}"
    SKIP_VALIDATION=1
else
    SKIP_VALIDATION=0
fi

if ! python3 -c "import fontTools" 2>/dev/null; then
    echo -e "${RED}Error: fonttools is required but not installed.${NC}"
    echo "Install with: pip install fonttools"
    echo "         or: sudo apt install python3-fonttools"
    exit 1
fi

# Find DejaVu Sans on the system
DEJAVU_PATHS=(
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    "/usr/share/fonts/TTF/DejaVuSans.ttf"
    "/usr/share/fonts/dejavu/DejaVuSans.ttf"
    "/usr/local/share/fonts/truetype/dejavu/DejaVuSans.ttf"
)

DEJAVU_BOLD_PATHS=(
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
    "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"
    "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"
    "/usr/local/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
)

DEJAVU_SRC=""
DEJAVU_BOLD_SRC=""

# Find and validate regular font
for path in "${DEJAVU_PATHS[@]}"; do
    if [ -f "$path" ]; then
        # Validate it's a TrueType font
        if [ "$SKIP_VALIDATION" -eq 0 ]; then
            if ! file "$path" | grep -qi "TrueType\|OpenType"; then
                echo -e "${YELLOW}Warning: $path is not a valid font file, skipping...${NC}"
                continue
            fi
        fi
        DEJAVU_SRC="$path"
        break
    fi
done

# Find and validate bold font
for path in "${DEJAVU_BOLD_PATHS[@]}"; do
    if [ -f "$path" ]; then
        # Validate it's a TrueType font
        if [ "$SKIP_VALIDATION" -eq 0 ]; then
            if ! file "$path" | grep -qi "TrueType\|OpenType"; then
                echo -e "${YELLOW}Warning: $path is not a valid font file, skipping...${NC}"
                continue
            fi
        fi
        DEJAVU_BOLD_SRC="$path"
        break
    fi
done

if [ -z "$DEJAVU_SRC" ]; then
    echo -e "${RED}Error: DejaVu Sans font not found on system.${NC}"
    echo "Install with: sudo apt install fonts-dejavu-core"
    exit 1
fi

echo -e "${GREEN}Found DejaVu Sans:${NC} $DEJAVU_SRC"
if [ -n "$DEJAVU_BOLD_SRC" ]; then
    echo -e "${GREEN}Found DejaVu Sans Bold:${NC} $DEJAVU_BOLD_SRC"
fi
echo ""

# Create Fonts directory if it doesn't exist
if [ ! -d "$FONTS_DIR" ]; then
    mkdir -p "$FONTS_DIR"
    chmod 755 "$FONTS_DIR"
fi

# Backup existing fonts if present
if [ -f "$FONTS_DIR/segoeui.ttf" ]; then
    BACKUP="$FONTS_DIR/segoeui.ttf.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Backing up existing segoeui.ttf to:${NC}"
    echo "  $BACKUP"
    cp "$FONTS_DIR/segoeui.ttf" "$BACKUP"
    chmod 644 "$BACKUP"
fi

# Copy DejaVu Sans to WINEPREFIX
echo ""
echo -e "${BLUE}Copying DejaVu Sans to WINEPREFIX...${NC}"
cp "$DEJAVU_SRC" "$FONTS_DIR/segoeui.ttf"
chmod 644 "$FONTS_DIR/segoeui.ttf"

if [ -n "$DEJAVU_BOLD_SRC" ]; then
    cp "$DEJAVU_BOLD_SRC" "$FONTS_DIR/segoeuib.ttf"
    chmod 644 "$FONTS_DIR/segoeuib.ttf"
fi

# Rename font family using Python/fonttools
echo -e "${BLUE}Renaming font family to 'Segoe UI'...${NC}"

python3 << 'PYTHON_SCRIPT'
import sys
import os
from fontTools.ttLib import TTFont

def rename_font_family(font_path, new_family_name):
    """Rename font family, full name, and PostScript name."""
    try:
        font = TTFont(font_path)
        name_table = font['name']

        changes = 0
        for record in name_table.names:
            try:
                text = record.toUnicode()
            except:
                continue

            # Name IDs: 1=Family, 4=Full Name, 6=PostScript Name
            if record.nameID == 1 and "DejaVu Sans" in text:
                # Preserve style suffix (e.g., "Bold")
                if text == "DejaVu Sans":
                    record.string = new_family_name
                else:
                    suffix = text.replace("DejaVu Sans", "").strip()
                    record.string = f"{new_family_name} {suffix}".strip()
                changes += 1

            elif record.nameID == 4 and "DejaVu Sans" in text:
                record.string = text.replace("DejaVu Sans", new_family_name)
                changes += 1

            elif record.nameID == 6 and "DejaVuSans" in text:
                record.string = text.replace("DejaVuSans", new_family_name.replace(" ", ""))
                changes += 1

        font.save(font_path)
        return changes
    except Exception as e:
        print(f"Error processing {font_path}: {e}", file=sys.stderr)
        return 0

wineprefix = os.environ.get('WINEPREFIX', os.path.expanduser('~/.wine'))
fonts_dir = os.path.join(wineprefix, 'drive_c/windows/Fonts')

# Validate wineprefix exists
if not os.path.isdir(fonts_dir):
    print(f"Error: Fonts directory not found: {fonts_dir}", file=sys.stderr)
    sys.exit(1)

# Rename regular
regular_path = os.path.join(fonts_dir, 'segoeui.ttf')
if os.path.exists(regular_path):
    changes = rename_font_family(regular_path, "Segoe UI")
    if changes > 0:
        print(f"  segoeui.ttf: {changes} name records updated")
    else:
        print(f"  segoeui.ttf: Failed to update", file=sys.stderr)
        sys.exit(1)

# Rename bold
bold_path = os.path.join(fonts_dir, 'segoeuib.ttf')
if os.path.exists(bold_path):
    changes = rename_font_family(bold_path, "Segoe UI")
    if changes > 0:
        print(f"  segoeuib.ttf: {changes} name records updated")
PYTHON_SCRIPT

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Font renaming failed${NC}"
    exit 1
fi

# Verify the result
echo ""
echo -e "${BLUE}Verifying installation...${NC}"

python3 << 'VERIFY_SCRIPT'
import os
import sys
from fontTools.ttLib import TTFont

wineprefix = os.environ.get('WINEPREFIX', os.path.expanduser('~/.wine'))
font_path = os.path.join(wineprefix, 'drive_c/windows/Fonts/segoeui.ttf')

if not os.path.exists(font_path):
    print(f"Error: Font file not found: {font_path}", file=sys.stderr)
    sys.exit(1)

try:
    font = TTFont(font_path)
    cmap = font.getBestCmap()

    # Get family name
    family_name = "Unknown"
    for record in font['name'].names:
        if record.nameID == 1:
            try:
                family_name = record.toUnicode()
                break
            except:
                pass

    flat_ok = 0x266D in cmap   # ♭
    sharp_ok = 0x266F in cmap  # ♯

    print(f"  Font family: {family_name}")
    print(f"  Flat symbol (♭):  {'✓ Present' if flat_ok else '✗ Missing'}")
    print(f"  Sharp symbol (♯): {'✓ Present' if sharp_ok else '✗ Missing'}")

    if family_name == "Segoe UI" and flat_ok and sharp_ok:
        print("\n  Status: SUCCESS")
        sys.exit(0)
    else:
        print("\n  Status: FAILED")
        sys.exit(1)
except Exception as e:
    print(f"Error verifying font: {e}", file=sys.stderr)
    sys.exit(1)
VERIFY_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Installation complete!                                      ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║  FL Studio should now display ♭ and ♯ symbols correctly       ║${NC}"
    echo -e "${GREEN}║  in the Piano Roll chord detection.                           ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║  Restart FL Studio to see the changes.                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
else
    echo ""
    echo -e "${RED}Installation may have failed. Please check the output above.${NC}"
    exit 1
fi
