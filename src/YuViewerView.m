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

#import "YuDocument.h"
#import "YuViewerViewController.h"

#import "MgLayer.h"

#define MIN_SCALE (1. / 32)
#define MAX_SCALE 32

@implementation YuViewerView
{
  MgLayer *_nodeLayer;
  CGPoint _viewCenter;
  CGFloat _viewScale;
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

  layer.backgroundColor = [[NSColor darkGrayColor] CGColor];

  if (_nodeLayer == nil)
    {
      _nodeLayer = [MgLayer layer];
      _nodeLayer.delegate = [NSApp delegate];
      [layer addSublayer:_nodeLayer];
    }

  YuDocument *document = self.controller.document;

  _nodeLayer.rootNode = document.rootNode;

  CGFloat scale = self.viewScale;
  _nodeLayer.affineTransform = CGAffineTransformMakeScale(scale, scale);

  CGSize size = document.documentSize;
  _nodeLayer.bounds = CGRectMake(0, 0, size.width, size.height);

  _nodeLayer.position = self.viewCenter;
}

- (void)setNeedsUpdate
{
  [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
  return YES;
}

- (void)mouseDown:(NSEvent *)e
{
}

- (void)mouseDragged:(NSEvent *)e
{
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
