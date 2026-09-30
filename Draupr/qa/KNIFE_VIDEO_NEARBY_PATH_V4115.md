# Draupr 4.1.15 Preview — Video-Derived Nearby-Path Knife Resolver

The supplied 19.9-second recording showed long periods of “Hover a supported Draupr path first,” followed by false start/end errors. SketchUp was not returning a usable face pick path over much of the connected/occluded wall.

- Knife now combines normal face pick paths with a screen-near search across root, active-context, and selected Draupr path objects.
- Nearby paths within 400 screen pixels are eligible, allowing tall walls, roof-obscured walls, and thin silhouettes to remain targetable.
- Face-hit candidates still use exact 3D ray/face projection.
- Nearby fallback candidates intersect the cursor ray with the computed vertical cut plane, keeping the red line under the pointer.
- Endpoint protection is reduced from 5 mm to the core 0.5 mm geometric tolerance; only true zero-length/sliver children are blocked.
- Internal candidates, picked objects, and screen distance remain the ranking order.

Includes all 4.1.14 connected-wall metadata, Attach Top, roof-join, Heal Opening, hosted-opening, and snap fixes.
