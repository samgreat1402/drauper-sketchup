# Changelog

## 4.1.43 Preview

- Fixed the driving-dimension target step shown failing in the submitted recording.
- Target endpoints can now be selected through the visible wall end cap, end edges, or nearby centerline marker.
- Maps thick-wall visible corners back to the correct logical centerline endpoint in perspective views.
- Expanded screen-space endpoint tolerance and highlights the resolved logical endpoint before clicking.

## 4.1.42 Preview

- Replaced unreliable automatic wall dimensions with user-authored driving dimensions.
- Added a three-click workflow: fixed reference, selected-wall endpoint, and dimension-line placement.
- References can originate on the target wall, another wall, or other inferencable SketchUp geometry.
- Uses actual built wall-segment endpoints instead of assuming the stored path order represents the visible wall ends.
- Drives the selected endpoint along the wall axis; near-perpendicular dimensions move the whole target wall.
- Preserves hosted openings, blocks invalid shortening, and protects joined moving endpoints.

## 4.1.41 Preview

- Improved the temporary wall-dimension overlay discovered during native testing.
- Moved the numeric label above the dimension line and added a high-contrast background and border.
- Sized the label dynamically so formatted metric and imperial values remain readable.
- Kept the endpoint anchors and editable Measurements workflow unchanged.

## 4.1.40 Preview

- Added Revit-style temporary wall dimensions for straight two-point Draupr walls.
- Added exact wall-length entry through SketchUp's native Measurements box with model-unit parsing.
- Added Start, End, and Center anchor modes; click an endpoint or press Tab to choose the fixed reference.
- Preserved hosted door and window positions relative to the selected anchor and blocked invalid wall shortening.
- Protected joined endpoints from destructive resizing and retained native SketchUp Undo/Redo.
- Added the Editable Wall Length command to Modify and to the Draupr wall context menu.

## 4.1.39 Preview

- Audited all 18 Modify buttons from HTML click routing through the JavaScript bridge to their Ruby implementations.
- Replaced the Edge Detail selection-only action with an interactive visible-edge picker while retaining preselected-edge support.
- Corrected chamfer and bullnose orientation for horizontal, vertical, and sloped edges, including nested active edit contexts.
- Implemented Flip and Start/End Return geometry for railing paths instead of reporting success without a visible change.
- Prevented Detach Boundaries from reporting success when a wall has no attached boundary.
- Improved unsupported-path guidance to distinguish parametric Draupr paths from ordinary SketchUp groups.

## 4.1.38 Preview

- Relaxed the overly aggressive Dormer height auto-fit behavior.
- Treats the sketched footprint depth as a minimum placement footprint and may extend the rear roof join uphill to preserve the requested wall and roof heights.
- Computes the usable uphill distance at both Dormer sides from the actual selected roof face.
- Prevents automatic extension from crossing the host roof ridge or outer boundary.
- Falls back to proportional fitting only when the real host face cannot contain the requested Dormer dimensions.

## 4.1.37 Preview

- Replaced the generic icon library with 41 original Draupr CAD/BIM icons drawn specifically for their commands.
- Used the approved bold architectural direction while correcting duplicated, mislabeled, and ambiguous metaphors.
- Clarified Wall, Curtain Wall, Door, Window, structural, hosted-object, boundary, opening, profile, and roof operations.
- Preserved the semantic palette: navy geometry, blue targets, orange actions, red removals, green joins, and cyan glazing.
- Audited every icon at palette size in light and dark modes; tooltips and screen-reader labels remain intact.

## 4.1.36 Preview

- Rebased all 17 Create and 18 Modify tool shapes on the MIT-licensed Tabler icon system.
- Mapped familiar standard symbols such as Cut, Align, Join, Unlink, Layers, Stairs, Wall, Door, Window, Roof/Home, Fence, Grid, and Border Radius to their matching commands.
- Preserved Draupr's blue/orange/green/red/cyan semantic CAD overlays for domain-specific meaning.
- Added generated offline SVG assets and third-party attribution; no runtime web or Node dependency is required.

## 4.1.35 Preview

- Corrected low-contrast workspace icons on the permanently dark sidebar.
- Replaced ambiguous sidebar symbols with familiar Create, Edit, Modify/Wrench, Materials/Paint, Library/Books, and Project/Building metaphors.
- Added dedicated inactive, hover, and active colors for the dark navigation rail.
- Preserved Draupr's semantic multicolor command icons and translated hover labels.

## 4.1.34 Preview

- Introduced a custom multicolor CAD icon family across all Create and Modify commands.
- Standardized semantic color roles: dark existing geometry, blue targets, orange actions, green additions, red cuts/removals, and translucent cyan glazing.
- Added theme-aware color variants and preserved disabled, active, hover, RTL, tooltip, and accessibility states.
- Kept every icon original to Draupr while following established CAD legibility patterns.

## 4.1.33 Preview

- Rebuilt every Create and Modify icon around the actual architectural object or operation it controls.
- Replaced abstract modifier marks with explicit wall, opening, boundary, profile, and roof diagrams.
- Increased icon drawing area and standardized rounded 1.55 px strokes for clarity at SketchUp palette size.
- Retained translated hover labels, keyboard-focus labels, and screen-reader names.

## 4.1.32 Preview

- Replaced creation and modifier command text with a consistent architectural SVG icon system.
- Added accessible English/Persian hover labels, keyboard-focus labels, and screen-reader names.
- Corrected the Knife indicator to use the hovered assembly face and the exact local wall boundary height.
- Prevented roof-attached wall Knife lines from extending to an unrelated global ridge height.
- Corrected Knife preview transforms for objects in the active edit context.

## 4.1.31 Preview

- Moved the complete Studio interface into one tabbed vertical ribbon shell.
- Replaced the separate compact Ribbon and full Studio windows with a single primary interface.
- Added a collapsible workspace rail while retaining all Create, Edit, Modify, Materials, Library, and Project controls.
- Optimized detailed fields, galleries, action docks, and responsive behavior for a 480 px vertical palette.

## 4.1.30 Preview

- Added a compact tabbed vertical Draupr Ribbon for fast access to creation, modification, opening, roof, material, library, and project commands.
- Added icons-only collapsed mode with persistent size/state and English/Persian layout support.
- Kept the full Draupr Studio inspector available for detailed parameters and advanced workflows.

All notable changes to Draupr Studio are documented here.

## 4.1.29 Preview

- Added seamless textured Dormer siding and a dedicated siding material role.
- Removed Dormer gutter geometry and projecting siding-board geometry.
- Clipped Dormer crowns, front walls, and cheeks below the true roof underside.
- Preserved exact roof-host intersections, adaptive windows, shutters, dark fascia, and physical roof openings.
- Continued Knife, roof-join, attach-top, opening-heal, and cursor regression fixes.

## Earlier Preview work

Detailed feature-level regression notes are available under `Draupr/qa/`.
