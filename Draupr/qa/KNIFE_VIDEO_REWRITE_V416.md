# Draupr 4.1.6 Preview — Knife Video-Derived Rewrite

The supplied recording showed two visible problems: the preview plane expanded across the complete multi-segment assembly bounds, and the station could jump between projected path segments while orbiting or hovering oblique faces.

## Changes

- Removed screen-space baseline selection as the primary station solver.
- Knife now intersects the cursor pick ray with the actually visible picked face, transforms that unsnapped hit into assembly-local space, and projects it onto the nearest finite path segment.
- This avoids SketchUp InputPoint endpoint inference and avoids choosing a different path segment merely because two baselines overlap on screen.
- Preview width is now a bounded local cross-section derived from the assembly thickness/width, capped at 1.5 m total.
- Removed the large pink plane outline; only the solid red vertical cut line is drawn.
- Hover and click use the same face-ray/path solver.

## Native acceptance

1. Repeat the camera orbit and hover sequence from the supplied recording on the same multi-segment assembly.
2. Confirm the red line stays attached to the visible wall face and local segment.
3. Confirm the line does not expand across the entire L/U-shaped assembly.
4. Click at several middle stations and an internal node; confirm the resulting child objects do not move, rotate, or change elevation.
5. Confirm clicks within 5 mm of the true assembly start/end remain blocked.
6. Undo and redo each split in one step.
