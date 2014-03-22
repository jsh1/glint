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

#import "MgRectLayerState.h"

#import "MgCoderExtensions.h"
#import "MgCoreGraphics.h"

#import <Foundation/Foundation.h>

#define SUPERSTATE ((MgRectLayerState *)(self.superstate))

@implementation MgRectLayerState
{
  CGFloat _cornerRadius;
  CGPathDrawingMode _drawingMode;
  id _fillColor;			/* CGColorRef */
  id _strokeColor;			/* CGColorref */
  CGFloat _lineWidth;

  struct {
    bool cornerRadius :1;
    bool drawingMode :1;
    bool fillColor :1;
    bool strokeColor :1;
    bool lineWidth :1;
  } _defines;
}

- (void)setDefaults
{
  [super setDefaults];

  self.cornerRadius = 0;
  self.drawingMode = kCGPathFill;
  self.fillColor = MgBlackColor();
  self.strokeColor = MgBlackColor();
  self.lineWidth = 1;
}

- (BOOL)hasValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"cornerRadius"])
    return _defines.cornerRadius;
  else if ([key isEqualToString:@"drawingMode"])
    return _defines.drawingMode;
  else if ([key isEqualToString:@"fillColor"])
    return _defines.fillColor;
  else if ([key isEqualToString:@"strokeColor"])
    return _defines.strokeColor;
  else if ([key isEqualToString:@"lineWidth"])
    return _defines.lineWidth;
  else
    return [super hasValueForKey:key];
}

- (CGFloat)cornerRadius
{
  if (_defines.cornerRadius)
    return _cornerRadius;
  else
    return SUPERSTATE.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)x
{
  _cornerRadius = x;
  _defines.cornerRadius = true;
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

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgRectLayerState *copy = [super copyWithZone:zone];

  copy->_cornerRadius = _cornerRadius;
  copy->_drawingMode = _drawingMode;
  copy->_fillColor = _fillColor;
  copy->_strokeColor = _strokeColor;
  copy->_lineWidth = _lineWidth;
  copy->_defines = _defines;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_defines.cornerRadius)
    [c encodeDouble:_cornerRadius forKey:@"cornerRadius"];

  if (_defines.drawingMode)
    [c encodeInt:_drawingMode forKey:@"drawingMode"];

  if (_defines.fillColor)
    [c mg_encodeCGColor:(__bridge CGColorRef)_fillColor forKey:@"fillColor"];

  if (_defines.strokeColor)
    [c mg_encodeCGColor:(__bridge CGColorRef)_strokeColor forKey:@"strokeColor"];

  if (_defines.lineWidth)
    [c encodeDouble:_lineWidth forKey:@"lineWidth"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"cornerRadius"])
    {
      _cornerRadius = [c decodeDoubleForKey:@"cornerRadius"];
      _defines.cornerRadius = true;
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

  return self;
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