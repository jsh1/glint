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

@implementation YuViewerOverlayNode
{
  NSArray *_selection;			/* NSArray<YuTreeNode> */
  NSInteger _lastVersion;
}

- (void)drawNode:(YuTreeNode *)tn withState:(id<MgDrawingState>)st
{
  /* FIXME: concatenating into one matrix only works because everything
     is affine, that may change... */

  CGAffineTransform m = CGAffineTransformIdentity;
  MgLayerNode *container = nil;

  for (YuTreeNode *pn = tn; pn != nil; pn = pn.parent)
    {
      MgLayerNode *layer = (MgLayerNode *)pn.node;

      if (![layer isKindOfClass:[MgLayerNode class]])
	continue;

      if (container == nil)
	container = layer;

      m = CGAffineTransformConcat(m, layer.parentTransform);
    }

  if (container == nil)
    return;

  m = CGAffineTransformConcat(m, [self.view viewTransform]);

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

  CGContextRef ctx = st.context;

  /* Use dashed outline for non-layer [drawable] nodes. */

  if (container == tn.node)
    CGContextSetLineDash(ctx, 0, NULL, 0);
  else
    {
      CGFloat dash[2] = {10, 5};
      CGContextSetLineDash(ctx, 0, dash, 2);
    }

  /* Line width of 1 for non-rectilinear lines looks too thin and ropey.
     So fatten up those lines a touch. */

  CGContextSetLineWidth(ctx, MgAffineTransformIsRectilinear(&m) ? 1 : M_SQRT2);

  CGContextStrokeLineSegments(ctx, l, 8);
}

- (void)drawWithState:(id<MgDrawingState>)st
{
  YuWindowController *controller = self.view.controller.controller;

  CGContextRef ctx = st.context;

  CGContextSaveGState(ctx);

  CGContextSetStrokeColorWithColor(ctx, [[YuColor viewerOverlayColor] CGColor]);

  for (YuTreeNode *tn in _selection)
    [self drawNode:tn withState:st];

  CGContextRestoreGState(ctx);

  _lastVersion = controller.document.documentNode.version;
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
