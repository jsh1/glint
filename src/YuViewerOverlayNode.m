/* -*- c-style: gnu -*-

   Copyright (c) 2014 John Harper <jsh@unfactored.org>

   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation files
   (the "Software"), to deal in the Software without restriction,
   including without limitation the rights to use, copy, modify, merge,
   publish, distribute, sublicense, and/or sell copies of the Software,
   and to permit persons to whom the Software is furnished to do so,
   subject to the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE. */

#import "YuViewerOverlayNode.h"

#import "YuColor.h"
#import "YuDocument.h"
#import "YuTreeNode.h"
#import "YuViewerView.h"
#import "YuViewerViewController.h"
#import "YuWindowController.h"

#import "MgCoreGraphics.h"
#import "MgLayerNode.h"

#define ADORNMENT_SIZE 8
#define INNER_ADORNMENT_RADIUS 50
#define HIT_THRESH (ADORNMENT_SIZE + 4)

@implementation YuViewerOverlayNode
{
  NSArray *_selection;			/* NSArray<YuTreeNode> */
  NSInteger _lastVersion;

  YuViewerAdornmentMask _adornmentMask;
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _adornmentMask = (1U << YuViewerAdornmentCount) - 1;

  return self;
}

+ (BOOL)automaticallyNotifiesObserversOfAdornmentMask
{
  return NO;
}

- (YuViewerAdornmentMask)adornmentMask
{
  return _adornmentMask;
}

- (void)setAdornmentMask:(YuViewerAdornmentMask)x
{
  if (_adornmentMask != x)
    {
      [self willChangeValueForKey:@"adornmentMask"];
      _adornmentMask = x;
      [self setNeedsDisplay];
      [self didChangeValueForKey:@"adornmentMask"];
    }
}

static const CGPoint adornmentPositions[] =
{
  /* Absolute. */
  [YuViewerAdornmentResizeTopLeft] = {0, 0},
  [YuViewerAdornmentResizeTop] = {.5, 0},
  [YuViewerAdornmentResizeTopRight] = {1, 0},
  [YuViewerAdornmentResizeBottomLeft] = {0, 1},
  [YuViewerAdornmentResizeBottom] = {.5, 1},
  [YuViewerAdornmentResizeBottomRight] = {1, 1},
  [YuViewerAdornmentResizeLeft] = {0, .5},
  [YuViewerAdornmentResizeRight] = {1, .5},
  /* Special. */
  [YuViewerAdornmentCornerRadius] = {0, 0},
  /* Center relative. */
  [YuViewerAdornmentAnchor] = {0, 0},
  [YuViewerAdornmentRotate] = {1, 0},
  [YuViewerAdornmentScale] = {0, -1},
  [YuViewerAdornmentSqueeze] = {-1, 0},
  [YuViewerAdornmentSkew] = {0, 1},
};

static MgLayerNode *
getLayerAndTransform(YuTreeNode *node, CGAffineTransform *ret_m)
{
  CGAffineTransform m = CGAffineTransformIdentity;
  MgLayerNode *container = nil;

  for (YuTreeNode *pn = node; pn != nil; pn = pn.parent)
    {
      MgLayerNode *layer = (MgLayerNode *)pn.node;

      if (![layer isKindOfClass:[MgLayerNode class]])
	continue;

      if (container == nil)
	container = layer;

      m = CGAffineTransformConcat(m, layer.parentTransform);
    }

  if (container == nil)
    return nil;

  if (ret_m != NULL)
    *ret_m = m;

  return container;
}

