
# Magnesium (Mg)

This is a simple layer compositing framework, primarily to support the
Glint app and the assets it produces, but conceivably could be useful
in its own right when finished.

- Main priority is simple and logical behavior when viewed by a
designer through an app wrapping the API.

- Each object may have multiple states, and authored transitions
between those states.

- Renders either by translating the Mg graph to a CALayer/UIView
hierarchy, or by drawing into a CGContext.

Both modes are fully supported and interchangeable. Subgraphs can opt
in and out of the CG-rasterized mode at any time, e.g. to take
advantage of the different performance trade-offs.

- Will attempt to integrate spring-dynamics simulation, trying to unify
dynamics and declarative animations.


## API Mechanics

- Compositing tree is actually a DAG (i.e. each object may have
multiple parents).

- Basic layer class doesn't render content or have sublayers. There are
subclasses for that. This simplifies the API, and thus the app's user
interface.

- Coordinate space is relative to top-left corner, on both Mac and iOS.

- 2D only for now, but doesn't have anything that prevents 2.5D later.
