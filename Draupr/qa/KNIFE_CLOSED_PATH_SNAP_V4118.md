# Knife closed-path and snap regression — v4.1.18

## Video diagnosis

The house perimeter is a closed connected wall path. Knife rejected closed paths during hover, then its 400-pixel screen fallback selected the unrelated split wall at the right. This produced a remote red indicator and false start/end errors.

## Fix

- Knife alone may resolve closed path geometry. Other modifiers retain the closed-path guard.
- A closed loop is represented with its closing segment during hit testing and is partitioned into two open parametric paths at the clicked station and the stored loop origin.
- Hosted openings are redistributed through the existing split-opening logic.
- Screen fallback is limited to 24 logical pixels.
- Direct pick paths rank before fallback candidates.
- The red indicator is drawn from the exact computed split guide; it is no longer shifted to the raw face hit.

## Acceptance

- Knife previews and cuts a closed connected wall away from its vertices.
- The two results are open paths with valid point counts.
- Hovering the house cannot select a wall hundreds of pixels away.
- Red preview and committed cut use the same local cut station.
- Existing open-wall and hosted-opening split behavior remains active.
