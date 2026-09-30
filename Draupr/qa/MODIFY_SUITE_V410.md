# Draupr 4.1.0 Preview — Full Modify Suite

## Implemented groups

### Topology & Path
- Split Assembly / Knife for walls, curtain walls, beams, railings, louvers, molding runs, and strip foundations.
- Trim / Extend to an actual transformed target-face plane.
- Baseline alignment and existing face alignment.

### Junctions & Corners
- Butt left-through, butt right-through, true miter, and square-off switching.
- Parametric fillet and chamfer connector walls with radius validation.

### Boundaries & Heights
- Attach wall top or base to a transformed roof/slab/planar face.
- Persistent face and instance-path references, with explicit Sync refresh.
- Variable-height wall layer meshes and stepped wall/strip-foundation segments.

### Apertures & Openings
- Heal one hosted door, window, skylight, or Dormer opening.
- Jamb splay, sill slope, and casing setback persisted in opening records.
- Multi-ply wall carving expands/recesses each layer without boolean operations.

### Profiles & Sweeps
- Nine-point profile registration.
- Normal flip.
- Start/end returns with configurable return length.

### Architectural Detailing
- One-way disassembly to semantic component parts.
- Selected-edge chamfer or bullnose detail generation.

## Safety
- Every model mutation uses the shared transaction wrapper.
- Surface targeting stores persistent face ID, instance path, model GUID, and a local fallback plane.
- Disassembly requires explicit confirmation and intentionally removes parametric editing.
- The build remains Preview and native_tested remains false until the included SketchUp acceptance matrix passes.
