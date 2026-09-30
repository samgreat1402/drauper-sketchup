# Draupr 4.1.14 Preview — Connected-Wall Knife and Pointer Alignment

- Knife requests a 12-pixel SketchUp pick aperture so thin edges and connected-wall faces remain targetable.
- Every pick path is evaluated with its own visible face and complete nested transformation.
- The cursor ray is intersected with that exact face, then projected onto that candidate wall's finite path.
- Internal stations remain preferred over connected endpoints, with pick-path order and geometric distance as tie-breakers.
- The preview line is shifted from the wall centerline onto the actual clicked face, so it visually crosses the pointer instead of appearing behind or beside it.
- Hover and click continue to use the same ranked resolver; junction peer relinking and hosted-opening redistribution remain transactional.

Includes all 4.1.13 Attach Top, roof-join, Heal Opening, drawing snap, and hosted-opening fixes.
