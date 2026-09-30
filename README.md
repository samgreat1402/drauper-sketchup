# Draupr Studio

**Draupr Studio** is a free and open-source parametric architectural modeling extension for SketchUp. It provides intelligent architectural objects, hosted relationships, material workflows, editing tools, and bilingual English–Persian support.

[![License: GPL v3+](https://img.shields.io/badge/License-GPLv3%2B-blue.svg)](LICENSE)
[![Release](https://img.shields.io/badge/release-4.1.29%20Preview-orange.svg)](Draupr/src/config/release.json)
[![Native testing](https://img.shields.io/badge/native%20testing-required-red.svg)](Draupr/qa/NATIVE_ACCEPTANCE.md)

> **Project status: Preview.** The source is published for testing and contribution. Review the native acceptance checklist before using Draupr in production work.

## Features

- Parametric walls, roofs, slabs, beams, columns, foundations, stairs, railings, ramps, louvers, skylights, dormers, doors, and windows.
- Hosted openings that remain associated with their walls and roofs.
- Roof edge-to-face joins, wall junctions, boundary attachment, split/knife, trim, alignment, and healing tools.
- Nine roof-hosted Dormer types with physical roof openings and editable materials.
- Material assignment, reusable presets, object library, project levels, quantities, and reports.
- English and Persian user interface with RTL support.
- SketchUp-native Undo/Redo transactions and persistent parametric metadata.

## Current preview

The current source version is **4.1.29 Preview**. Recent Dormer work includes:

- exact host-roof plane intersections;
- adaptive divided-light windows and optional Gabled shutters;
- seamless horizontal-siding material instead of projecting siding boards;
- crown and cheek clipping against the true offset roof underside;
- removal of duplicate soffit sheets and Dormer gutters;
- separate facade trim, roof fascia, frame, glass, siding, and roof materials.

## Installation

### Install an RBZ build

1. Download an `.rbz` package from the repository Releases page.
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
