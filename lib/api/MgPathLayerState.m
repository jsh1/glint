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

#import "MgPathLayerState.h"

#import "MgCoderExtensions.h"
#import "MgCoreGraphics.h"

#import <Foundation/Foundation.h>

#define SUPERSTATE ((MgPathLayerState *)(self.superstate))

@implementation MgPathLayerState
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

  struct {
    bool path :1;
    bool drawingMode :1;
    bool fillColor :1;
    bool strokeColor :1;
    bool lineWidth :1;
    bool miterLimit :1;
    bool lineCap :1;
    bool lineJoin :1;
    bool lineDashPhase :1;
    bool lineDashPattern :1;
  } _defines;
}

- (void)setDefaults
{
  [super setDefaults];

  self.path = NULL;
  self.drawingMode = kCGPathFill;
  self.fillColor = MgBlackColor();
  self.strokeColor = MgBlackColor();
  self.lineWidth = 1;
  self.miterLimit = 10;
  self.lineCap = kCGLineCapButt;
  self.lineJoin = kCGLineJoinMiter;
  self.lineDashPhase = 0;
  self.lineDashPattern = nil;
}

- (BOOL)hasValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"path"])
    return _defines.path;
  else if ([key isEqualToString:@"drawingMode"])
    return _defines.drawingMode;
  else if ([key isEqualToString:@"fillColor"])
    return _defines.fillColor;
  else if ([key isEqualToString:@"strokeColor"])
    return _defines.strokeColor;
  else if ([key isEqualToString:@"lineWidth"])
    return _defines.lineWidth;
  else if ([key isEqualToString:@"miterLimit"])
    return _defines.miterLimit;
  else if ([key isEqualToString:@"lineCap"])
    return _defines.lineCap;
  else if ([key isEqualToString:@"lineJoin"])
    return _defines.lineJoin;
  else if ([key isEqualToString:@"lineDashPhase"])
    return _defines.lineDashPhase;
  else if ([key isEqualToString:@"lineDashPattern"])
    return _defines.lineDashPattern;
  else
    return [super hasValueForKey:key];
}

- (CGPathRef)path
{
  if (_defines.path)
    return (__bridge CGPathRef)_path;
  else
    return SUPERSTATE.path;
}

- (void)setPath:(CGPathRef)x
{
  _path = (__bridge id)x;
  _defines.path = true;
}

- (CGPathDrawingMode)drawingMode
{
  if (_defines.drawingMode)
    return _drawingMode;
  else
    return SUPERSTATE.drawingMode;
}

- (void)setDrawingMode:(CGPathDrawingMode)x
{
  _drawingMode = x;
  _defines.drawingMode = true;
}

- (CGColorRef)fillColor
{
  if (_defines.fillColor)
    return (__bridge CGColorRef)_fillColor;
  else
    return SUPERSTATE.fillColor;
}

- (void)setFillColor:(CGColorRef)x
{
  _fillColor = (__bridge id)x;
  _defines.fillColor = true;
}

- (CGColorRef)strokeColor
{
  if (_defines.strokeColor)
    return (__bridge CGColorRef)_strokeColor;
  else
    return SUPERSTATE.strokeColor;
}

- (void)setStrokeColor:(CGColorRef)x
{
  _strokeColor = (__bridge id)x;
  _defines.strokeColor = true;
}

- (CGFloat)lineWidth
{
  if (_defines.lineWidth)
    return _lineWidth;
  else
    return SUPERSTATE.lineWidth;
}

- (void)setLineWidth:(CGFloat)x
{
  _lineWidth = x;
  _defines.lineWidth = true;
}

- (CGFloat)miterLimit
{
  if (_defines.miterLimit)
    return _miterLimit;
  else
    return SUPERSTATE.miterLimit;
}

- (void)setMiterLimit:(CGFloat)x
{
  _miterLimit = x;
  _defines.miterLimit = true;
}

- (CGLineJoin)lineJoin
{
  if (_defines.lineJoin)
    return _lineJoin;
  else
    return SUPERSTATE.lineJoin;
}

- (void)setLineJoin:(CGLineJoin)x
{
  _lineJoin = x;
  _defines.lineJoin = true;
}

- (CGLineCap)lineCap
{
  if (_defines.lineCap)
    return _lineCap;
  else
    return SUPERSTATE.lineCap;
}

- (void)setLineCap:(CGLineCap)x
{
  _lineCap = x;
  _defines.lineCap = true;
}

