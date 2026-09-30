# Dormer redundant-soffit removal and gutters — v4.1.27

## Screenshot diagnosis

1. The roof panels are already closed PushPull solids with their own underside,
   but separate front and side soffit faces were added again. These duplicate
   sheets produced the extra dark plane visible beneath every Dormer roof.
2. The side fascia continued all the way to the host-roof intersection, causing
   trim geometry to penetrate the host roof.
3. The two rectangular side fascia pieces read as white boxes rather than
   functional drainage components.

## Correction

- Remove all separately generated front and side soffit sheets.
- Use the closed roof-solid underside as the single soffit surface.
- Remove the two side fascia boxes.
- Add a four-piece open rectangular gutter to each downslope roof edge:
  bottom, inner wall, outer wall, and reinforced outer lip.
- Orient each gutter to its sloped eave line.
- Stop gutters 65 mm before the host-roof intersection.
- Add a dedicated **Gutter Material** field and material role, defaulting to
  satin steel.
- Keep front rake fascia and all roof perimeter geometry intact.

## Native acceptance

Inspect every Dormer from below and above. Confirm there is only one roof
underside, no loose sheet beneath the overhang, no side trim entering the host
roof, both gutters remain open at the top, and their rear ends stop before the
host-roof intersection.