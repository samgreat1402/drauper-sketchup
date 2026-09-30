# Dormer textured siding and roof-underside clipping — v4.1.29

## Requested correction

- Remove Dormer gutters completely.
- Replace projecting board-like siding geometry with a material texture.
- Prevent any front crown or cheek wall from appearing above the roof covering.

## Implementation

- Removed gutter builders, gutter material, gutter role, and gutter controls.
- Removed all generated horizontal siding-strip geometry.
- Added an original seamless 512 × 512 warm-white horizontal siding texture.
- Added a dedicated **Dormer Siding Material** field and role.
- Apply the siding material directly to front-wall pieces, crown, and cheeks.
- For every roof panel, derive vertical underside clearance from:
  `roof thickness / abs(panel normal Z)`.
- Lower the rectangular front wall, every crown profile point, and both cheek
  top edges below the true offset roof plane.
- Add 2 mm tolerance to prevent coplanar flicker.
- Reject impossible combinations where roof thickness leaves less than
  120 mm of usable front wall.

## Native acceptance

Inspect the Dormer with X-Ray off and on. No white crown or cheek surface may
appear through the roof. Confirm there are no gutter groups and no individual
siding-board groups. Verify the siding courses come only from the material
texture and remain editable through the siding material role.