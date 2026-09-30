# Draupr 4.0.0 Preview — Integrated Three-Phase Rebuild

## Phase 1 — platform stability

- Safe Tool deactivation: arbitrary Tool changes never commit unfinished geometry.
- Explicit suspend/resume behavior and preserved Enter/double-click completion.
- Central active-context/world/object transformation contract.
- Persistent-ID-assisted host links with read-only host recovery and explicit repair.
- Per-model Draupr object index invalidated by model transactions.
- Scene creation is one undoable transaction.
- Internal extension loading uses `Sketchup.require`.
- Transactions rescue operational errors rather than all exceptions.
- Object Library format 4 validates size, counts, numeric coordinates, geometry checksums, texture checksums, face orientation, true inner loops, tags, and material-name collisions.

## Phase 2 — shared architecture

- Shared tolerance-aware path cleaning, segmenting, framing, and station helpers.
- Shared path preparation integrated into beams, strip foundations, curtain walls, railings, and molding runs.
- Shared coordinate conversion service used by roof operations.
- Central bilingual message foundation.
- Data schema advanced to version 2 while keeping the release in Preview.

## Phase 3 — object-family corrections

- Strip foundations now use a continuous miter-aware footprint rather than overlapping prisms.
- Curtain-wall path corners no longer create duplicate start mullions.
- Beam, railing, and molding paths reject coincident points consistently.
- Grid letters continue AA, AB, AC after Z.
- Roof tools use one world-transform path in nested edit contexts.
- Dormer conversion removes all nine confirmed opaque façade blockers, not only source face 788.
- Parametric Object Library imports reconstruct saved materials before running builders.

## Release gate

This package is statically checked but **not native-tested in SketchUp**. `native_tested` remains `false`; it must not be promoted to Stable until the included native/TestUp matrix passes.
