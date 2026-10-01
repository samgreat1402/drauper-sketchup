# Draupr Studio

**Draupr Studio** is a free and open-source parametric architectural modeling extension for SketchUp. It provides intelligent architectural objects, hosted relationships, material workflows, editing tools, and bilingual English–Persian support.

[![License: GPL v3+](https://img.shields.io/badge/License-GPLv3%2B-blue.svg)](LICENSE)
[![Release](https://img.shields.io/badge/release-4.1.43%20Preview-orange.svg)](https://github.com/samgreat1402/drauper-sketchup/releases/tag/v4.1.43)
[![Native testing](https://img.shields.io/badge/native%20testing-required-red.svg)](Draupr/qa/NATIVE_ACCEPTANCE.md)

> **Project status: Preview.** The source is published for testing and contribution. Review the native acceptance checklist before using Draupr in production work.

## Features

- Parametric walls, roofs, slabs, beams, columns, foundations, stairs, railings, ramps, louvers, skylights, dormers, doors, and windows.
- Hosted openings that remain associated with their walls and roofs.
- Roof edge-to-face joins, wall junctions, boundary attachment, split/knife, trim, alignment, and healing tools.
- User-authored driving wall dimensions with SketchUp Measurements input, same-wall or external references, endpoint resizing, and relative whole-wall movement.
- Nine roof-hosted Dormer types with physical roof openings and editable materials.
- Material assignment, reusable presets, object library, project levels, quantities, and reports.
- English and Persian user interface with RTL support.
- Unified tabbed vertical Studio with icon-first creation and modifier tools, accessible hover labels, and the complete editing, material, library, and project interface.
- SketchUp-native Undo/Redo transactions and persistent parametric metadata.

## Current preview

The current source version is **4.1.43 Preview**. The latest release introduces user-authored driving wall dimensions instead of unreliable automatic dimensions:

- Pick a fixed reference on the target wall, another wall, or inferencable SketchUp geometry.
- Pick the start or end cap of the selected target wall.
- Place the temporary dimension and enter the required value in SketchUp Measurements.
- Drive the chosen endpoint along its wall axis, or move the whole wall for near-perpendicular relative dimensions.
- Preserve hosted openings and native Undo/Redo while protecting joined moving endpoints.
- Select thick-wall endpoints through visible end caps, end edges, or nearby corners in perspective views.

This workflow currently supports one straight, unscaled, two-point Draupr wall. Joined endpoints that would need to move are intentionally blocked in this Preview.

Recent releases also added the original function-specific CAD/BIM icon family, unified vertical Studio, corrected Knife indicators, expanded Dormer types, roof-hosted openings, material separation, and roof-junction tools.

## Driving wall dimensions

1. Select one straight Draupr wall.
2. Open **Modify → Driving Wall Dimension**.
3. Click the fixed reference.
4. Click an end cap, end edge, or endpoint of the selected wall.
5. Click to place the dimension line.
6. Type a value such as `4500mm`, `4.5m`, or `15'` in SketchUp Measurements and press **Enter**.

Press **Esc** to clear the current dimension; press **Esc** again to exit the tool.

## Installation

### Install an RBZ build

1. Download the latest `.rbz` package from the [v4.1.43 Preview release](https://github.com/samgreat1402/drauper-sketchup/releases/tag/v4.1.43).
2. Open **SketchUp → Extension Manager**.
3. Select **Install Extension** and choose the RBZ file.
4. Restart SketchUp if requested, then open **Extensions → Draupr Studio**.

### Build an RBZ from source

The GitHub source stores binary PNG assets as open Base64 data. Restore them first, then package the extension:

```bash
python3 tools/materialize_assets.py
zip -r Draupr_Studio.rbz Draupr.rb Draupr
```

The restoration script writes the cursor, icon, and texture PNGs to their required paths. The RBZ archive root must contain both `Draupr.rb` and the `Draupr/` directory.

## Repository layout

```text
Draupr.rb                 SketchUp extension loader
Draupr/main.rb            Extension bootstrap
Draupr/src/core/          Parametric geometry and object services
Draupr/src/studio/        Interactive SketchUp tools and pickers
Draupr/src/ui/            HTML dialog and generated UI schema
Draupr/src/config/        Release and tool schemas
Draupr/src/assets/        Icons, cursors, textures, and presets
Draupr/qa/                Regression notes and acceptance checks
```

## Development

Draupr is written primarily in Ruby for the SketchUp Ruby API, with HTML, CSS, and JavaScript for the Studio dialog.

Before submitting changes:

1. Keep model edits inside a single SketchUp operation.
2. Preserve Undo/Redo behavior and parametric metadata.
3. Test English and Persian interfaces.
4. Run applicable static checks and native SketchUp acceptance cases.
5. Do not commit API keys, access tokens, passwords, private models, or user data.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution workflow.

## Reporting bugs

When opening an issue, include:

- SketchUp version and operating system;
- Draupr version;
- exact reproduction steps;
- screenshots or a minimal SKP fixture when possible;
- the complete error message from the Ruby Console.

Do not include confidential models or credentials. Security issues should follow [SECURITY.md](SECURITY.md).

## License

Draupr Studio is free software licensed under the **GNU General Public License, version 3 or later**. You may use, study, modify, and redistribute it under the GPL terms. Distributed modified versions must provide corresponding source code under a compatible GPL license.

See [LICENSE](LICENSE) and [LICENSE-NOTICE.md](LICENSE-NOTICE.md).

## Disclaimer

Draupr is provided without warranty. Preview geometry must be reviewed by qualified project professionals before construction or fabrication. SketchUp is a trademark of Trimble Inc.; this project is not affiliated with or endorsed by Trimble.
