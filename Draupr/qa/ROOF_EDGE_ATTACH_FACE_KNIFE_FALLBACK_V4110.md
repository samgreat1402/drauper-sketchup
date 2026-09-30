# Draupr 4.1.10 Preview — Roof Edge Removal, Exact Face Attach, Knife Fallback

## Roof destination edge/fascia removal

- When a destination cut reaches a roof-face perimeter, the matching top edge is now recognized as an open boundary.
- The corresponding outer thickness/fascia side face is split and erased through the same planar-region cutter.
- Boundary-coincident opening edges no longer recreate a reveal face across the intended opening.

## Attach Top/Base to Face

- The command now always honors the exact clicked planar face, including faces nested inside a Draupr roof.
- The clicked plane is transformed into wall-local coordinates and intentionally extrapolated as a face constraint.
- This removes the roof-envelope footprint rejection from the explicit **Attach Top to Face** workflow while retaining target object metadata.

## Knife picking fallback

- Visible-face ray intersection remains the preferred station solver.
- Hovering an edge, silhouette, or narrow face now falls back to finite screen-space path projection instead of reporting “Move over a visible face.”
- If face projection falsely clamps to the true assembly start/end while the screen path station is internal, the internal screen station wins.
- The true endpoint sliver guard and hosted-opening redistribution remain active.

## Native acceptance

1. Repeat the gable-to-main-roof join and inspect the destination eave from below; confirm the remaining horizontal strip marked X is gone.
2. Attach a wall top to a clicked roof slope even when the wall footprint extends beyond that slope polygon; confirm the clicked plane is followed.
3. Run Knife over wall faces, outer edges, silhouettes, and narrow pieces; confirm the red line remains available and internal cuts do not report the assembly-start error.
4. Confirm true start/end cuts remain blocked, then Undo/Redo and save/reload all three operations.
