# Draupr 4.1.3 Preview — Junction, Roof Join, Envelope, Knife, and Cursor Hotfixes

- Trim/Extend to Corner now detaches a conflicting prior endpoint join from both walls before committing the new junction.
- Roof Join honors the clicked target slope normal, avoiding ridge ambiguity.
- Each connected source roof slope creates its own target-face opening strip; disconnected intersections are no longer merged into one malformed polygon.
- Attach Top retains bounded roof surfaces while permitting a thickness-aware edge margin capped at 250 mm.
- Knife accepts existing internal polyline nodes as valid split stations.
- Knife uses a fixed 5 mm sliver guard only at the true assembly start and end.
- Replaced Knife and Trim cursor assets supplied for this hotfix.
- Knife cursor hotspot: `(3, 3)`.
- Trim cursor hotspot: `(16, 16)`.

## Validation boundary

Static syntax, package, schema, and browser-side QA can be run outside SketchUp. Native geometry, cursor hotspot, Undo/Redo, and visual behavior must still be confirmed interactively in SketchUp.
