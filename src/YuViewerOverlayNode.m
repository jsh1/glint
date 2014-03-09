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

#define ADORNMENT_SIZE 12
#define INNER_ADORNMENT_RADIUS 50
#define HIT_THRESH ADORNMENT_SIZE

@implementation YuViewerOverlayNode
{
  NSArray *_selection;			/* NSArray<YuTreeNode> */
  NSInteger _lastVersion;

  YuViewerAdornmentMask _adornmentMask;

  id _adornmentImage;			/* CGImageRef */
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
  /* Special. */
  [YuViewerAdornmentCornerRadius] = {0, 0},
  /* Bounds relative. */
  [YuViewerAdornmentResizeTopLeft] = {0, 0},
  [YuViewerAdornmentResizeTop] = {.5, 0},
  [YuViewerAdornmentResizeTopRight] = {1, 0},
  [YuViewerAdornmentResizeBottomLeft] = {0, 1},
  [YuViewerAdornmentResizeBottom] = {.5, 1},
  [YuViewerAdornmentResizeBottomRight] = {1, 1},
  [YuViewerAdornmentResizeLeft] = {0, .5},
  [YuViewerAdornmentResizeRight] = {1, .5},
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

static void
drawBlackAndWhite(CGContextRef ctx, void (^block)(CGColorRef color))
{
  CGContextTranslateCTM(ctx, -.5, .5);
  block(MgBlackColor());
  CGContextTranslateCTM(ctx, 1, -1);
  block(MgWhiteColor());
  CGContextTranslateCTM(ctx, -.5, .5);
}

static void
strokeLineSegments(CGContextRef ctx, const CGPoint lines[], size_t count)
{
  drawBlackAndWhite(ctx, ^(CGColorRef color)
    {
      CGContextSetStrokeColorWithColor(ctx, color);
      CGContextStrokeLineSegments(ctx, lines, count);
    });
}

- (void)drawNode:(YuTreeNode *)tn withState:(id<MgDrawingState>)st
{
  /* FIXME: concatenating into one matrix only works because everything
     is affine, that may change... */

  CGAffineTransform m;
  MgLayerNode *container = getLayerAndTransform(tn, &m);
  if (container == nil)
    return;

  CGContextRef ctx = st.context;

  CGContextSaveGState(ctx);
  
  m = CGAffineTransformConcat(m, [self.view viewTransform]);

  if (1)
    {
      CGPoint p[4];
      MgRectGetCorners(container.bounds, p);

      for (size_t i = 0; i < 4; i++)
	p[i] = CGPointApplyAffineTransform(p[i], m);

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

      strokeLineSegments(ctx, l, 8);

      CGContextRestoreGState(ctx);
    }

  YuViewerAdornmentMask mask = self.adornmentMask;

  if (mask != 0 && container == tn.node)
    {
      CGPoint anchor = container.anchor;
      CGRect bounds = container.bounds;

      CGRect rects[YuViewerAdornmentCount];
      size_t count = 0;

      for (NSInteger i = YuViewerAdornmentCount; mask != 0 && i >= 0; i--)
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

	  rects[count].origin.x = mp.x - ADORNMENT_SIZE*.5;
	  rects[count].origin.y = mp.y - ADORNMENT_SIZE*.5;
	  rects[count].size.width = ADORNMENT_SIZE;
	  rects[count].size.height = ADORNMENT_SIZE;
	  count++;

	  mask &= ~bit;
	}

      if (count != 0)
	{
	  CGImageRef im = (__bridge CGImageRef)_adornmentImage;

	  if (im == NULL)
	    {
	      size_t w = ADORNMENT_SIZE;
	      im = MgImageCreateByDrawing(w, w, false, ^(CGContextRef ctx)
		{
		  CGFloat c = w * .5;
		  CGFloat r = (ADORNMENT_SIZE-4)*.5;

		  drawBlackAndWhite(ctx, ^(CGColorRef color)
		    {
		      CGContextSetFillColorWithColor(ctx, color);
		      CGContextBeginPath(ctx);
		      CGContextAddArc(ctx, c, c, r, 0, 2*M_PI, 0);
		      CGContextFillPath(ctx);
		    });
		});

	      _adornmentImage = CFBridgingRelease(im);
	    }

	  for (size_t i = 0; i < count; i++)
	    CGContextDrawImage(ctx, rects[i], im);
	}
    }

  CGContextRestoreGState(ctx);
}

- (void)drawWithState:(id<MgDrawingState>)st
{
  YuWindowController *controller = self.view.controller.controller;

  for (YuTreeNode *tn in _selection)
    [self drawNode:tn withState:st];

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
