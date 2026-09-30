# Draupr 4.1.7 Preview — Destination Roof Cut and Draw Coordinates

## Roof Join destination cut

- Replaced the previous add-face/erase shortcut with an explicit planar-region cutter.
- The cutter adds every opening boundary edge to the destination slope, identifies only coplanar faces fully contained by the opening polygon, and erases those regions on both top and underside planes.
- Boundary-connected notches are supported; a join now fails instead of silently succeeding if either destination surface cannot be cut.
- Opening reveal faces are rebuilt after the top and underside regions are removed.

## Drawing coordinate accuracy

- Level placement now intersects the cursor pick ray directly with the active level plane. It no longer takes an inferred 3D point and changes only its Z coordinate, which caused perspective offset from the crosshair.
- Surface placement now intersects the cursor ray with the actually visible nested face using its complete instance transformation.
- Removed the secondary InputPoint marker from preview drawing so it cannot appear at a different location from the custom crosshair and object preview.
- The centered 32×32 draw cursor keeps its `(16, 16)` hotspot.

## Native acceptance

1. Join a gable source roof into a target slope at an eave/boundary; verify a visible destination notch through top and underside surfaces.
2. Orbit below the target and confirm no destination skin remains across the joined source roof.
3. Undo/redo the join in one step and save/reload.
4. Draw point, line, rectangle, rotated, and path objects in perspective at several project levels; verify the first point and preview stay directly under the crosshair.
5. Repeat surface placement on nested group/component faces and in an active edit context.
