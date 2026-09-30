# Contributing to Draupr Studio

Thank you for helping improve Draupr.

## Workflow

1. Open an issue for substantial behavioral or schema changes.
2. Fork the repository and create a focused branch.
3. Keep commits small and descriptive.
4. Add or update regression notes under `Draupr/qa/`.
5. Test the affected workflow in SketchUp, including Undo/Redo and save/reload.
6. Open a pull request describing the problem, solution, and test coverage.

## Code expectations

- Use SketchUp Ruby API operations transactionally.
- Preserve hosted relationships and stable object identifiers.
- Avoid destructive edits outside the active object context.
- Keep English and Persian messages synchronized.
- Do not add telemetry, credentials, or network dependencies without prior discussion.
- Do not commit copyrighted models or textures without redistribution permission.

By contributing, you agree that your contribution is licensed under GPL-3.0-or-later.
