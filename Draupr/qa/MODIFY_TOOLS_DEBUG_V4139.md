# Modify tools debug audit — 4.1.39

All 18 Modify buttons were traced through their HTML IDs, frontend dispatch cases, Ruby bridge handlers, picker classes, and core operations.

## Corrected failures

1. **Edge Chamfer / Bullnose** now enters an interactive edge picker when no raw edge is preselected. Geometry is constructed in an orthonormal edge frame, so vertical and sloped edges no longer create detached or incorrectly oriented details.
2. **Registration, Flip & Returns** now applies path returns to railings as well as moldings. Previously railing rebuilds could complete without consuming these options.
3. **Detach Boundaries** now reports that no attachment exists instead of rebuilding the wall and claiming success.
4. Path-based tools now explain that they require a parametric Draupr path and identify the supported object families. Ordinary SketchUp groups remain valid for Align Faces, and ordinary visible edges remain valid for Edge Detail.

## Wiring result

- 18/18 buttons present
- 18/18 frontend handlers present
- 18/18 Ruby bridge routes present
- 18/18 operations resolve to an implementation or interactive picker
