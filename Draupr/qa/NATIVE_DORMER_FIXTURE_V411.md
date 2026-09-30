# Draupr 4.1.1 Preview — Native Dormer Fixture Hotfix

## Root cause
The generic create/edit smoke loop instantiated a standalone Dormer from schema defaults. In production, a roof-face picker injects `host_slope`, `host_slope_rise`, and `host_surface_factor`; the synthetic fixture omitted those derived values, so the correct flat-host guard rejected it before the remaining native tests could run.

## Correction
- The standalone Dormer smoke fixture now supplies a deterministic 0.5 pitched host contract.
- The nine-type Dormer catalog fixture now supplies both slope ratio and slope rise consistently.
- A separate regression check verifies that a true zero-slope host is still rejected.
- No production Dormer tolerance or geometry validation was relaxed.

## Required rerun
Run **Extensions → Draupr BIM → Run Native Smoke Test (Empty Model)** in a new empty model. The result should have zero failures and include the explicit flat-host validation check.
