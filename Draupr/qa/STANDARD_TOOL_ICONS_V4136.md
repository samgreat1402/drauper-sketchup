# Industry-Standard Tool Icons — v4.1.36

## Mapping

- Standard Tabler glyphs provide the base visual vocabulary for all 35 commands.
- Draupr overlays retain CAD semantics: blue target, orange action, green addition,
  red removal/cut, and cyan glazing.
- Domain-specific tools combine the closest standard base glyph with an original
  Draupr overlay instead of copying proprietary CAD application icons.

## Acceptance

1. Confirm `standard_icons.js` loads before `studio.js` without network access.
2. Verify all 17 Create and 18 Modify commands resolve to a standard base glyph.
3. Check hover labels and accessible names in English and Persian.
4. Verify light/dark, active, disabled, RTL, keyboard focus, and 100–200% scaling.
5. Confirm source and packaged RBZ include `THIRD_PARTY_NOTICES.md`.