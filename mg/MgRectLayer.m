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

#import "MgRectLayer.h"

#import "MgCoderExtensions.h"
#import "MgCoreGraphics.h"
#import "MgLayerInternal.h"
#import "MgNodeInternal.h"
#import "MgRectLayerState.h"

#import <Foundation/Foundation.h>

#define STATE ((MgRectLayerState *)(self.state))

@implementation MgRectLayer

+ (Class)stateClass
{
  return [MgRectLayerState class];
}

+ (BOOL)automaticallyNotifiesObserversOfCornerRadius
{
  return NO;
}

- (CGFloat)cornerRadius
{
  return STATE.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)x
{
  MgRectLayerState *state = STATE;

  if (state.cornerRadius != x)
    {
      [self willChangeValueForKey:@"cornerRadius"];
      state.cornerRadius = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"cornerRadius"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfDrawingMode
{
  return NO;
}

- (CGPathDrawingMode)drawingMode
{
  return STATE.drawingMode;
}

- (void)setDrawingMode:(CGPathDrawingMode)x
{
  MgRectLayerState *state = STATE;

  if (state.drawingMode != x)
    {
      [self willChangeValueForKey:@"drawingMode"];
      state.drawingMode = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"drawingMode"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfFillColor
{
  return NO;
}

- (CGColorRef)fillColor
{
  return STATE.fillColor;
}

- (void)setFillColor:(CGColorRef)x
{
  MgRectLayerState *state = STATE;

  if (state.fillColor != x)
    {
      [self willChangeValueForKey:@"fillColor"];
      state.fillColor = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"fillColor"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfStrokeColor
{
  return NO;
}

- (CGColorRef)strokeColor
{
  return STATE.strokeColor;
}

- (void)setStrokeColor:(CGColorRef)x
{
  MgRectLayerState *state = STATE;

  if (state.strokeColor != x)
    {
      [self willChangeValueForKey:@"strokeColor"];
      state.strokeColor = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"strokeColor"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfLineWidth
{
  return NO;
}

- (CGFloat)lineWidth
{
  return STATE.lineWidth;
}

- (void)setLineWidth:(CGFloat)x
{
  MgRectLayerState *state = STATE;

  if (state.lineWidth != x)
    {
      [self willChangeValueForKey:@"lineWidth"];
      state.lineWidth = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"lineWidth"];
    }
}

- (BOOL)containsPoint:(CGPoint)p layerNode:(MgLayer *)node
{
  /* FIXME: rounded corners. */

  return node != nil && CGRectContainsPoint(node.bounds, p);
}

- (void)_renderLayerWithState:(MgLayerRenderState *)rs
{
  CGContextSaveGState(rs->ctx);

  CGFloat radius = self.cornerRadius;
  CGPathDrawingMode mode = self.drawingMode;

  if (radius == 0 && (mode == kCGPathFill || mode == kCGPathEOFill))
    {
      CGContextSetFillColorWithColor(rs->ctx, self.fillColor);
      CGContextFillRect(rs->ctx, self.bounds);
    }
  else if (radius == 0 && mode == kCGPathStroke)
    {
      CGContextSetStrokeColorWithColor(rs->ctx, self.strokeColor);
      CGContextStrokeRectWithWidth(rs->ctx, self.bounds, self.lineWidth);
    }
  else
    {
      CGContextSetFillColorWithColor(rs->ctx, self.fillColor);
      CGContextSetStrokeColorWithColor(rs->ctx, self.strokeColor);
      CGContextSetLineWidth(rs->ctx, self.lineWidth);

      CGContextBeginPath(rs->ctx);
      if (radius == 0)
	CGContextAddRect(rs->ctx, self.bounds);
      else
	{
	  CGPathRef p = MgPathCreateWithRoundRect(self.bounds, radius);
	  CGContextAddPath(rs->ctx, p);
	  CGPathRelease(p);
	}

      CGContextDrawPath(rs->ctx, self.drawingMode);
    }

  CGContextRestoreGState(rs->ctx);
}

- (void)_renderLayerMaskWithState:(MgLayerRenderState *)rs
{
  CGPathDrawingMode mode = self.drawingMode;

  float alpha = rs->alpha * self.alpha;

  if (alpha != 1
      || (mode != kCGPathStroke
	  && CGColorGetAlpha(self.fillColor) < 1)
      || (mode != kCGPathFill && mode != kCGPathEOFill
	  && CGColorGetAlpha(self.strokeColor) < 1))
    {
      [super _renderLayerMaskWithState:rs];
      return;
    }

  CGFloat radius = self.cornerRadius;

  if (radius == 0 && (mode == kCGPathFill || mode == kCGPathEOFill))
    {
      CGContextClipToRect(rs->ctx, self.bounds);
      return;
    }

  CGPathRef p = MgPathCreateWithRoundRect(self.bounds, radius);
  CGPathRef sp = NULL;
  if (mode != kCGPathFill && mode != kCGPathEOFill)
    {
      sp = CGPathCreateCopyByStrokingPath(p, NULL, self.lineWidth,
					kCGLineCapButt, kCGLineJoinMiter, 10);
    }

  CGContextBeginPath(rs->ctx);
  CGContextAddPath(rs->ctx, p);
  if (sp != NULL)
    CGContextAddPath(rs->ctx, sp);
  CGContextClip(rs->ctx);

  CGPathRelease(sp);
  CGPathRelease(p);
}

/** NSKeyValueCoding methods. **/

- (id)valueForUndefinedKey:(NSString *)key
{
  if ([key isEqualToString:@"fillColor"])
    return (__bridge id)[self fillColor];
  else if ([key isEqualToString:@"strokeColor"])
    return (__bridge id)[self strokeColor];
  else
    return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
  if ([key isEqualToString:@"fillColor"])
    [self setFillColor:(__bridge CGColorRef)value];
  else if ([key isEqualToString:@"strokeColor"])
    [self setStrokeColor:(__bridge CGColorRef)value];
  else
    [super setValue:value forUndefinedKey:key];
}

@end
