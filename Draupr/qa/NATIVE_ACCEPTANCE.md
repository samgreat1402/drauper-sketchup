# Draupr 4.1.43 Native Acceptance Checklist

**Status:** not executed in the build sandbox. `native_tested` remains false.

Generated scope: **17 tools**, **286 fields**, **6 workspaces**.

## Tool matrix

- [ ] `wall`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `curtain_wall`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `door`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `window`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `column`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `foundation`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `beam`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `slab`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `grid`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `stair`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `roof`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `railing`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `louver`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `ramp`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `skylight`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `dormer`: create, edit, transform, delete, Undo/Redo, save/reload
- [ ] `molding`: create, edit, transform, delete, Undo/Redo, save/reload

## Relationship and persistence gates

- [ ] Hosted openings: two per wall/roof; move, resize, delete, heal, Undo/Redo, save/reload.
- [ ] Wall junctions: Butt/Miter/Square Off at 45°, 60°, 90°, 120°, and 135°; swap priority and edit peers.
- [ ] Roof edge-to-face joins: gable/hip, target holes, multiple joins, Undo/Redo, save/reload.
- [ ] Local railings: configure folder, validate all expected filenames, horizontal/sloped/L paths.
- [ ] Molding: horizontal/sloped/connected paths, 35 profiles, anchor/flip/rotation/smoothing.
- [ ] Preferences migrate from legacy `.040` keys without losing values.
- [ ] Legacy object inference flags ambiguous levels and never silently adopts the active level.
- [ ] Plan/Elevation scene command is idempotent and uses the active Project level.
- [ ] Test EN/FA, RTL, 420/610/900 px, all unit modes, Windows/macOS, and supported SketchUp versions.

Do not mark the release Stable or set `native_tested` true until applicable native cases pass.