- (CGFloat)lineDashPhase
{
  if (_defines.lineDashPhase)
    return _lineDashPhase;
  else
    return SUPERSTATE.lineDashPhase;
}

- (void)setLineDashPhase:(CGFloat)x
{
  _lineDashPhase = x;
  _defines.lineDashPhase = true;
}

- (NSArray *)lineDashPattern
{
  if (_defines.lineDashPattern)
    return _lineDashPattern;
  else
    return SUPERSTATE.lineDashPattern;
}

- (void)setLineDashPattern:(NSArray *)array
{
  _lineDashPattern = [array copy];
  _defines.lineDashPattern = true;
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgPathLayerState *copy = [super graphCopy:map];

  copy->_path = _path;
  copy->_drawingMode = _drawingMode;
  copy->_fillColor = _fillColor;
  copy->_strokeColor = _strokeColor;
  copy->_lineWidth = _lineWidth;
  copy->_miterLimit = _miterLimit;
  copy->_lineJoin = _lineJoin;
  copy->_lineCap = _lineCap;
  copy->_lineDashPhase = _lineDashPhase;
  copy->_lineDashPattern = _lineDashPattern;
  copy->_defines = _defines;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_defines.path)
    [c mg_encodeCGPath:(__bridge CGPathRef)_path forKey:@"path"];

  if (_defines.drawingMode)
    [c encodeInt:_drawingMode forKey:@"drawingMode"];

  if (_defines.fillColor)
    [c mg_encodeCGColor:(__bridge CGColorRef)_fillColor forKey:@"fillColor"];

  if (_defines.strokeColor)
    [c mg_encodeCGColor:(__bridge CGColorRef)_strokeColor forKey:@"strokeColor"];

  if (_defines.lineWidth)
    [c encodeDouble:_lineWidth forKey:@"lineWidth"];

  if (_defines.miterLimit)
    [c encodeDouble:_miterLimit forKey:@"miterLimit"];

  if (_defines.lineCap)
    [c encodeInt:_lineCap forKey:@"lineCap"];

  if (_defines.lineJoin)
    [c encodeInt:_lineJoin forKey:@"lineJoin"];

  if (_defines.lineDashPhase)
    [c encodeDouble:_lineDashPhase forKey:@"lineDashPhase"];

  if (_defines.lineDashPattern)
    [c encodeObject:_lineDashPattern forKey:@"lineDashPattern"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"path"])
    {
      _path = (__bridge id)[c mg_decodeCGPathForKey:@"path"];
      _defines.path = true;
    }

  if ([c containsValueForKey:@"drawingMode"])
    {
      _drawingMode = (CGPathDrawingMode)[c decodeIntForKey:@"drawingMode"];
      _defines.drawingMode = true;
    }

  if ([c containsValueForKey:@"fillColor"])
    {
      _fillColor = (__bridge id)[c mg_decodeCGColorForKey:@"fillColor"];
      _defines.fillColor = true;
    }

  if ([c containsValueForKey:@"strokeColor"])
    {
      _strokeColor = (__bridge id)[c mg_decodeCGColorForKey:@"strokeColor"];
      _defines.strokeColor = true;
    }

  if ([c containsValueForKey:@"lineWidth"])
    {
      _lineWidth = [c decodeDoubleForKey:@"lineWidth"];
      _defines.lineWidth = true;
    }

  if ([c containsValueForKey:@"miterLimit"])
    {
      _miterLimit = [c decodeDoubleForKey:@"miterLimit"];
      _defines.miterLimit = true;
    }

  if ([c containsValueForKey:@"lineCap"])
    {
      _lineCap = [c decodeDoubleForKey:@"lineCap"];
      _defines.lineCap = true;
    }

  if ([c containsValueForKey:@"lineJoin"])
    {
      _lineJoin = [c decodeDoubleForKey:@"lineJoin"];
      _defines.lineJoin = true;
    }

  if ([c containsValueForKey:@"lineDashPhase"])
    {
      _lineDashPhase = [c decodeDoubleForKey:@"lineDashPhase"];
      _defines.lineDashPhase = true;
    }

  if ([c containsValueForKey:@"lineDashPattern"])
    {
      _lineDashPattern = [c decodeObjectOfClass:[NSArray class] forKey:@"lineDashPattern"];
      _defines.lineDashPattern = true;
    }

  return self;
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
