# Editable Wall Dimensions — v4.1.40

## Scope

- Temporary viewport-only dimension; no annotation entities are left in the model.
- Exact input through SketchUp Measurements/VCB.
- Straight, two-point, unscaled parametric Draupr walls.
- Fixed Start, Fixed End, and Center resize modes.
- Hosted door/window validation and repositioning.
- Joined moving endpoints are intentionally blocked in this first release.

## Native acceptance checklist

- [ ] Activate from Modify > Editable Wall Length with one wall selected.
- [ ] Activate from the wall context menu.
- [ ] Enter values in mm, cm, m, inches, and feet.
- [ ] Click the start/end markers and verify the opposite endpoint moves.
- [ ] Press Tab and verify Start > End > Center cycling.
- [ ] Verify a hosted door/window remains stationary relative to the fixed reference.
- [ ] Verify shortening through an opening is rejected without model changes.
- [ ] Verify moving a joined endpoint is rejected; verify the free endpoint still works.
- [ ] Verify Undo and Redo restore wall and hosted objects as one operation.
- [ ] Verify rotated walls and nested active editing contexts.
- [ ] Verify Esc exits and leaves no dimensions in Outliner or the model.
- [ ] Save/reopen and verify no temporary geometry was persisted.

Native SketchUp execution is required before promoting this Preview to Stable.