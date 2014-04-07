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

#import "GtViewerOverlayLayer.h"

#import "GtColor.h"
#import "GtDocument.h"
#import "GtTreeNode.h"
#import "GtViewerView.h"
#import "GtViewerViewController.h"
#import "GtWindowController.h"

#import "MgCoreGraphics.h"

#define ADORNMENT_SIZE 12
#define INNER_ADORNMENT_RADIUS 50
#define HIT_THRESH ADORNMENT_SIZE

@implementation GtViewerOverlayLayer
{
  NSArray *_selection;			/* NSArray<GtTreeNode> */
  NSInteger _lastVersion;

  GtViewerAdornmentMask _adornmentMask;

  id _adornmentImage;			/* CGImageRef */

  CGSize _documentSize;
  CGPoint _viewCenter;
  CGFloat _viewScale;
  CGAffineTransform _viewTransform;
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _adornmentMask = (1U << GtViewerAdornmentCount) - 1;

  return self;
}

+ (BOOL)automaticallyNotifiesObserversOfAdornmentMask
{
  return NO;
}

- (GtViewerAdornmentMask)adornmentMask
{
  return _adornmentMask;
}

- (void)setAdornmentMask:(GtViewerAdornmentMask)x
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
  [GtViewerAdornmentCornerRadius] = {0, 0},
  /* Bounds relative. */
  [GtViewerAdornmentResizeTopLeft] = {0, 0},
  [GtViewerAdornmentResizeTop] = {.5, 0},
  [GtViewerAdornmentResizeTopRight] = {1, 0},
  [GtViewerAdornmentResizeBottomLeft] = {0, 1},
  [GtViewerAdornmentResizeBottom] = {.5, 1},
  [GtViewerAdornmentResizeBottomRight] = {1, 1},
  [GtViewerAdornmentResizeLeft] = {0, .5},
  [GtViewerAdornmentResizeRight] = {1, .5},
  /* Center relative. */
  [GtViewerAdornmentAnchor] = {0, 0},
  [GtViewerAdornmentRotate] = {1, 0},
  [GtViewerAdornmentScale] = {0, -1},
  [GtViewerAdornmentSqueeze] = {-1, 0},
  [GtViewerAdornmentSkew] = {0, 1},
};

