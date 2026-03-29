# Cape Forge 1.0.0

Cape Forge converts Windows cursor packs (`.cur`, `.ani`) into Mousecape-compatible `.cape` files on macOS.

## Highlights

- Import Windows cursor folders and preview mapped cursor roles.
- Adjust individual cursor roles by choosing a replacement `.cur` or `.ani` file.
- Preview both large and actual-size cursor rendering before export.
- Export a `.cape` file for use with Mousecape.
- Support core cursor roles plus official Mousecape supplemental cursor slots.
- Interface available in multiple languages.

## Notes

- Cape Forge creates `.cape` files. It does not apply system cursors directly.
- For best results, use a cursor pack folder that contains standard Windows cursor files such as `Normal.cur`, `Text.cur`, `Link.cur`, `Busy.ani`, and related resize cursors.
- Some cursor packs combine multiple roles into one file; Cape Forge will map those where possible and fall back to similar roles when needed.

## System Requirements

- macOS 26.0 or later

## Known Limitations

- Export targets Mousecape-compatible `.cape` files only.
- Cursor names and role mappings may vary depending on the source pack.

