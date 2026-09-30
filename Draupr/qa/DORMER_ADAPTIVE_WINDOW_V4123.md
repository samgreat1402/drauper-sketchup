# Dormer adaptive front window — v4.1.23

## Diagnosis

The front-window option was enabled, but the builder silently omitted the
window whenever host-envelope fitting reduced the Dormer wall to 420 mm or
less. This affected many ordinary roof slopes and made the generated Dormers
appear as blank boxes.

## Correction

- Remove the fixed 420 mm suppression threshold.
- Derive sill, head, side margins, and glazing from the fitted wall dimensions.
- Support every valid Dormer wall down to the existing 250 mm minimum.
- Keep the Front Window checkbox functional; only an explicit false value
  suppresses the window.
- Build a real wall opening with frame, deep reveals, glass, optional mullion,
  and projecting sill.
- Record accurate window/reveal metadata.

## Native acceptance

Create every Dormer type with Front Window enabled on both shallow and steep
roofs. Confirm the window remains inside the front wall and survives
edit/rebuild. Disable Front Window and confirm a solid front wall is generated.