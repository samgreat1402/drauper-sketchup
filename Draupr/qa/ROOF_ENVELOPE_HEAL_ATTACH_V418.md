# Draupr 4.1.8 Preview — Destination Envelope Cut, Heal Opening, Attach Top

## Roof Join destination removal

- Destination cutting now uses the convex envelope of every connected source slope strip.
- The envelope removes the complete source roof-end silhouette from the destination slope, including the central gable/attic region—not only narrow roof-thickness slots.
- The envelope is clipped to the selected destination face and passed through the explicit top/underside planar cutter introduced in 4.1.7.

## Heal One Opening

- Heal accepts an opening object, a wall jamb/reveal, or a click through an empty opening void.
- Empty-void clicks resolve to the nearest projected hosted opening within 500 screen pixels and includes active-context/selected walls.
- Wall-host healing removes the nearest opening record, rebuilds the host wall, and deletes the linked door/window object when present in one transaction.

## Attach Top/Base with openings

- Removed the previous guard that rejected walls containing hosted openings.
- Attached-boundary walls now use the same longitudinal and vertical opening segmentation as ordinary walls.
- Each remaining wall piece resolves the roof/face constraint only on its true outer top or base boundary; opening heads, sills, and jambs stay at their configured elevations.
- Internal opening cut edges remain hidden on flat or sloped attached pieces.

## Native acceptance

1. Join a gable source to a destination slope and confirm the complete region marked X is removed through destination top and underside skins.
2. Heal by clicking the door/window object, then Undo; repeat by clicking a jamb and by clicking through the empty void.
3. Place a window and door, then Attach Top to a roof and to a planar face; confirm the wall reaches the target while both openings remain intact.
4. Test single-layer and multi-layer walls, Undo/Redo, save/reload, and nested active edit contexts.
