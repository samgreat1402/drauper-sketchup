# Draupr 4.1.2 Preview — Roof Envelope and L-Wall Trim Fix

## Roof attachment
The previous modifier stored only the clicked roof-face plane. On hip/gable roofs that plane was extrapolated across the whole wall, creating oversized triangular wall tops. Roof targets now store every canonical roof slope as a bounded underside surface in wall-local coordinates. Every wall-layer vertex resolves against the containing slope, and attached caps are triangulated for safe ridge transitions. Sync regenerates the complete envelope after roof edits.

## L-wall trim/extend
Explicit Trim/Extend now removes stale automatic `end_trims` before rebuilding. It preserves the junction at the opposite end of a segment and rejects only when the specifically selected endpoint is joined. The bilingual error now tells the user to choose the free endpoint or detach the selected junction.

## Knife rewrite
- The custom cursor hotspot now follows the visible blade tip (`27,4`) instead of the handle.
- Preview is a complete cut-plane rectangle sized from the actual object bounds.
- Cut stations have deterministic endpoint clearance and no silent preview failures.
- Wall start/end junction metadata and per-segment wall/foundation overrides are redistributed to the correct child.
- If an original wall UID moves to one child, the opposite joined peer is relinked transactionally.
- Hosted wall openings remain protected until a dedicated host-redistribution workflow is available.
