# Dormer height fitting — 4.1.38

## Corrected behavior

The drawn depth is now a minimum placement footprint rather than a hard height ceiling. Draupr calculates the available uphill distance at the left and right sides of the selected roof face. It preserves the requested front-wall and template-roof heights by extending the rear intersection uphill when the same roof face has room.

If the required intersection would cross the ridge or an outer face boundary, Draupr proportionally fits the Dormer to the actual available host area. The opening polygon and generated Dormer continue to share the same calculated intersection.

## Safety properties

- Never extends past the selected semantic roof face.
- Uses the shorter available depth of the two Dormer sides.
- Keeps a boundary clearance before fitting.
- Stores `auto_extended`, `auto_fitted`, and the v6 geometry contract in object metadata.
- Preserves the previous fallback behavior for non-interactive fixtures and legacy callers.
