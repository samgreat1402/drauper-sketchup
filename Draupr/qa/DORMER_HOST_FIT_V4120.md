# Dormer host-slope fitting — v4.1.20

## Screenshot diagnosis

The procedural Dormer roof used the requested 1.35 m wall and 0.805 m crown literally even when the selected roof gained much less height across the drawn footprint. The rear edge was forced onto the host plane, producing folded, near-vertical or floating roof panels. The detailed Gabled template was also scaled to the unfitted requested height.

## Correction

- Compute the available vertical envelope from `host_slope × drawn uphill depth`.
- Reserve rear clearance and proportionally fit wall/crown height below the host intersection.
- Preserve a usable 250 mm minimum front wall and 60 mm crown where the host envelope permits it.
- Reject genuinely impossible shallow footprints with an instruction to draw farther uphill.
- Keep the user-drawn width and depth unchanged.
- Apply the same fitted height to the detailed Gabled template and all eight procedural types.
- Shed now uses a single front eave line instead of adding the crown height twice.

## Native acceptance

For all nine types: verify no vertical/folded panels, no floating rear edge, opening stays within the drawn rectangle, edit/heal work, and Undo is one step.
