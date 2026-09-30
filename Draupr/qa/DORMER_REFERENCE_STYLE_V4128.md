# Reference-style integrated Gabled Dormer — v4.1.28

## Reference interpretation

The supplied photograph shows a traditional roof-integrated Gabled Dormer:

- a compact gabled roof intersecting the main roof;
- dark roof-edge fascia instead of bright facade trim on the roof;
- a narrower, vertically proportioned divided-light window;
- paired louvered shutters;
- subtle horizontal siding;
- simple light facade casing and sill;
- tapered cheek walls disappearing into the host roof.

The photograph is used as a design reference, not copied geometry.

## Implementation

- Preserve the exact host-plane roof intersection and tapered solid cheeks.
- Narrow the window when shutters are enabled.
- Add a center mullion, meeting rail, and two glazing bars.
- Add parametric paired shutters with perimeter frames, middle rails, and
  repeated louver slats.
- Add shallow horizontal siding reveals around the window and within the crown.
- Separate light facade trim from dark roof fascia materials.
- Keep the solid roof underside and optional side gutters.
- Add controls for shutters, siding detail, gutters, and roof-fascia material.
- Restrict shutters to the Gabled type so curved and flat Dormers retain their
  appropriate identities.

## Native acceptance

Compare a default Gabled Dormer with the reference at front, oblique, and side
views. Verify the window remains vertical and centered, shutters fit between
the casing and corner boards, siding does not cross the opening, dark fascia
follows both rakes, and cheeks terminate cleanly at the host roof.