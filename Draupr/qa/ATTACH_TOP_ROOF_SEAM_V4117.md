# Attach Top roof-seam regression — v4.1.17

## Reproduction

Attach a single long wall to a gable or other multi-surface roof whose ridge crosses the middle of the wall segment.

## Root cause

The variable-height wall builder sampled only each unsplit wall-layer quad corner. When both segment ends were under equal-height eaves, the top remained horizontal even though a ridge crossed the segment interior.

## Fix

Before constructing attached wall pieces, intersect every roof-surface boundary with the wall-layer perimeter and centerline. Add those intersection stations to the existing longitudinal cuts, then solve each resulting piece against the correct roof plane.

## Acceptance

- A gable ridge crossing a wall creates an interior station and a peaked wall top.
- Shed/one-surface roofs remain unchanged.
- Hip, gambrel, and mansard surface seams can add multiple stations.
- Opening cuts remain combined with roof-seam cuts.
- Top and base roof-envelope constraints both use the same seam logic.
