# Draupr 4.1.12 Preview — Knife Overlapping-Object Target Resolution

The repeated assembly-start error occurred where multiple Draupr assemblies overlap in the pick aperture. The old picker accepted the first SketchUp pick path, which could be a short foreground/end-cap object whose projected station was its true start.

- Knife now evaluates every SketchUp pick path under the cursor.
- Unsupported objects are discarded through the same path validation used by the split core.
- Candidate stations are projected onto each finite visible path.
- Internal stations are ranked ahead of true start/end stations; screen distance breaks ties.
- Hover preview and click use the identical ranked object/station pair.
- True endpoint protection remains active when no valid internal candidate exists.

Includes all 4.1.11 roof, Attach Face, Heal Opening, hosted-opening split, and snap fixes.
