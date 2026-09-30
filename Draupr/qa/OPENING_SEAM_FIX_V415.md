# Draupr 4.1.5 Preview — Door and Window Wall-Seam Fix

- Door and window recuts still use independent parametric wall pieces for safe rebuilds.
- Vertical edges created only by internal opening cut stations are now hidden on every generated layer piece.
- True wall ends, wall corners, sill edges, head edges, and frame geometry remain unchanged.
- The fix applies to doors, windows, edited openings, and host synchronization because all use `Walls.recut`.

## Native acceptance

1. Place a window and a door in single-layer and multi-layer walls.
2. Confirm no full-height vertical seam continues above or below either opening.
3. Confirm frames, jamb reveals, heads, sills, materials, and opening voids remain visible.
4. Edit width, sill, jamb splay, and casing setback; confirm seams remain hidden.
5. Undo and redo each placement and edit in one step.
