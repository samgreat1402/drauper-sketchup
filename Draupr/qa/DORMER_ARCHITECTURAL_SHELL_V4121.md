# Dormer architectural shell rewrite — v4.1.21

## Review basis

The rewrite was checked against the supplied SketchUp Ruby API skill and Dormer
Generator sample. The sample's useful architectural ideas were retained as
design goals—solid wall shells, a physical window opening, roof thickness,
soffits, and fascia—but its monolithic methods, raw inch values, global
materials, fragile face deletion, and two-type limitation were not copied.

## Geometry correction

- All nine catalog types now use one original parametric construction pipeline.
- Every rear roof vertex is the exact intersection of its Dormer roof plane and
  the selected host roof plane.
- Host-envelope fitting prevents folded, vertical, floating, or overlong panels.
- Gabled no longer uses the incomplete reference-template path.
- Hipped uses three planar roof facets; Shed uses one planar rising facet.
- Curved types use twenty planar facets while retaining their distinct profiles.
- The host opening follows the complete rear join profile instead of assuming a
  four-point rectangle.
- Roof-opening centroid calculation now uses the actual polygon vertex count.

## Architectural enhancement

- Solid front and cheek walls.
- Physical front-window opening assembled around the void.
- Deep jamb/frame members, glass, optional mullion, and projecting sill.
- Roof thickness normal to each roof plane.
- Closed front and side soffits.
- Rake and eave fascia.
- Parametric materials and metadata remain integrated with Draupr.

## Automated checks

Static geometry simulation covers all nine types and verifies panel planarity,
host-plane opening vertices, bounded join depth, catalog preservation, and the
new architectural-shell contract.

## Native acceptance

In SketchUp, test each type on shallow and steep roof slopes, near both roof
edges, with and without the front window. Verify one-step Undo, edit/rebuild,
opening healing, materials, no folded faces, and no roof remnants. Native
testing is still required before Stable status.