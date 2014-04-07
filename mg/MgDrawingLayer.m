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

#import "MgDrawingLayerInternal.h"

#import "MgDrawingCALayer.h"
#import "MgLayerInternal.h"
#import "MgNodeInternal.h"

@implementation MgDrawingLayer
{
  BOOL _opaque;
  NSInteger _drawingVersion;
  MgLayerRenderState *_rs;
}

- (Class)viewLayerClass
{
  return [MgDrawingCALayer class];
}

+ (BOOL)automaticallyNotifiesObserversOfOpaque
{
  return NO;
}

- (BOOL)isOpaque
{
  return _opaque;
}

- (void)setOpaque:(BOOL)flag
{
  if (_opaque != flag)
    {
      [self willChangeValueForKey:@"opaque"];
      _opaque = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"opaque"];
    }
}

- (NSInteger)drawingVersion
{
  return _drawingVersion;
}

- (void)setNeedsDisplay
{
  _drawingVersion++;
  [self incrementVersion];
}

- (void)drawWithState:(id<MgDrawingState>)obj
{
}

- (void)clipWithState:(id<MgDrawingState>)obj
{
}

- (void)_renderLayerWithState:(MgLayerRenderState *)rs
{
  _rs = rs;

  CGContextSaveGState(rs->ctx);

  [self drawWithState:(id)self];

  CGContextRestoreGState(rs->ctx);

  _rs = NULL;
}

- (void)_renderLayerMaskWithState:(MgLayerRenderState *)rs
{
  _rs = rs;

  float alpha = rs->alpha * self.alpha;

  if (alpha != 1)
    {
      [super _renderLayerMaskWithState:rs];
      return;
    }

  /* Can't save/restore gstate, need clip changes. */

  [self clipWithState:(id)self];

  _rs = NULL;
}

/** MgDrawingState methods. **/

- (CGContextRef)context
{
  return _rs != NULL ? _rs->ctx : NULL;
}

@end
