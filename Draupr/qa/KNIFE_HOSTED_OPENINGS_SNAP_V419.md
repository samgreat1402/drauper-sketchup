# Draupr 4.1.9 Preview — Knife with Hosted Openings and Visible Snaps

## Knife splitting walls with openings

- Removed the blanket rejection for walls containing hosted doors/windows.
- Opening records are partitioned by child path and their segment indices are shifted to the new child topology.
- Openings on the split segment move to the correct child and their local station values are rebased when necessary.
- A cut that passes through an opening is still rejected with a specific instruction to move the Knife outside the opening.
- Door/window `hosts_json` references are updated to the new child wall UID, persistent ID, and segment in the same split transaction.

## Drawing snap feedback

- Restored native `InputPoint` snap markers only when the inferred point lies within 12 screen pixels of the exact cursor-ray placement plane.
- The actual committed point uses the same plane-projected snap point, so the marker and object preview cannot disagree.
- Level and surface coordinate accuracy from 4.1.7 remains unchanged.

## Native acceptance

1. Split before and after a hosted window and door; confirm each opening stays with the correct child and remains editable.
2. Split a multi-segment wall on both sides of an opening and at an internal node; confirm segment indices remain valid.
3. Attempt a cut through an opening; confirm the specific guarded error and no model change.
4. Undo/redo, move/edit each child, then save/reload.
5. Draw on a level plane and nested surface; hover vertices, endpoints, midpoints, and intersections. Confirm the native snap marker appears and the committed point matches it.
