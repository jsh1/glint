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

#import "YuViewerView.h"

#import "YuColor.h"
#import "YuDocument.h"
#import "YuTreeNode.h"
#import "YuViewerOverlayNode.h"
#import "YuViewerViewController.h"
#import "YuWindowController.h"

#import "MgLayer.h"
#import "MgMacros.h"

#define MIN_SCALE (1. / 32)
#define MAX_SCALE 32

#define DRAG_MASK (NSLeftMouseDownMask | NSLeftMouseUpMask \
  | NSRightMouseDownMask | NSRightMouseUpMask | NSMouseMovedMask \
  | NSLeftMouseDraggedMask | NSRightMouseDraggedMask \
  | NSOtherMouseDownMask | NSOtherMouseUpMask | NSOtherMouseDraggedMask)

@implementation YuViewerView
{
  MgLayer *_nodeLayer;
  MgLayerNode *_rootNode;
  MgLayerNode *_documentContainer;
  YuViewerOverlayNode *_overlayNode;
  CGPoint _viewCenter;
  CGFloat _viewScale;
  NSTrackingArea *_trackingArea;
}

- (id)initWithFrame:(NSRect)r
{
  self = [super initWithFrame:r];
  if (self == nil)
    return nil;

  _viewScale = 1;

  return self;
}

+ (BOOL)automaticallyNotifiesObserversOfViewCenter
{
  return NO;
}

- (CGPoint)viewCenter
{
  return _viewCenter;
}

