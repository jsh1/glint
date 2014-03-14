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

#import "GtViewerView.h"

#import "GtColor.h"
#import "GtDocument.h"
#import "GtTreeNode.h"
#import "GtViewerOverlayLayer.h"
#import "GtViewerViewController.h"
#import "GtWindowController.h"

#import "MgCoreAnimationLayer.h"
#import "MgMacros.h"

#define MIN_SCALE (1. / 32)
#define MAX_SCALE 32

#define DRAG_MASK (NSLeftMouseDownMask | NSLeftMouseUpMask \
  | NSRightMouseDownMask | NSRightMouseUpMask | NSMouseMovedMask \
  | NSLeftMouseDraggedMask | NSRightMouseDraggedMask \
  | NSOtherMouseDownMask | NSOtherMouseUpMask | NSOtherMouseDraggedMask)

@implementation GtViewerView
{
  MgCoreAnimationLayer *_nodeLayer;
  MgGroupLayer *_rootLayer;
  MgGroupLayer *_documentContainer;
  GtViewerOverlayLayer *_overlayLayer;
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
  GtDocument *document = self.controller.document;
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

  layer.backgroundColor = [[GtColor viewerBackgroundColor] CGColor];

  if (_nodeLayer == nil)
    {
      _nodeLayer = [MgCoreAnimationLayer layer];
      _nodeLayer.delegate = [NSApp delegate];
      [layer addSublayer:_nodeLayer];
    }

  if (_rootLayer == nil)
    {
      _rootLayer = [MgGroupLayer node];
      _rootLayer.anchor = CGPointZero;
      _nodeLayer.layer = _rootLayer;
    }

  if (_documentContainer == nil)
    {
      _documentContainer = [MgGroupLayer node];
      [_rootLayer addSublayer:_documentContainer];
    }

  if (_overlayLayer == nil)
    {
      _overlayLayer = [GtViewerOverlayLayer node];
      _overlayLayer.view = self;
      _overlayLayer.anchor = CGPointZero;
      [_rootLayer addSublayer:_overlayLayer];
    }

  GtDocument *document = self.controller.document;
  CGSize size = document.documentSize;
  CGRect bounds = [layer bounds];
  CGFloat scale = self.viewScale;
  CGPoint center = self.viewCenter;

  _nodeLayer.frame = bounds;
  _nodeLayer.contentsScale = [[self window] backingScaleFactor];

  _rootLayer.bounds = bounds;

  _documentContainer.scale = scale;
  _documentContainer.position = center;
  _documentContainer.bounds = CGRectMake(0, 0, size.width, size.height);
  _documentContainer.sublayers = @[document.documentNode];

  _overlayLayer.bounds = bounds;

  [_overlayLayer update];

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

- (GtTreeNode *)selectedNodeContainingPoint:(CGPoint)p
{
  GtWindowController *controller = self.controller.windowController;

  for (GtTreeNode *node in controller.selection)
    {
      GtTreeNode *parent = node.parent;
      CGPoint lp = p;
      if (parent != nil)
	lp = [parent convertPointFromRoot:p];
      if ([node containsPoint:lp])
	return node;
    }

  return nil;
}

- (BOOL)mouseDown:(NSEvent *)e inAdornment:(NSInteger)adornment
    ofNode:(GtTreeNode *)node
{
  GtWindowController *controller = self.controller.windowController;

  NSMutableArray *nodes = [NSMutableArray array];
  NSMutableSet *layers = [NSMutableSet set];
  NSInteger node_idx = -1;

  for (GtTreeNode *tn in controller.selection)
    {
      GtTreeNode *pn = tn;
      while (pn != nil && ![pn.node isKindOfClass:[MgLayer class]])
	pn = pn.parent;
      if (pn == nil)
	continue;
      MgLayer *layer = (MgLayer *)pn.node;
      if ([layers containsObject:layer])
	continue;
      if (node == nil && pn.parent == nil)
	continue;
      [nodes addObject:pn];
      [layers addObject:layer];
      if (pn == node)
	node_idx = [nodes count] - 1;
    }

  if (node != nil && node_idx < 0)
    return NO;

  NSInteger count = [nodes count];
  if (count == 0)
    return NO;

  struct layer_state
    {
      bool is_rect;
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
      GtTreeNode *tn = nodes[i];
      MgLayer *layer = (MgLayer *)tn.node;
      old_state[i].is_rect = [layer isKindOfClass:[MgRectLayer class]];
      old_state[i].position = layer.position;
      old_state[i].anchor = layer.anchor;
      old_state[i].bounds = layer.bounds;
      old_state[i].cornerRadius = (old_state[i].is_rect
				   ? ((MgRectLayer *)layer).cornerRadius : 0);
      old_state[i].scale = layer.scale;
      old_state[i].squeeze = layer.squeeze;
      old_state[i].skew = layer.skew;
      old_state[i].rotation = layer.rotation;
    }

  struct layer_state new_state[count];
  memcpy(new_state, old_state, count * sizeof(new_state[0]));

  BOOL dragging = NO;

  NSPoint p0 = [self convertPoint:[e locationInWindow] fromView:nil];
  p0.x = round(p0.x);
  p0.y = round(p0.y);

  while (1)
    {
      [CATransaction flush];

      e = [[self window] nextEventMatchingMask:DRAG_MASK];
      if ([e type] != NSLeftMouseDragged)
	break;

      NSPoint p1 = [self convertPoint:[e locationInWindow] fromView:nil];

      /* NSEvent loves to give us fractional window locations. wtf? */

      p1.x = round(p1.x);
      p1.y = round(p1.y);

      CGFloat dx = p1.x - p0.x;
      CGFloat dy = p0.y - p1.y;

      if (!dragging && (fabs(dx) > 2 || fabs(dy) > 2))
	dragging = YES;

      if (!dragging)
	continue;

      double arg = 0;

      switch (adornment)
	{
	case GtViewerAdornmentRotate: {
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

	case GtViewerAdornmentScale:
	case GtViewerAdornmentSqueeze:
	case GtViewerAdornmentSkew: {
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
	  if (adornment == GtViewerAdornmentScale)
	    arg = fabs((np1.y - nc.y) / (np0.y - nc.y));
	  else if (adornment == GtViewerAdornmentSqueeze)
	    arg = fabs((np1.x - nc.x) / (np0.x - nc.x));
	  else /* if (adornment == GtViewerAdornmentSkew) */
	    arg = (np1.x - np0.x) / (np0.y - nc.y);
	  break; }

	default:
	  break;
	}

      for (NSInteger i = 0; i < count; i++)
	{
	  GtTreeNode *tn = nodes[i];
	  MgLayer *layer = (MgLayer *)tn.node;

	  CGPoint np0 = [tn convertPointFromRoot:
			 [self convertPointToDocument:p0]];
	  CGPoint np1 = [tn convertPointFromRoot:
			 [self convertPointToDocument:p1]];

	  CGFloat ndx = np1.x - np0.x;
	  CGFloat ndy = np1.y - np0.y;

	  struct layer_state *ns = &new_state[i];
	  memcpy(ns, &old_state[i], sizeof(*ns));

	  if (adornment >= GtViewerAdornmentResizeTopLeft
	      && adornment <= GtViewerAdornmentResizeRight)
	    {
	      ns->position = [layer convertPointFromParent:ns->position];

	      switch (adornment)
		{
		case GtViewerAdornmentResizeTopLeft:
		case GtViewerAdornmentResizeLeft:
		case GtViewerAdornmentResizeBottomLeft:
		  ns->bounds.size.width -= ndx;
		  ns->position.x += ndx * (1 - ns->anchor.x);
		  break;

		case GtViewerAdornmentResizeTopRight:
		case GtViewerAdornmentResizeRight:
		case GtViewerAdornmentResizeBottomRight:
		  ns->bounds.size.width += ndx;
		  ns->position.x += ndx * ns->anchor.x;
		  break;

		default:
		  break;
		}

	      switch (adornment)
		{
		case GtViewerAdornmentResizeTopLeft:
		case GtViewerAdornmentResizeTop:
		case GtViewerAdornmentResizeTopRight:
		  ns->bounds.size.height -= ndy;
		  ns->position.y += ndy * ns->anchor.y;
		  break;

		case GtViewerAdornmentResizeBottomLeft:
		case GtViewerAdornmentResizeBottom:
		case GtViewerAdornmentResizeBottomRight:
		  ns->bounds.size.height += ndy;
		  ns->position.y += ndy * (1 - ns->anchor.y);
		  break;

		default:
		  break;
		}

	      ns->position = [layer convertPointToParent:ns->position];
	    }
	  else if (adornment < GtViewerAdornmentCount)
	    {
	      switch (adornment)
		{
		case GtViewerAdornmentCornerRadius:
		  ns->cornerRadius = fmax(0, ns->cornerRadius + ndx);
		  break;

		case GtViewerAdornmentAnchor:
		  ns->position = [layer convertPointFromParent:ns->position];
		  ns->anchor.x += ndx / ns->bounds.size.width;
		  ns->anchor.y += ndy / ns->bounds.size.height;
		  ns->position.x += ndx;
		  ns->position.y += ndy;
		  ns->position = [layer convertPointToParent:ns->position];
		  break;

		case GtViewerAdornmentRotate:
		  ns->rotation = fmod(ns->rotation - arg, 2*M_PI);
		  break;

		case GtViewerAdornmentScale:
		  ns->scale = fmax(ns->scale * arg, 1e-3);
		  break;

		case GtViewerAdornmentSqueeze:
		  ns->squeeze = fmax(ns->squeeze * arg, 1e-3);
		  break;

		case GtViewerAdornmentSkew:
		  ns->skew = fmin(ns->skew + arg, 1e3);
		  break;

		default:
		  break;
		}
	    }
	  else
	    {
	      /* move. */

	      CGPoint p = [tn.parent convertPointToRoot:ns->position];
	      p.x += dx;
	      p.y += dy;
	      ns->position = [tn.parent convertPointFromRoot:p];
	    }

	  layer.position = ns->position;
	  layer.anchor = ns->anchor;
	  layer.bounds = ns->bounds;
	  if (ns->is_rect)
	    ((MgRectLayer *)layer).cornerRadius = ns->cornerRadius;
	  layer.scale = ns->scale;
	  layer.squeeze = ns->squeeze;
	  layer.skew = ns->skew;
	  layer.rotation = ns->rotation;
	}
    }

  if (dragging)
    {
      GtDocument *document = controller.document;

      for (NSInteger i = 0; i < count; i++)
	{
	  GtTreeNode *node = nodes[i];
	  MgLayer *layer = (MgLayer *)node.node;
	  struct layer_state *os = &old_state[i];
	  struct layer_state *ns = &new_state[i];

	  layer.position = os->position;
	  layer.anchor = os->anchor;
	  layer.bounds = os->bounds;
	  if (os->is_rect)
	    ((MgRectLayer *)layer).cornerRadius = os->cornerRadius;
	  layer.scale = os->scale;
	  layer.squeeze = os->squeeze;
	  layer.skew = os->skew;
	  layer.rotation = os->rotation;

	  [document node:node setValue:BOX(ns->position) forKey:@"position"];
	  [document node:node setValue:BOX(ns->anchor) forKey:@"anchor"];
	  [document node:node setValue:BOX(ns->bounds) forKey:@"bounds"];
	  if (ns->is_rect)
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
  return [self mouseDown:e inAdornment:GtViewerAdornmentCount ofNode:nil];
}

- (void)modifySelectionForNode:(GtTreeNode *)node withEvent:(NSEvent *)e
{
  GtWindowController *controller = self.controller.windowController;

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
  GtWindowController *controller = self.controller.windowController;

  NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];

  /* Get location relative to the root of the document. */

  CGPoint dp = [self convertPointToDocument:p];

  for (GtTreeNode *node in controller.selection)
    {
      NSInteger a = [_overlayLayer hitTest:dp inAdornmentsOfNode:node];
      if (a != NSNotFound)
	{
	  if ([self mouseDown:e inAdornment:a ofNode:node])
	    return;
	  else
	    break;
	}
    }

  BOOL inside = [self selectedNodeContainingPoint:dp] != nil;

  GtTreeNode *node = [controller.tree hitTest:dp];

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
	  for (GtTreeNode *tn in controller.selection)
	    {
	      if (inside && !toggle)
		[set addObject:tn];
	      for (GtTreeNode *pn = tn.parent; pn != nil; pn = pn.parent)
		[set addObject:pn];
	    }
	}
      else
	{
	  [set addObject:controller.tree];
	}

      while (node != nil)
	{
	  GtTreeNode *parent = node.parent;
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
  GtWindowController *controller = self.controller.controller;

  NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];

  /* Get location relative to the root of the document. */

  CGPoint dp = [self convertPointToDocument:p];
#endif
}

- (void)scrollWheel:(NSEvent *)e
{
  CGPoint o = self.viewCenter;
  o.x += round([e scrollingDeltaX]);
  o.y += round([e scrollingDeltaY]);
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

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
  NSPasteboard *pboard = [sender draggingPasteboard];

  if ([self.controller.document
       canAddObjectsFromPasteboard:pboard asImages:NO])
    return NSDragOperationCopy;
  else
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
  NSPasteboard *pboard = [sender draggingPasteboard];

  NSPoint p = [self convertPoint:[sender draggingLocation] fromView:nil];
  CGPoint dp = [self convertPointToDocument:p];

  return [self.controller.document addObjectsFromPasteboard:pboard
	  asImages:NO atDocumentPoint:dp];
}

@end
