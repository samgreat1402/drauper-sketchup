# Draupr 4.1.4 Preview — Bounded Roof Join and Knife Indicator Rewrite

## Roof Join

- Replaced the all-or-nothing target-face midpoint rejection with convex face clipping.
- Source slope strips may cross a target-face boundary; only their bounded overlap is stored as a target opening.
- A precise facing-slope error remains when the extended source end has no overlap at all.

## Knife

- Cut station now follows the cursor projected onto the visible 2D path, not SketchUp InputPoint snapping on shell edges.
- Hover preview and click recompute the same station, preventing endpoint-snap disagreement.
- Indicator is now a solid red center cut line with a lighter plane outline; diagonal clutter was removed.
- True assembly endpoints retain the 5 mm zero-length/sliver guard.

## Native acceptance

1. Join a source gable end whose strip partly crosses the selected target slope boundary.
2. Confirm the target opening is clipped to that slope and Undo restores both roofs in one step.
3. Move Knife across a long assembly and an internal path node; confirm the solid red line follows the cursor without snapping to the outer endpoint.
4. Confirm clicking at the displayed line creates two non-zero-length parametric children.
