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

#import "MgPathNode.h"

#import "MgCoderExtensions.h"
#import "MgCoreGraphics.h"
#import "MgDrawableNodeInternal.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgPathNode
{
  id _path;				/* CGPathRef */
  CGPathDrawingMode _drawingMode;
  id _fillColor;			/* CGColorRef */
  id _strokeColor;			/* CGColorRef */
  CGFloat _lineWidth;
  CGFloat _miterLimit;
  CGLineCap _lineCap;
  CGLineJoin _lineJoin;
  CGFloat _lineDashPhase;
  NSArray *_lineDashPattern;
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _drawingMode = kCGPathFill;
  _fillColor = (__bridge id)MgBlackColor();
  _strokeColor = (__bridge id)MgBlackColor();
  _lineWidth = 1;
  _miterLimit = 10;
  _lineCap = kCGLineCapButt;
  _lineJoin = kCGLineJoinMiter;

  return self;
}

+ (BOOL)automaticallyNotifiesObserversOfPath
{
  return NO;
}

- (CGPathRef)path
{
  return (__bridge CGPathRef)_path;
}

- (void)setPath:(CGPathRef)x
{
  if (_path != (__bridge id)x)
    {
      [self willChangeValueForKey:@"path"];
      _path = (__bridge id)x;
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
  return _drawingMode;
}

- (void)setDrawingMode:(CGPathDrawingMode)x
{
  if (_drawingMode != x)
    {
      [self willChangeValueForKey:@"drawingMode"];
      _drawingMode = x;
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
  return (__bridge CGColorRef)_fillColor;
}

- (void)setFillColor:(CGColorRef)x
{
  if (_fillColor != (__bridge id)x)
    {
      [self willChangeValueForKey:@"fillColor"];
      _fillColor = (__bridge id)x;
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
  return (__bridge CGColorRef)_strokeColor;
}

- (void)setStrokeColor:(CGColorRef)x
{
  if (_strokeColor != (__bridge id)x)
    {
      [self willChangeValueForKey:@"strokeColor"];
      _strokeColor = (__bridge id)x;
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
  return _lineWidth;
}

- (void)setLineWidth:(CGFloat)x
{
  if (_lineWidth != x)
    {
      [self willChangeValueForKey:@"lineWidth"];
      _lineWidth = x;
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
  return _miterLimit;
}

- (void)setMiterLimit:(CGFloat)x
{
  if (_miterLimit != x)
    {
      [self willChangeValueForKey:@"miterLimit"];
      _miterLimit = x;
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
  return _lineCap;
}

- (void)setLineCap:(CGLineCap)x
{
  if (_lineCap != x)
    {
      [self willChangeValueForKey:@"lineCap"];
      _lineCap = x;
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
  return _lineJoin;
}

- (void)setLineJoin:(CGLineJoin)x
{
  if (_lineJoin != x)
    {
      [self willChangeValueForKey:@"lineJoin"];
      _lineJoin = x;
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
  return _lineDashPhase;
}

- (void)setLineDashPhase:(CGFloat)x
{
  if (_lineDashPhase != x)
    {
      [self willChangeValueForKey:@"lineDashPhase"];
      _lineDashPhase = x;
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
  return _lineDashPattern != nil ? _lineDashPattern : @[];
}

- (void)setLineDashPattern:(NSArray *)array
{
  if (_lineDashPattern != array && ![_lineDashPattern isEqual:array])
    {
      [self willChangeValueForKey:@"lineDashPattern"];
      _lineDashPattern = [array copy];
      [self incrementVersion];
      [self didChangeValueForKey:@"lineDashPattern"];
    }
}

- (BOOL)containsPoint:(CGPoint)p layerNode:(MgLayerNode *)node
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
      return CGPathContainsPoint(path, NULL, p, false);

    case kCGPathEOFill:
    case kCGPathEOFillStroke:
      return CGPathContainsPoint(path, NULL, p, true);

    default:
      return NO;
    }
}

- (void)_renderWithState:(MgDrawableRenderState *)rs
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
      MgContextSetLineDash(rs->ctx, (__bridge CFArrayRef)self.lineDashPattern,
			   self.lineDashPhase);
      CGContextBeginPath(rs->ctx);
      CGContextAddPath(rs->ctx, self.path);
      CGContextDrawPath(rs->ctx, self.drawingMode);
      break;
    }

  CGContextRestoreGState(rs->ctx);
}

- (void)_renderMaskWithState:(MgDrawableRenderState *)rs
{
  CGPathDrawingMode mode = self.drawingMode;

  if ((mode != kCGPathStroke
       && CGColorGetAlpha(self.fillColor) < 1)
      || (mode != kCGPathFill && mode != kCGPathEOFill
	  && CGColorGetAlpha(self.strokeColor) < 1))
    {
      [super _renderMaskWithState:rs];
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

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgPathNode *copy = [super copyWithZone:zone];

  copy->_path = _path;
  copy->_drawingMode = _drawingMode;
  copy->_fillColor = _fillColor;
  copy->_strokeColor = _strokeColor;
  copy->_lineWidth = _lineWidth;
  copy->_miterLimit = _miterLimit;
  copy->_lineCap = _lineCap;
  copy->_lineJoin = _lineJoin;
  copy->_lineDashPhase = _lineDashPhase;
  copy->_lineDashPattern = _lineDashPattern;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_path != nil)
    [c mg_encodeCGPath:(__bridge CGPathRef)_path forKey:@"path"];

  if (_drawingMode != kCGPathFill)
    [c encodeInt:_drawingMode forKey:@"drawingMode"];

  if (_fillColor != nil)
    [c mg_encodeCGColor:(__bridge CGColorRef)_fillColor forKey:@"fillColor"];

  if (_strokeColor != nil)
    [c mg_encodeCGColor:(__bridge CGColorRef)_strokeColor forKey:@"strokeColor"];

  if (_lineWidth != 1)
    [c encodeDouble:_lineWidth forKey:@"lineWidth"];

  if (_miterLimit != 10)
    [c encodeDouble:_miterLimit forKey:@"miterLimit"];

  if (_lineCap != kCGLineCapButt)
    [c encodeInt:_lineCap forKey:@"lineCap"];

  if (_lineJoin != kCGLineJoinMiter)
    [c encodeInt:_lineJoin forKey:@"lineJoin"];

  if (_lineDashPhase != 0)
    [c encodeDouble:_lineDashPhase forKey:@"lineDashPhase"];

  if (_lineDashPattern != nil)
    [c encodeObject:_lineDashPattern forKey:@"lineDashPattern"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"path"])
    _path = (__bridge id)[c mg_decodeCGPathForKey:@"path"];

  if ([c containsValueForKey:@"drawingMode"])
    _drawingMode = (CGPathDrawingMode)[c decodeIntForKey:@"drawingMode"];
  else
    _drawingMode = kCGPathFill;

  if ([c containsValueForKey:@"fillColor"])
    _fillColor = (__bridge id)[c mg_decodeCGColorForKey:@"fillColor"];

  if ([c containsValueForKey:@"strokeColor"])
    _strokeColor = (__bridge id)[c mg_decodeCGColorForKey:@"strokeColor"];

  if ([c containsValueForKey:@"lineWidth"])
    _lineWidth = [c decodeDoubleForKey:@"lineWidth"];
  else
    _lineWidth = 1;

  if ([c containsValueForKey:@"miterLimit"])
    _miterLimit = [c decodeDoubleForKey:@"miterLimit"];
  else
    _miterLimit = 10;

  if ([c containsValueForKey:@"lineCap"])
    _lineCap = [c decodeDoubleForKey:@"lineCap"];
  else
    _lineCap = kCGLineCapButt;

  if ([c containsValueForKey:@"lineJoin"])
    _lineJoin = [c decodeDoubleForKey:@"lineJoin"];
  else
    _lineJoin = kCGLineJoinMiter;

  if ([c containsValueForKey:@"lineDashPhase"])
    _lineDashPhase = [c decodeDoubleForKey:@"lineDashPhase"];

  if ([c containsValueForKey:@"lineDashPattern"])
    _lineDashPattern = [c decodeObjectOfClass:[NSArray class] forKey:@"lineDashPattern"];

  return self;
}

@end
