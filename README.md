
# Magnesium (Mg)

This is an experimental scene graph / layer compositing framework.


## Goals

- Explore what happens when compositor objects can have multiple
parents. (E.g. what replaces the -convertPoint:fromView: style methods?)

- Will be rendered directly (to CGContext initially), or translated at
runtime to a CALayer/UIView hierarchy.

- 2D only for now, but don't prevent adding 2.5D later.

- Build support for node/document states into the scene graph.

- Integrate spring dynamics simulation. Try to unify dynamics and
declarative animations.


## Implementation Decisions

- Layers don't render content, their child nodes can be layers or
content objects (no geometry, only drawing). This simplifies the base
layer class.

- Enabled property is not animatable. This allows hidden subtrees to be
pruned before they get to the render tree.

- No transactions or built-in thread safety. Callers will modify the
shared object graph, then manually render it to a drawing context or
commit its translation to a hosting CALayer.

- Animations are nodes in the scene graph (although they aren't
"drawable"). They can be added to any drawable object but can't target
properties of that object's descendants.

- Ignore filters for now. At some point try to solve the "background
filters suck" problem. Support N-input filters, e.g. either a filter
attached to a layer that takes another drawable node as input, or make
filters be drawable nodes themselves.

- Coordinate space is relative to top-left corner, on both Mac and iOS.


## Class Hierarchy (work in progress)

<pre>
MgNode : NSObject

 -- stores the version number of this node and its children
 -- internally caches an array of supernodes ("references")
 -- abstract child traversal (with optional de-dup'ing)

  BOOL enabled
  NSString *name

MgTiming (protocol)

  double begin, duration, speed, offset, repeat
  bool autoreverses, holdsBeforeStart, holdsAfterEnd

MgLayerNode : MgDrawableNode <MgTiming>

  CGPoint position
  CGPoint anchor
  CGRect bounds
  CGFloat cornerRadius
  CGFloat scale, squeeze, skew
  double rotation
  float alpha
  CGBlendMode blendMode
  MgDrawableNode *mask
  NSArray<MgAnimationNode> *animations

MgGroupNode : MgLayerNode

  BOOL group
  NSArray<MgDrawableNode> *contents

MgRectNode : MgLayerNode

  CGPathDrawingMode drawingMode
  CGColorRef fillColor
  CGColorRef strokeColor
  CGFloat lineWidth

  Draws into bounds rect of containing layer.

MgImageNode : MgLayerNode

  id<MgImageProvider> imageProvider
  CGRect cropRect		-- in image pixels
  CGRect centerRect		-- in image pixels
  BOOL repeats

  Draws into bounds rect of containing layer.

MgPathNode : MgLayerNode

  CGPathRef path
  CGPathDrawingMode drawingMode
  CGColorRef fillColor
  CGColorRef strokeColor
  -- and the usual stroke parameters

MgGradientNode : MgLayerNode

  NSArray<CGColorRef> *colors
  NSArray<NSNumber> *locations
  BOOL radial
  CGPoint startPoint, endPoint
  CGFloat startRadius, endRadius
  BOOL drawsBeforeStart, drawsAfterEnd

MgAnimationNode : MgNode <MgTiming>

  NSString *keyPath
  MgTimingFunction *timingFunction
  MgFunction *valueFunction

MgBasicAnimationNode : MgAnimationNode

  id fromValue, toValue
</pre>
