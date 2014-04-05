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

#import "MgPathLayer.h"

#import "MgCoderExtensions.h"
#import "MgCoreGraphics.h"
#import "MgLayerInternal.h"
#import "MgNodeInternal.h"
#import "MgPathLayerState.h"

#import <Foundation/Foundation.h>

#define STATE ((MgPathLayerState *)(self.state))

@implementation MgPathLayer

+ (Class)stateClass
{
  return [MgPathLayerState class];
}

+ (BOOL)automaticallyNotifiesObserversOfPath
{
  return NO;
}

- (CGPathRef)path
{
  return STATE.path;
}

- (void)setPath:(CGPathRef)x
{
  MgPathLayerState *state = STATE;

  if (state.path != x)
    {
      [self willChangeValueForKey:@"path"];
      state.path = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"path"];
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
  MgPathLayerState *state = STATE;

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
  MgPathLayerState *state = STATE;

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
  MgPathLayerState *state = STATE;

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
  MgPathLayerState *state = STATE;

  if (state.lineWidth != x)
    {
      [self willChangeValueForKey:@"lineWidth"];
      state.lineWidth = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"lineWidth"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfMiterLimit
{
  return NO;
}

- (CGFloat)miterLimit
{
  return STATE.miterLimit;
}

- (void)setMiterLimit:(CGFloat)x
{
  MgPathLayerState *state = STATE;

  if (state.miterLimit != x)
    {
      [self willChangeValueForKey:@"miterLimit"];
      state.miterLimit = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"miterLimit"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfLineCap
{
  return NO;
}

- (CGLineCap)lineCap
{
  return STATE.lineCap;
}

- (void)setLineCap:(CGLineCap)x
{
  MgPathLayerState *state = STATE;

  if (state.lineCap != x)
    {
      [self willChangeValueForKey:@"lineCap"];
      state.lineCap = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"lineCap"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfLineJoin
{
  return NO;
}

- (CGLineJoin)lineJoin
{
  return STATE.lineJoin;
}

- (void)setLineJoin:(CGLineJoin)x
{
  MgPathLayerState *state = STATE;

  if (state.lineJoin != x)
    {
      [self willChangeValueForKey:@"lineJoin"];
      state.lineJoin = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"lineJoin"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfLineDashPhase
{
  return NO;
}

- (CGFloat)lineDashPhase
{
  return STATE.lineDashPhase;
}

- (void)setLineDashPhase:(CGFloat)x
{
  MgPathLayerState *state = STATE;

  if (state.lineDashPhase != x)
    {
      [self willChangeValueForKey:@"lineDashPhase"];
      state.lineDashPhase = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"lineDashPhase"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfLineDashPattern
{
  return NO;
}

- (NSArray *)lineDashPattern
{
  return STATE.lineDashPattern;
}

- (void)setLineDashPattern:(NSArray *)array
{
  MgPathLayerState *state = STATE;

  if (![state.lineDashPattern isEqual:array])
    {
      [self willChangeValueForKey:@"lineDashPattern"];
      state.lineDashPattern = array;
      [self incrementVersion];
      [self didChangeValueForKey:@"lineDashPattern"];
    }
}

- (BOOL)contentContainsPoint:(CGPoint)lp
{
  CGPathRef path = self.path;
  if (path == NULL)
    return NO;

  CGPathDrawingMode mode = self.drawingMode;

  switch (mode)
    {
    case kCGPathFill:
    case kCGPathFillStroke:
    case kCGPathStroke:			/* FIXME: incorrect */
      return CGPathContainsPoint(path, NULL, lp, false);

    case kCGPathEOFill:
    case kCGPathEOFillStroke:
      return CGPathContainsPoint(path, NULL, lp, true);

    default:
      return NO;
    }
}

- (void)_renderLayerWithState:(MgLayerRenderState *)rs
{
  CGPathRef path = self.path;
  if (path == NULL)
    return;

  CGContextSaveGState(rs->ctx);

  switch (self.drawingMode)
    {
    case kCGPathFill:
    case kCGPathEOFill:
      CGContextSetFillColorWithColor(rs->ctx, self.fillColor);
      CGContextBeginPath(rs->ctx);
      CGContextAddPath(rs->ctx, self.path);
      CGContextFillPath(rs->ctx);
      break;

    default:
      CGContextSetFillColorWithColor(rs->ctx, self.fillColor);
      CGContextSetStrokeColorWithColor(rs->ctx, self.strokeColor);
      CGContextSetLineWidth(rs->ctx, self.lineWidth);
      CGContextSetMiterLimit(rs->ctx, self.miterLimit);
      CGContextSetLineJoin(rs->ctx, self.lineJoin);
      CGContextSetLineCap(rs->ctx, self.lineCap);
      MgContextSetLineDash(rs->ctx, self.lineDashPattern, self.lineDashPhase);
      CGContextBeginPath(rs->ctx);
      CGContextAddPath(rs->ctx, self.path);
      CGContextDrawPath(rs->ctx, self.drawingMode);
      break;
    }

  CGContextRestoreGState(rs->ctx);
}

- (void)_renderLayerMaskWithState:(MgLayerRenderState *)rs
{
  CGPathDrawingMode mode = self.drawingMode;

  if (rs->alpha != 1
      || (mode != kCGPathStroke
	  && CGColorGetAlpha(self.fillColor) < 1)
      || (mode != kCGPathFill && mode != kCGPathEOFill
	  && CGColorGetAlpha(self.strokeColor) < 1))
    {
      [super _renderLayerMaskWithState:rs];
      return;
    }

  CGPathRef p = self.path;

  CGPathRef sp = NULL;
  if (mode != kCGPathFill && mode != kCGPathEOFill)
    {
      sp = CGPathCreateCopyByStrokingPath(p, NULL, self.lineWidth,
				self.lineCap, self.lineJoin, self.miterLimit);
    }

  CGContextBeginPath(rs->ctx);
  CGContextAddPath(rs->ctx, p);
  if (sp != NULL)
    CGContextAddPath(rs->ctx, sp);
  CGContextClip(rs->ctx);

  CGPathRelease(sp);
}

/** NSKeyValueCoding methods. **/

- (id)valueForUndefinedKey:(NSString *)key
{
  if ([key isEqualToString:@"path"])
    return (__bridge id)[self path];
  else if ([key isEqualToString:@"fillColor"])
    return (__bridge id)[self fillColor];
  else if ([key isEqualToString:@"strokeColor"])
    return (__bridge id)[self strokeColor];
  else
    return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
  if ([key isEqualToString:@"path"])
    [self setPath:(__bridge CGPathRef)value];
  else if ([key isEqualToString:@"fillColor"])
    [self setFillColor:(__bridge CGColorRef)value];
  else if ([key isEqualToString:@"strokeColor"])
    [self setStrokeColor:(__bridge CGColorRef)value];
  else
    [super setValue:value forUndefinedKey:key];
}

@end
