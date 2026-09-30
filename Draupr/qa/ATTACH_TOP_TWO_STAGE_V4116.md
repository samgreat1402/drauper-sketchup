# Draupr 4.1.16 Preview — Attach Top Two-Stage Picking

The supplied 28.6-second recording starts with a Draupr roof selected. The previous tool required one wall to be preselected, immediately rejected that state, and returned control to SketchUp selection—so subsequent clicks only selected the roof and never attached the wall.

- Preselection is now optional.
- If exactly one wall is selected, the tool begins at target-face selection.
- Otherwise the first model click must choose a Draupr wall and the second click chooses the target face.
- A selected roof or unrelated object no longer aborts tool activation.
- Escape clears the chosen wall first; a second Escape exits.
- Stage-specific status text and hover colors make the wall and target steps explicit.
- Draupr roofs continue to use the multi-slope nearest-envelope solver; ordinary planar targets use the exact clicked plane.

Includes all 4.1.15 Knife, roof-join, Heal Opening, hosted-opening, and snap fixes.