- (void)drawNode:(YuTreeNode *)tn withState:(id<MgDrawingState>)st
{
  /* FIXME: concatenating into one matrix only works because everything
     is affine, that may change... */

  CGAffineTransform m;
  MgLayerNode *container = getLayerAndTransform(tn, &m);
  if (container == nil)
    return;

  m = CGAffineTransformConcat(m, [self.view viewTransform]);
  bool rectilinear = MgAffineTransformIsRectilinear(&m);

  CGContextRef ctx = st.context;

  if (1)
    {
      CGPoint p[4];
      MgRectGetCorners(container.bounds, p);

      for (size_t i = 0; i < 4; i++)
	{
	  p[i] = CGPointApplyAffineTransform(p[i], m);
	  p[i].x = floor(p[i].x) + .5;
	  p[i].y = floor(p[i].y) + .5;
	}

      CGPoint l[8];
      l[0] = p[0]; l[1] = p[1];
      l[2] = p[1]; l[3] = p[2];
      l[4] = p[2]; l[5] = p[3];
      l[6] = p[3]; l[7] = p[0];

      CGContextSaveGState(ctx);

      /* Use dashed outline for non-layer [drawable] nodes. */

      if (container == tn.node)
	CGContextSetLineDash(ctx, 0, NULL, 0);
      else
	{
	  CGFloat dash[2] = {10, 5};
	  CGContextSetLineDash(ctx, 0, dash, 2);
	}

      /* Line width of 1 for non-rectilinear lines looks too thin and
	 ropey. So fatten those up a touch. */

      CGContextSetLineWidth(ctx, rectilinear ? 1 : M_SQRT2);

      CGContextStrokeLineSegments(ctx, l, 8);

      CGContextRestoreGState(ctx);
    }

  YuViewerAdornmentMask mask = self.adornmentMask;

  if (mask != 0 && container == tn.node)
    {
      CGPoint anchor = container.anchor;
      CGRect bounds = container.bounds;

      CGContextSaveGState(ctx);

      for (NSInteger i = 0; mask != 0 && i < YuViewerAdornmentCount; i++)
	{
	  YuViewerAdornmentMask bit = 1U << i;

	  if ((mask & bit) == 0)
	    continue;

	  CGPoint p = adornmentPositions[i];

	  if (i < YuViewerAdornmentAnchor)
	    {
	      p.x = p.x * bounds.size.width;
	      p.y = p.y * bounds.size.height;

	      if (i == YuViewerAdornmentCornerRadius)
		p.x += container.cornerRadius;
	    }
	  else
	    {
	      p.x = (anchor.x * bounds.size.width
		     + p.x * INNER_ADORNMENT_RADIUS);
	      p.y = (anchor.y * bounds.size.height
		     + p.y * INNER_ADORNMENT_RADIUS);
	    }

	  CGPoint mp = CGPointApplyAffineTransform(p, m);
	  mp.x = round(mp.x);
	  mp.y = round(mp.y);

	  CGRect r = CGRectMake(mp.x - ADORNMENT_SIZE*.5, mp.y
			- ADORNMENT_SIZE*.5, ADORNMENT_SIZE, ADORNMENT_SIZE);

	  /* FIXME: draw something better, or at least rotate to match
	     the layer orientation. Also need a way to differentiate
	     when flipped or rotated. */

	  CGContextFillRect(ctx, r);

	  mask &= ~bit;
	}

      CGContextRestoreGState(ctx);
    }
}

- (void)drawWithState:(id<MgDrawingState>)st
{
  YuWindowController *controller = self.view.controller.controller;

  CGContextRef ctx = st.context;

  CGContextSaveGState(ctx);

  CGContextSetStrokeColorWithColor(ctx, [[YuColor viewerOverlayColor] CGColor]);
  CGContextSetFillColorWithColor(ctx, [[YuColor viewerOverlayColor] CGColor]);

  for (YuTreeNode *tn in _selection)
    [self drawNode:tn withState:st];

  CGContextRestoreGState(ctx);

  _lastVersion = controller.document.documentNode.version;
}

- (NSInteger)hitTest:(CGPoint)point inAdornmentsOfNode:(YuTreeNode *)tn
{
  CGAffineTransform m;
  MgLayerNode *container = getLayerAndTransform(tn, &m);
  if (container == nil || container != tn.node)
    return NSNotFound;

  YuViewerAdornmentMask mask = self.adornmentMask;
  if (mask == 0)
    return NSNotFound;

  CGPoint anchor = container.anchor;
  CGRect bounds = container.bounds;

  for (NSInteger i = 0; mask != 0 && i < YuViewerAdornmentCount; i++)
    {
      YuViewerAdornmentMask bit = 1U << i;

      if ((mask & bit) == 0)
	continue;

      CGPoint p = adornmentPositions[i];

      if (i < YuViewerAdornmentAnchor)
	{
	  p.x = p.x * bounds.size.width;
	  p.y = p.y * bounds.size.height;

	  if (i == YuViewerAdornmentCornerRadius)
	    p.x += container.cornerRadius;
	}
      else
	{
	  p.x = (anchor.x * bounds.size.width
		 + p.x * INNER_ADORNMENT_RADIUS);
	  p.y = (anchor.y * bounds.size.height
		 + p.y * INNER_ADORNMENT_RADIUS);
	}

      p = CGPointApplyAffineTransform(p, m);
      p.x = round(p.x);
      p.y = round(p.y);

      if (fabs(p.x - point.x) < HIT_THRESH
	  && fabs(p.y - point.y) < HIT_THRESH)
	return i;

      mask &= ~bit;
    }

  return NSNotFound;
}

- (void)updateSelectedNodes
{
  YuWindowController *controller = self.view.controller.controller;
  YuDocument *document = controller.document;
  NSArray *sel = controller.selection;

  if (![_selection isEqual:sel])
    {
      _selection = [sel copy];
      [self setNeedsDisplay];
    }
  else if (_lastVersion != document.documentNode.version)
    {
      [self setNeedsDisplay];
    }
}

- (void)update
{
  [self updateSelectedNodes];
}

@end
