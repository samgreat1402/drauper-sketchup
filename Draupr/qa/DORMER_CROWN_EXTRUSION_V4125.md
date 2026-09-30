# Dormer front-crown extrusion correction — v4.1.25

## Screenshot diagnosis

The triangular or curved wall crown was created on the exterior front plane at
`Y = -wall_thickness`. Its face normal points toward negative Y, but the builder
used a positive PushPull distance. The crown therefore projected farther out
from the facade, producing the large white triangular wedge visible beside the
window and roof.

## Correction

- Inspect the generated crown face normal.
- Select the PushPull sign that always moves from the exterior plane toward
  local `Y = 0`.
- Keep the crown flush with the rectangular front-wall shell.
- Preserve crown profiles for Gabled, Pointed, Trapezoidal, Eyebrow, Segmental,
  and Barrel Dormers.

## Native acceptance

Inspect each crowned Dormer from both side angles. The crown must remain between
the exterior and interior front planes, with no wedge projecting in front of
the casing or outside the roof.