- (void)setViewCenter:(CGPoint)p
{
  if (!CGPointEqualToPoint(_viewCenter, p))
    {
      [self willChangeValueForKey:@"viewCenter"];
      _viewCenter = p;
      [self didChangeValueForKey:@"viewCenter"];
      [self setNeedsUpdate];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfViewScale
{
  return NO;
}

- (CGFloat)viewScale
{
  return _viewScale;
}

- (void)setViewScale:(CGFloat)s
{
  s = fmin(s, MAX_SCALE);
  s = fmax(s, MIN_SCALE);

  if (_viewScale != s)
    {
      [self willChangeValueForKey:@"viewScale"];
      _viewScale = s;
      [self didChangeValueForKey:@"viewScale"];
      [self setNeedsUpdate];
    }
}

- (CGAffineTransform)viewTransform
{
  YuDocument *document = self.controller.document;
  CGSize size = document.documentSize;

  CGFloat ax = size.width * (CGFloat).5;
  CGFloat ay = size.height * (CGFloat).5;
  CGFloat s = _viewScale;

  return CGAffineTransformMake(s, 0, 0, s,
			       s * -ax + _viewCenter.x,
			       s * -ay + _viewCenter.y);
}

- (CGFloat)zoomToFitScale
{
  CGSize view_size = [self bounds].size;
  CGSize doc_size = self.controller.document.documentSize;

  CGFloat sx = view_size.width / doc_size.width;
  CGFloat sy = view_size.height / doc_size.height;

  return fmin(sx, sy);
}

- (CGFloat)zoomToFillScale
{
  CGSize view_size = [self bounds].size;
  CGSize doc_size = self.controller.document.documentSize;

  CGFloat sx = view_size.width / doc_size.width;
  CGFloat sy = view_size.height / doc_size.height;

  return fmax(sx, sy);
}

- (BOOL)wantsUpdateLayer
{
  return YES;
}

- (void)updateLayer
{
  CALayer *layer = [self layer];

  layer.backgroundColor = [[YuColor viewerBackgroundColor] CGColor];

  if (_nodeLayer == nil)
    {
      _nodeLayer = [MgLayer layer];
      _nodeLayer.delegate = [NSApp delegate];
      [layer addSublayer:_nodeLayer];
    }

  if (_rootNode == nil)
    {
      _rootNode = [MgLayerNode node];
      _rootNode.anchor = CGPointZero;
      _nodeLayer.rootNode = _rootNode;
    }

  if (_documentContainer == nil)
    {
      _documentContainer = [MgLayerNode node];
      [_rootNode addContent:_documentContainer];
    }

  if (_overlayNode == nil)
    {
      _overlayNode = [YuViewerOverlayNode node];
      _overlayNode.view = self;
      [_rootNode addContent:_overlayNode];
    }

  YuDocument *document = self.controller.document;
  CGSize size = document.documentSize;
  CGRect bounds = [layer bounds];

  _nodeLayer.frame = bounds;
  _nodeLayer.contentsScale = [[self window] backingScaleFactor];

  _rootNode.bounds = bounds;

  _documentContainer.scale = self.viewScale;
  _documentContainer.position = self.viewCenter;
  _documentContainer.bounds = CGRectMake(0, 0, size.width, size.height);
  _documentContainer.contents = @[document.documentNode];

  [_overlayNode update];

  if (_trackingArea == nil
      || !NSEqualRects(NSRectFromCGRect(bounds), [_trackingArea rect]))
    {
      if (_trackingArea != nil)
	[self removeTrackingArea:_trackingArea];

      _trackingArea = [[NSTrackingArea alloc]
		       initWithRect:NSRectFromCGRect(bounds)
		       options:(NSTrackingMouseEnteredAndExited
				| NSTrackingMouseMoved
				| NSTrackingActiveInKeyWindow)
		       owner:self userInfo:nil];
      [self addTrackingArea:_trackingArea];
    }
}

- (void)setNeedsUpdate
{
  [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
  return NO;
}

- (BOOL)isOpaque
{
  return YES;
}

- (CGPoint)convertPointToDocument:(NSPoint)p
{
  CGAffineTransform m = CGAffineTransformInvert([self viewTransform]);

  /* There's an implicit y-flip between view coordinates and the root
     of the Mg viewer. */

  NSRect bounds = [self bounds];

  m = CGAffineTransformTranslate(m, 0, bounds.size.height);
  m = CGAffineTransformScale(m, 1, -1);

  return CGPointApplyAffineTransform(NSPointToCGPoint(p), m);
}

- (YuTreeNode *)selectedNodeContainingPoint:(CGPoint)p
{
  YuWindowController *controller = self.controller.controller;

  for (YuTreeNode *node in controller.selection)
    {
      YuTreeNode *parent = node.parent;
      CGPoint lp = p;
      if (parent != nil)
	lp = [parent convertPointFromRoot:p];
      if ([node containsPoint:lp])
	return node;
    }

  return nil;
}

- (BOOL)mouseDown:(NSEvent *)e inAdornment:(YuViewerAdornment)adornment
    ofNode:(YuTreeNode *)node
{
  YuWindowController *controller = self.controller.controller;

  NSMutableArray *nodes = [NSMutableArray array];
  NSMutableSet *layers = [NSMutableSet set];
  NSInteger node_idx = -1;

  for (YuTreeNode *tn in controller.selection)
    {
      MgLayerNode *layer = (MgLayerNode *)tn.node;
      if (![layer isKindOfClass:[MgLayerNode class]])
	continue;
      if ([layers containsObject:layer])
	continue;
      [nodes addObject:tn];
      [layers addObject:layer];
      if (tn == node)
	node_idx = [nodes count] - 1;
    }

  if (node_idx < 0)
    return NO;

  NSInteger count = [nodes count];
  if (count == 0)
    return NO;

  struct layer_state
    {
      CGPoint position;
      CGPoint anchor;
      CGRect bounds;
      CGFloat cornerRadius;
      CGFloat scale;
      CGFloat squeeze;
      CGFloat skew;
      double rotation;
    };
  
  struct layer_state old_state[count];
  for (NSInteger i = 0; i < count; i++)
    {
      YuTreeNode *tn = nodes[i];
      MgLayerNode *layer = (MgLayerNode *)tn.node;
      old_state[i].position = layer.position;
      old_state[i].anchor = layer.anchor;
      old_state[i].bounds = layer.bounds;
      old_state[i].cornerRadius = layer.cornerRadius;
      old_state[i].scale = layer.scale;
      old_state[i].squeeze = layer.squeeze;
      old_state[i].skew = layer.skew;
      old_state[i].rotation = layer.rotation;
    }

  struct layer_state new_state[count];
  memcpy(new_state, old_state, count * sizeof(new_state[0]));

  BOOL dragging = NO;

  NSPoint p0 = [self convertPoint:[e locationInWindow] fromView:nil];

  while (1)
    {
      [CATransaction flush];

      e = [[self window] nextEventMatchingMask:DRAG_MASK];
      if ([e type] != NSLeftMouseDragged)
	break;

      NSPoint p1 = [self convertPoint:[e locationInWindow] fromView:nil];

      CGFloat dx = p1.x - p0.x;
      CGFloat dy = p0.y - p1.y;

      if (!dragging && (fabs(dx) > 2 || fabs(dy) > 2))
	dragging = YES;

      if (!dragging)
	continue;

      double arg = 0;

      switch (adornment)
	{
	case YuViewerAdornmentRotate: {
	  CGPoint np0 = [node convertPointFromRoot:
			 [self convertPointToDocument:p0]];
	  CGPoint np1 = [node convertPointFromRoot:
			 [self convertPointToDocument:p1]];
	  CGPoint nc;
	  nc.x = (old_state[node_idx].bounds.origin.x
		  + old_state[node_idx].bounds.size.width
		  * old_state[node_idx].anchor.x);
	  nc.y = (old_state[node_idx].bounds.origin.y
		  + old_state[node_idx].bounds.size.height
		  * old_state[node_idx].anchor.y);

	  double ang0 = atan2(np0.y - nc.y, np0.x - nc.x);
	  double ang1 = atan2(np1.y - nc.y, np1.x - nc.x);
	  arg = ang1 - ang0;
	  break; }

	  /* FIXME: skew is not right. But it'll do for now. */

	case YuViewerAdornmentScale:
	case YuViewerAdornmentSqueeze:
	case YuViewerAdornmentSkew: {
	  CGPoint np0 = [node convertPointFromRoot:
			 [self convertPointToDocument:p0]];
	  CGPoint np1 = [node convertPointFromRoot:
			 [self convertPointToDocument:p1]];
	  CGPoint nc;
	  nc.x = (old_state[node_idx].bounds.origin.x
		  + old_state[node_idx].bounds.size.width
		  * old_state[node_idx].anchor.x);
	  nc.y = (old_state[node_idx].bounds.origin.y
		  + old_state[node_idx].bounds.size.height
		  * old_state[node_idx].anchor.y);
	  if (adornment == YuViewerAdornmentScale)
	    arg = fabs((np1.y - nc.y) / (np0.y - nc.y));
	  else if (adornment == YuViewerAdornmentSqueeze)
	    arg = fabs((np1.x - nc.x) / (np0.x - nc.x));
	  else /* if (adornment == YuViewerAdornmentSkew) */
	    arg = (np1.x - np0.x) / (np0.y - nc.y);
	  break; }

	default:
	  break;
	}

      for (NSInteger i = 0; i < count; i++)
	{
	  YuTreeNode *tn = nodes[i];
	  MgLayerNode *layer = (MgLayerNode *)tn.node;

	  CGPoint np0 = [tn convertPointFromRoot:
			 [self convertPointToDocument:p0]];
	  CGPoint np1 = [tn convertPointFromRoot:
			 [self convertPointToDocument:p1]];

	  CGFloat ndx = np1.x - np0.x;
	  CGFloat ndy = np1.y - np0.y;

	  struct layer_state *ns = &new_state[i];
	  memcpy(ns, &old_state[i], sizeof(*ns));

	  if (adornment >= YuViewerAdornmentResizeTopLeft
	      && adornment <= YuViewerAdornmentResizeRight)
	    {
	      ns->position = [layer convertPointFromParent:ns->position];

	      switch (adornment)
		{
		case YuViewerAdornmentResizeTopLeft:
		case YuViewerAdornmentResizeLeft:
		case YuViewerAdornmentResizeBottomLeft:
		  ns->bounds.size.width -= ndx;
		  ns->position.x += ndx * (1 - ns->anchor.x);
		  break;

		case YuViewerAdornmentResizeTopRight:
		case YuViewerAdornmentResizeRight:
		case YuViewerAdornmentResizeBottomRight:
		  ns->bounds.size.width += ndx;
		  ns->position.x += ndx * ns->anchor.x;
		  break;

		default:
		  break;
		}

	      switch (adornment)
		{
		case YuViewerAdornmentResizeTopLeft:
		case YuViewerAdornmentResizeTop:
		case YuViewerAdornmentResizeTopRight:
		  ns->bounds.size.height -= ndy;
		  ns->position.y += ndy * ns->anchor.y;
		  break;

		case YuViewerAdornmentResizeBottomLeft:
		case YuViewerAdornmentResizeBottom:
		case YuViewerAdornmentResizeBottomRight:
		  ns->bounds.size.height += ndy;
		  ns->position.y += ndy * (1 - ns->anchor.y);
		  break;

		default:
		  break;
		}

	      ns->position = [layer convertPointToParent:ns->position];
	    }
	  else
	    {
	      switch (adornment)
		{
		case YuViewerAdornmentCornerRadius:
		  ns->cornerRadius = fmax(0, ns->cornerRadius + ndx);
		  break;

		case YuViewerAdornmentAnchor:
		  ns->position = [layer convertPointFromParent:ns->position];
		  ns->anchor.x += ndx / ns->bounds.size.width;
		  ns->anchor.y += ndy / ns->bounds.size.height;
		  ns->position.x += ndx;
		  ns->position.y += ndy;
		  ns->position = [layer convertPointToParent:ns->position];
		  break;

		case YuViewerAdornmentRotate:
		  ns->rotation = fmod(ns->rotation - arg, 2*M_PI);
		  break;

		case YuViewerAdornmentScale:
		  ns->scale = fmax(ns->scale * arg, 1e-3);
		  break;

		case YuViewerAdornmentSqueeze:
		  ns->squeeze = fmax(ns->squeeze * arg, 1e-3);
		  break;

		case YuViewerAdornmentSkew:
		  ns->skew = fmin(ns->skew + arg, 1e3);
		  break;

		default:
		  break;
		}
	    }

	  /* FIXME: whatever undo/update machinery YuDocument implements
	     needs to be invoked here. */

	  layer.position = ns->position;
	  layer.anchor = ns->anchor;
	  layer.bounds = ns->bounds;
	  layer.cornerRadius = ns->cornerRadius;
	  layer.scale = ns->scale;
	  layer.squeeze = ns->squeeze;
	  layer.skew = ns->skew;
	  layer.rotation = ns->rotation;
	}
    }

  if (dragging)
    {
      YuDocument *document = controller.document;

      for (NSInteger i = 0; i < count; i++)
	{
	  YuTreeNode *node = nodes[i];
	  MgLayerNode *layer = (MgLayerNode *)node.node;
	  struct layer_state *os = &old_state[i];
	  struct layer_state *ns = &new_state[i];

	  layer.position = os->position;
	  layer.anchor = os->anchor;
	  layer.bounds = os->bounds;
	  layer.cornerRadius = os->cornerRadius;
	  layer.scale = os->scale;
	  layer.squeeze = os->squeeze;
	  layer.skew = os->skew;
	  layer.rotation = os->rotation;

	  [document node:node setValue:BOX(ns->position) forKey:@"position"];
	  [document node:node setValue:BOX(ns->anchor) forKey:@"anchor"];
	  [document node:node setValue:BOX(ns->bounds) forKey:@"bounds"];
	  [document node:node setValue:@(ns->cornerRadius) forKey:@"cornerRadius"];
	  [document node:node setValue:@(ns->scale) forKey:@"scale"];
	  [document node:node setValue:@(ns->squeeze) forKey:@"squeeze"];
	  [document node:node setValue:@(ns->skew) forKey:@"skew"];
	  [document node:node setValue:@(ns->rotation) forKey:@"rotation"];
	}
    }

  return dragging;
}

- (BOOL)dragSelectionWithEvent:(NSEvent *)e
{
  YuWindowController *controller = self.controller.controller;

  NSMutableArray *nodes = [NSMutableArray array];
  NSMutableSet *layers = [NSMutableSet set];

  for (YuTreeNode *node in controller.selection)
    {
      YuTreeNode *ln = node;
      while (ln != nil && ![ln.node isKindOfClass:[MgLayerNode class]])
	ln = ln.parent;
      if (ln == nil)
	continue;
      MgLayerNode *layer = (MgLayerNode *)ln.node;
      if ([layers containsObject:layer])
	continue;
      [nodes addObject:ln];
      [layers addObject:layer];
    }

  NSInteger count = [nodes count];
  if (count == 0)
    return NO;

  CGPoint old_positions[count];
  CGPoint new_positions[count];
  for (NSInteger i = 0; i < count; i++)
    {
      YuTreeNode *node = nodes[i];
      MgLayerNode *layer = (MgLayerNode *)node.node;
      old_positions[i] = layer.position;
      new_positions[i] = old_positions[i];
    }

  NSPoint p0 = [self convertPoint:[e locationInWindow] fromView:nil];

  BOOL dragging = NO;

  while (1)
    {
      [CATransaction flush];

      e = [[self window] nextEventMatchingMask:DRAG_MASK];
      if ([e type] != NSLeftMouseDragged)
	break;

      NSPoint p1 = [self convertPoint:[e locationInWindow] fromView:nil];

      CGFloat dx = p1.x - p0.x;
      CGFloat dy = p0.y - p1.y;

      if (!dragging && (fabs(dx) > 2 || fabs(dy) > 2))
	dragging = YES;

      if (!dragging)
	continue;

      for (NSInteger i = 0; i < count; i++)
	{
	  YuTreeNode *node = nodes[i];
	  MgLayerNode *layer = (MgLayerNode *)node.node;

	  CGPoint p = old_positions[i];
	  p = [node.parent convertPointToRoot:p];
	  p.x += dx;
	  p.y += dy;
	  p = [node.parent convertPointFromRoot:p];

	  /* FIXME: whatever undo/update machinery YuDocument implements
	     needs to be invoked here. */

	  new_positions[i] = p;
	  layer.position = p;
	}
    }

  if (dragging)
    {
      YuDocument *document = controller.document;

      for (NSInteger i = 0; i < count; i++)
	{
	  YuTreeNode *node = nodes[i];
	  MgLayerNode *layer = (MgLayerNode *)node.node;

	  layer.position = old_positions[i];

	  [document node:node
	   setValue:BOX(new_positions[i]) forKey:@"position"];
	}
    }

  return dragging;
}

- (void)modifySelectionForNode:(YuTreeNode *)node withEvent:(NSEvent *)e
{
  YuWindowController *controller = self.controller.controller;

  BOOL extend = ([e modifierFlags] & NSShiftKeyMask) != 0;
  BOOL toggle = ([e modifierFlags] & NSCommandKeyMask) != 0;

  NSMutableArray *selection = [controller.selection mutableCopy];

  if (!extend && !toggle)
    [selection removeAllObjects];

  if (node != nil)
    {
      NSInteger node_idx = [selection indexOfObjectIdenticalTo:node];

      if (node_idx == NSNotFound)
	[selection addObject:node];
      else if (toggle)
	[selection removeObjectAtIndex:node_idx];
    }

  controller.selection = selection;
}

- (void)mouseDown:(NSEvent *)e
{
  YuWindowController *controller = self.controller.controller;

  NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];

  /* Get location relative to the root of the document. */

  CGPoint dp = [self convertPointToDocument:p];

  for (YuTreeNode *node in controller.selection)
    {
      NSInteger a = [_overlayNode hitTest:dp inAdornmentsOfNode:node];
      if (a != NSNotFound)
	{
	  if ([self mouseDown:e inAdornment:a ofNode:node])
	    return;
	  else
	    break;
	}
    }

  BOOL inside = [self selectedNodeContainingPoint:dp] != nil;

  YuTreeNode *node = [controller.tree hitTest:dp];

  BOOL toggle = ([e modifierFlags] & NSCommandKeyMask) != 0;
  BOOL deep = ([e modifierFlags] & NSAlternateKeyMask) != 0;

  if (node != nil && !deep)
    {
      /* Find the closest ancestor of the hit node that's a sibling
	 of something in the selection (if clicking inside the
	 selection and Command isn't held down) or a sibling of an
	 ancestor of something in the selection otherwise. */

      NSMutableSet *set = [NSMutableSet set];

      NSArray *selection = controller.selection;

      if ([selection count] != 0)
	{
	  for (YuTreeNode *tn in controller.selection)
	    {
	      if (inside && !toggle)
		[set addObject:tn];
	      for (YuTreeNode *pn = tn.parent; pn != nil; pn = pn.parent)
		[set addObject:pn];
	    }
	}
      else
	{
	  [set addObject:controller.tree];
	}

      while (node != nil)
	{
	  YuTreeNode *parent = node.parent;
	  if (parent == nil)
	    break;
	  if ([set containsObject:parent])
	    break;
	  node = parent;
	}
    }

  /* If we clicked outside the selection, update the selection state
     immediately to reflect what was clicked (even if that's nothing). */

  if (!inside)
    [self modifySelectionForNode:node withEvent:e];

  /* Then try to drag the (possibly modified) selection. */

  BOOL dragged = [self dragSelectionWithEvent:e];

  /* If no drag happened, and we clicked on something inside the
     selection, update the selection for that node. */

  if (!dragged && inside && node != nil)
    [self modifySelectionForNode:node withEvent:e];
}

- (void)mouseMoved:(NSEvent *)e
{
#if 0
  YuWindowController *controller = self.controller.controller;

  NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];

  /* Get location relative to the root of the document. */

  CGPoint dp = [self convertPointToDocument:p];
#endif
}

- (void)scrollWheel:(NSEvent *)e
{
  CGPoint o = self.viewCenter;
  o.x += [e scrollingDeltaX];
  o.y += [e scrollingDeltaY];
  self.viewCenter = o;
}

- (void)magnifyWithEvent:(NSEvent *)e
{
  CGFloat s = self.viewScale;
  s = s + [e magnification];
  s = fmin(s, MAX_SCALE);
  s = fmax(s, MIN_SCALE);
  self.viewScale = s;
}

@end
