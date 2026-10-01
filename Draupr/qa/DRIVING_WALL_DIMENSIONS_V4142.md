# Driving Wall Dimensions — v4.1.42

## Interaction

1. Select one straight Draupr wall.
2. Start **Modify > Driving Wall Dimension**.
3. Click a fixed reference on the same wall, another wall, or other model geometry.
4. Click the start or end of the selected target wall.
5. Click to place the temporary dimension.
6. Type the required value in SketchUp Measurements and press Enter.

Esc clears the current dimension; Esc again exits.

## Native QA

- [ ] Same-wall start-to-end dimension, driving each endpoint in turn.
- [ ] Reference on another parallel wall; perpendicular value moves the whole target wall.
- [ ] Oblique external reference drives the chosen endpoint along its wall axis.
- [ ] InputPoint snapping to endpoint, midpoint, intersection, edge, and face.
- [ ] Pick both logical wall ends through visible end caps and end edges at near and far zoom levels.
- [ ] Rotated walls and active nested edit contexts.
- [ ] Doors/windows remain correctly hosted after resize and whole-wall movement.
- [ ] Joined moving endpoints are rejected without partial changes.
- [ ] Undo/Redo returns wall and hosted objects in one step.
- [ ] No temporary annotation entities persist after exit or save/reopen.