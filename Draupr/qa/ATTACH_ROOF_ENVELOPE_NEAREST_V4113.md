# Draupr 4.1.13 Preview — Attach Top Multi-Slope Roof Envelope

The 4.1.10 exact-face fallback removed the footprint error but extrapolated one slope across the entire wall, producing the triangular spike shown in the latest screenshot.

- Draupr roof targets again use all canonical roof slopes, not one clicked plane.
- Each wall-layer vertex first resolves against a slope that actually contains it.
- Near-edge vertices use the closest bounded slope within the thickness-aware margin.
- Vertices outside every bounded polygon fall back to the nearest roof slope instead of raising the roof-envelope footprint error.
- The chosen slope plane is applied independently to each remaining wall piece, including walls with hosted openings.
- Non-Draupr planar targets still use the exact clicked face.

Includes all 4.1.12 Knife, roof-join, Heal Opening, hosted-opening split, and snap fixes.
