
# Magnesium (Mg)

This is an experimental scene graph / layer compositing framework.


## Goals

- Priority is simple and logical behavior when viewed by a designer
through an app wrapping the API.

- Explore what happens when compositor objects can have multiple
parents. (E.g. what replaces the -convertPoint:fromView: style
methods?)

- Either render directly (to CGContext initially), or translate at
run-time to a CALayer/UIView hierarchy.

- 2D only for now, but don't do anything that stops 2.5D later.

- Integrate spring dynamics simulation. Try to unify dynamics and
declarative animations.


## Implementation Decisions

- Layers don't render content or have sublayers. There are subclasses
that each provide a specific kind of content or add sublayers. This
simplifies the base layer class.

- The enabled (aka hidden) property is not animatable. This allows
hidden subtrees to be pruned before they get to the render tree.

- Coordinate space is relative to top-left corner, on both Mac and iOS.


## Class Hierarchy (work in progress)

<pre>
MgNode : NSObject

  -- stores the version number of this node and its children
  -- internally caches an array of supernodes ("references")
  -- abstract child traversal (with optional de-dup'ing)

  BOOL enabled
  NSString *name

MgLayer : MgNode

  CGPoint position
  CGPoint anchor
  CGRect bounds
  CGFloat scale, squeeze, skew
  double rotation
  float alpha
  CGBlendMode blendMode
  MgLayer *mask

MgGroupLayer : MgLayer

  BOOL group
  NSArray<MgLayer> *contents

MgRectLayer : MgLayer

  CGFloat cornerRadius
  CGPathDrawingMode drawingMode
  CGColorRef fillColor
  CGColorRef strokeColor
  CGFloat lineWidth

MgImageLayer : MgLayer

  id<MgImageProvider> imageProvider
  CGRect cropRect		-- in image pixels
  CGRect centerRect		-- in image pixels
  BOOL repeats

MgPathLayer : MgLayer

  CGPathRef path
  CGPathDrawingMode drawingMode
  CGColorRef fillColor
  CGColorRef strokeColor
  -- and the usual stroke parameters

MgGradientLayer : MgLayer

  NSArray<CGColorRef> *colors
  NSArray<NSNumber> *locations
  BOOL radial
  CGPoint startPoint, endPoint
  CGFloat startRadius, endRadius
  BOOL drawsBeforeStart, drawsAfterEnd
</pre>
