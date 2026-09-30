# Dormer overhang integration — v4.1.22

## Screenshot diagnosis

The v4.1.21 roof facets stopped at the Dormer wall width while the side soffit
and fascia were generated at the overhang width. This left detached dark fins
beside the Dormer. Extending every profile point as a separate panel would also
have introduced unnecessary seams at the wall lines.

## Correction

- Extend the first and last roof facets to the lateral overhang.
- Continue each facet's actual slope rather than forcing a horizontal extension.
- Keep one solid per architectural facet, avoiding extra coplanar panel seams.
- Generate front rake fascia from the same extended roof profile.
- Generate side soffit and fascia from the exact outer and inner roof edges.
- Preserve the core host-opening polygon at the wall footprint.
- Apply the same integration to all nine Dormer types.

## Automated checks

All 72 roof facets across the nine-type simulation are planar and span the same
lateral overhang. Static checks confirm the v5 hosted-Dormer geometry contract,
extended front profile, and shared side-edge data.

## Native acceptance

Confirm in SketchUp that no detached black fins remain, soffits meet the roof,
fascia follows the roof boundary, the host opening remains correctly cut, and
Undo/edit/rebuild work for every Dormer type.