static MgLayer *
getLayerAndTransform(GtTreeNode *node, CGAffineTransform *ret_m)
{
  CGAffineTransform m = CGAffineTransformIdentity;
  MgLayer *container = nil;

  for (GtTreeNode *pn = node; pn != nil; pn = pn.parent)
    {
      MgLayer *layer = (MgLayer *)pn.node;

      if (![layer isKindOfClass:[MgLayer class]])
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

static CGRect
rect_slice_8(CGRect content, CGRect bounds, size_t i)
{
  CGFloat llx, lly, urx, ury;

  switch (i)
    {
    case 0: case 3: case 5:
      llx = bounds.origin.x;
      urx = content.origin.x;
      break;

    case 1: case 6:
      llx = content.origin.x;
      urx = content.origin.x + content.size.width;
      break;

    case 2: case 4: case 7:
      llx = content.origin.x + content.size.width;
      urx = bounds.origin.x + bounds.size.width;
      break;
    }

  switch (i)
    {
    case 0: case 1: case 2:
      lly = bounds.origin.y;
      ury = content.origin.y;
      break;

    case 3: case 4:
      lly = content.origin.y;
      ury = content.origin.y + content.size.height;
      break;

    case 5: case 6: case 7:
      lly = content.origin.y + content.size.height;
      ury = bounds.origin.y + bounds.size.height;
      break;
    }

  llx = round(llx);
  lly = round(lly);
  urx = round(urx);
  ury = round(ury);

  return CGRectMake(llx, lly, fmax(0, urx-llx), fmax(0, ury-lly));
}

- (void)drawBorderInContext:(CGContextRef)ctx
{
  CGRect bounds = self.bounds;

  CGRect docR;
  docR.origin.x = _viewCenter.x - _documentSize.width * _viewScale * .5;
  docR.origin.y = _viewCenter.y - _documentSize.height * _viewScale * .5;
  docR.size.width = _documentSize.width * _viewScale;
  docR.size.height = _documentSize.height * _viewScale;

  CGContextSaveGState(ctx);

  CGContextSetFillColorWithColor(ctx, [[GtColor viewerBorderColor] CGColor]);

  for (size_t i = 0; i < 8; i++)
    {
      CGRect r = rect_slice_8(docR, bounds, i);
      CGContextFillRect(ctx, r);
    }

  CGContextRestoreGState(ctx);
}

- (void)drawNode:(GtTreeNode *)tn inContext:(CGContextRef)ctx
{
  /* FIXME: concatenating into one matrix only works because everything
     is affine, that may change... */

  CGAffineTransform m;
  MgLayer *container = getLayerAndTransform(tn, &m);
  if (container == nil)
    return;

  CGContextSaveGState(ctx);
  
  m = CGAffineTransformConcat(m, _viewTransform);

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

  GtViewerAdornmentMask mask = self.adornmentMask;

  if (![tn.node isKindOfClass:[MgRectLayer class]])
    mask &= ~GtViewerAdornmentMaskCornerRadius;

  if (mask != 0 && container == tn.node)
    {
      CGPoint anchor = container.anchor;
      CGRect bounds = container.bounds;

      CGRect rects[GtViewerAdornmentCount];
      size_t count = 0;

      for (NSInteger i = GtViewerAdornmentCount; mask != 0 && i >= 0; i--)
	{
	  GtViewerAdornmentMask bit = 1U << i;

	  if ((mask & bit) == 0)
	    continue;

	  CGPoint p = adornmentPositions[i];

	  if (i < GtViewerAdornmentAnchor)
	    {
	      p.x = p.x * bounds.size.width;
	      p.y = p.y * bounds.size.height;

	      if (i == GtViewerAdornmentCornerRadius)
		p.x += ((MgRectLayer *)container).cornerRadius;
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
  GtDocument *document = self.view.controller.document;

  [self drawBorderInContext:st.context];

  for (GtTreeNode *tn in _selection)
    [self drawNode:tn inContext:st.context];

  _lastVersion = document.documentNode.version;
}

- (NSInteger)hitTest:(CGPoint)point inAdornmentsOfNode:(GtTreeNode *)tn
{
  CGAffineTransform m;
  MgLayer *container = getLayerAndTransform(tn, &m);
  if (container == nil || container != tn.node)
    return NSNotFound;

  GtViewerAdornmentMask mask = self.adornmentMask;

  if (![tn.node isKindOfClass:[MgRectLayer class]])
    mask &= ~GtViewerAdornmentMaskCornerRadius;

  if (mask == 0)
    return NSNotFound;

  CGPoint anchor = container.anchor;
  CGRect bounds = container.bounds;

  for (NSInteger i = 0; mask != 0 && i < GtViewerAdornmentCount; i++)
    {
      GtViewerAdornmentMask bit = 1U << i;

      if ((mask & bit) == 0)
	continue;

      CGPoint p = adornmentPositions[i];

      if (i < GtViewerAdornmentAnchor)
	{
	  p.x = p.x * bounds.size.width;
	  p.y = p.y * bounds.size.height;

	  if (i == GtViewerAdornmentCornerRadius)
	    p.x += ((MgRectLayer *)container).cornerRadius;
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

- (void)update
{
  GtViewerView *view = self.view;
  GtWindowController *controller = view.controller.windowController;
  GtDocument *document = controller.document;
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

  CGFloat scale = view.viewScale;
  CGSize size = document.documentSize;
  CGPoint center = view.viewCenter;
  CGAffineTransform transform = view.viewTransform;

  if (scale != _viewScale
      || !CGSizeEqualToSize(size, _documentSize)
      || !CGPointEqualToPoint(center, _viewCenter)
      || !CGAffineTransformEqualToTransform(transform, _viewTransform))
    {
      _viewScale = scale;
      _documentSize = size;
      _viewCenter = center;
      _viewTransform = transform;
      [self setNeedsDisplay];
    }
}

@end
