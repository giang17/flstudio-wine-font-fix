#!/usr/bin/env python3
"""
Patch Segoe UI font to include flat symbol (U+266D) from Segoe UI Symbol.

Usage:
    python3 patch-segoeui.py [WINEPREFIX]

If WINEPREFIX is not specified, defaults to ~/.wine
"""

from fontTools.ttLib import TTFont
import copy
import sys
import os

def main():
    # Determine WINEPREFIX
    if len(sys.argv) > 1:
        wineprefix = sys.argv[1]
    else:
        wineprefix = os.path.expanduser("~/.wine")

    fonts_dir = os.path.join(wineprefix, "drive_c/windows/Fonts")
    segoeui_path = os.path.join(fonts_dir, "segoeui.ttf")
    seguisym_path = os.path.join(fonts_dir, "seguisym.ttf")
    backup_path = segoeui_path + ".backup"

    print(f"WINEPREFIX: {wineprefix}")
    print(f"Fonts dir:  {fonts_dir}")
    print()

    # Check files exist
    if not os.path.exists(segoeui_path):
        print(f"ERROR: Segoe UI not found: {segoeui_path}")
        sys.exit(1)

    if not os.path.exists(seguisym_path):
        print(f"ERROR: Segoe UI Symbol not found: {seguisym_path}")
        sys.exit(1)

    # Create backup if needed
    if not os.path.exists(backup_path):
        print(f"Creating backup: {backup_path}")
        import shutil
        shutil.copy2(segoeui_path, backup_path)
    else:
        print(f"Backup exists: {backup_path}")

    # Load fonts
    print(f"Loading fonts...")
    segoeui = TTFont(backup_path)  # Load from backup
    seguisym = TTFont(seguisym_path)

    # Glyphs to copy
    glyphs_to_copy = [
        (0x266D, "uni266D", "MUSIC FLAT SIGN"),
        (0x266E, "uni266E", "MUSIC NATURAL SIGN"),
    ]

    seguisym_cmap = seguisym.getBestCmap()
    glyf_table = segoeui['glyf']
    symbol_glyf = seguisym['glyf']

    for codepoint, new_name, description in glyphs_to_copy:
        if codepoint not in seguisym_cmap:
            print(f"Warning: U+{codepoint:04X} not in Segoe UI Symbol, skipping")
            continue

        glyph_name = seguisym_cmap[codepoint]
        print(f"Copying U+{codepoint:04X} ({chr(codepoint)}) {description}...")

        # Copy glyph data
        glyph_data = copy.deepcopy(symbol_glyf[glyph_name])
        glyf_table.glyphs[new_name] = glyph_data

        # Update glyph order
        glyf_table.glyphOrder = segoeui.getGlyphOrder() + [new_name]
        segoeui.setGlyphOrder(segoeui.getGlyphOrder() + [new_name])

        # Update cmap tables
        for table in segoeui['cmap'].tables:
            if hasattr(table, 'cmap') and table.cmap is not None:
                table.cmap[codepoint] = new_name

        # Copy horizontal metrics
        if glyph_name in seguisym['hmtx'].metrics:
            segoeui['hmtx'].metrics[new_name] = seguisym['hmtx'].metrics[glyph_name]

    # Save
    print(f"Saving patched font to: {segoeui_path}")
    segoeui.save(segoeui_path)

    segoeui.close()
    seguisym.close()

    # Verify
    print("\nVerifying...")
    test_font = TTFont(segoeui_path)
    test_cmap = test_font.getBestCmap()
    for cp, sym, desc in [(0x266D, "♭", "flat"), (0x266E, "♮", "natural"), (0x266F, "♯", "sharp")]:
        status = "✓" if cp in test_cmap else "✗"
        print(f"  U+{cp:04X} ({sym}) {desc}: {status}")
    test_font.close()

    print("\n✓ Patch complete! Run FL Studio to verify.")

if __name__ == "__main__":
    main()
