# Skylight roof cut and Dormer catalog — v4.1.19

## Video diagnosis

Both Skylight and Dormer reached host placement but failed while rebuilding the first roof opening with `Cannot cut roof_slope_0 opening 1`. The coplanar opening edges did not reliably seed the inner face on every SketchUp version.

The Dormer gallery displayed nine icons, but the canonical schema allowed only `gabled`, so every other choice normalized back to Gabled. The procedural builder also expected solution data that was never produced.

## Fixes

- Explicitly seed the coplanar inner roof face before erasing the top and underside opening regions.
- Keep roof recut transactional: the hosted object and original roof remain unchanged if validation fails.
- Register all nine Dormer types in the canonical schema.
- Keep the detailed reference-template Gabled Dormer.
- Add procedural Hipped, Shed, Eyebrow, Segmental Arch, Barrel Roof, Flat Roof, Pointed and Trapezoidal Dormers.
- Every procedural type produces front wall/window framing, cheek walls, roof panels, fascia/soffits and a physical host-roof opening bounded by the drawn footprint.

## Native acceptance checklist

- Place, edit and heal one Skylight on each roof slope.
- Place each Dormer type on a gable, hip and shed host roof.
- Verify the opening is visible from below and heals after deletion.
- Verify multiple openings remain independent.
- Verify Undo restores both host and opening object in one step.
