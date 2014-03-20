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

#import "MgGradientLayerState.h"

#import "MgCoderExtensions.h"

#import <Foundation/Foundation.h>

#define SUPERSTATE ((MgGradientLayerState *)(self.superstate))

@implementation MgGradientLayerState
{
  NSArray *_colors;
  NSArray *_locations;
  BOOL _radial;
  CGPoint _startPoint;
  CGPoint _endPoint;
  CGFloat _startRadius;
  CGFloat _endRadius;
  BOOL _drawsBeforeStart;
  BOOL _drawsAfterEnd;

  struct {
    bool colors :1;
    bool radial :1;
    bool locations :1;
    bool startPoint :1;
    bool endPoint :1;
    bool startRadius :1;
    bool endRadius :1;
    bool drawsBeforeStart :1;
    bool drawsAfterEnd :1;
  } _defines;
}

- (void)setDefaults
{
  [super setDefaults];

  self.colors = @[];
  self.locations = @[];
  self.radial = NO;
  self.startPoint = CGPointZero;
  self.endPoint = CGPointZero;
  self.startRadius = 0;
  self.endRadius = 0;
  self.drawsBeforeStart = NO;
  self.drawsAfterEnd = NO;
}

- (BOOL)hasValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"colors"])
    return _defines.colors;
  else if ([key isEqualToString:@"locations"])
    return _defines.locations;
  else if ([key isEqualToString:@"radial"])
    return _defines.radial;
  else if ([key isEqualToString:@"startPoint"])
    return _defines.startPoint;
  else if ([key isEqualToString:@"endPoint"])
    return _defines.endPoint;
  else if ([key isEqualToString:@"startRadius"])
    return _defines.startRadius;
  else if ([key isEqualToString:@"endRadius"])
    return _defines.endRadius;
  else if ([key isEqualToString:@"drawsBeforeStart"])
    return _defines.drawsBeforeStart;
  else if ([key isEqualToString:@"drawsAfterEnd"])
    return _defines.drawsAfterEnd;
  else
    return [super hasValueForKey:key];
}

- (NSArray *)colors
{
  if (_defines.colors)
    return _colors;
  else
    return SUPERSTATE.colors;
}

- (void)setColors:(NSArray *)array
{
  _colors = [array copy];
  _defines.colors = true;
}

- (NSArray *)locations
{
  if (_defines.locations)
    return _locations;
  else
    return SUPERSTATE.locations;
}

- (void)setLocations:(NSArray *)array
{
  _locations = [array copy];
  _defines.locations = true;
}

- (BOOL)isRadial
{
  if (_defines.radial)
    return _radial;
  else
    return SUPERSTATE.radial;
}

- (void)setRadial:(BOOL)flag
{
  _radial = flag;
  _defines.radial = true;
}

- (CGPoint)startPoint
{
  if (_defines.startPoint)
    return _startPoint;
  else
    return SUPERSTATE.startPoint;
}

- (void)setStartPoint:(CGPoint)p
{
  _startPoint = p;
  _defines.startPoint = true;
}

- (CGPoint)endPoint
{
  if (_defines.endPoint)
    return _endPoint;
  else
    return SUPERSTATE.endPoint;
}

- (void)setEndPoint:(CGPoint)p
{
  _endPoint = p;
  _defines.endPoint = true;
}

- (CGFloat)startRadius
{
  if (_defines.startRadius)
    return _startRadius;
  else
    return SUPERSTATE.startRadius;
}

- (void)setStartRadius:(CGFloat)x
{
  _startRadius = x;
  _defines.startRadius = true;
}

- (CGFloat)endRadius
{
  if (_defines.endRadius)
    return _endRadius;
  else
    return SUPERSTATE.endRadius;
}

- (void)setEndRadius:(CGFloat)x
{
  _endRadius = x;
  _defines.endRadius = true;
}

- (BOOL)drawsBeforeStart
{
  if (_defines.drawsBeforeStart)
    return _drawsBeforeStart;
  else
    return SUPERSTATE.drawsBeforeStart;
}

- (void)setDrawsBeforeStart:(BOOL)flag
{
  _drawsBeforeStart = flag;
  _defines.drawsBeforeStart = true;
}

- (BOOL)drawsAfterEnd
{
  if (_defines.drawsAfterEnd)
    return _drawsAfterEnd;
  else
    return SUPERSTATE.drawsAfterEnd;
}

- (void)setDrawsAfterEnd:(BOOL)flag
{
  _drawsAfterEnd = flag;
  _defines.drawsAfterEnd = true;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgGradientLayerState *copy = [super copyWithZone:zone];

  copy->_colors = _colors;
  copy->_locations = _locations;
  copy->_radial = _radial;
  copy->_startPoint = _startPoint;
  copy->_endPoint = _endPoint;
  copy->_startRadius = _startRadius;
  copy->_endRadius = _endRadius;
  copy->_drawsBeforeStart = _drawsBeforeStart;
  copy->_drawsAfterEnd = _drawsAfterEnd;
  copy->_defines = _defines;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_defines.colors)
    [c encodeObject:_colors forKey:@"colors"];

  if (_defines.locations)
    [c encodeObject:_locations forKey:@"locations"];

  if (_defines.radial)
    [c encodeBool:_radial forKey:@"radial"];

  if (_defines.startPoint)
    [c mg_encodeCGPoint:_startPoint forKey:@"startPoint"];

  if (_defines.endPoint)
    [c mg_encodeCGPoint:_endPoint forKey:@"endPoint"];

  if (_defines.startRadius)
    [c encodeDouble:_startRadius forKey:@"startRadius"];

  if (_defines.endRadius)
    [c encodeDouble:_endRadius forKey:@"endRadius"];

  if (_defines.drawsBeforeStart)
    [c encodeBool:_drawsBeforeStart forKey:@"drawsBeforeStart"];

  if (_defines.drawsAfterEnd)
    [c encodeBool:_drawsAfterEnd forKey:@"drawsAfterEnd"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"colors"])
    {
      _colors = [c decodeObjectOfClass:[NSArray class] forKey:@"colors"];
      _defines.colors = true;
    }

  if ([c containsValueForKey:@"locations"])
    {
      _locations = [c decodeObjectOfClass:[NSArray class] forKey:@"locations"];
      _defines.locations = true;
    }

  if ([c containsValueForKey:@"radial"])
    {
      _radial = [c decodeBoolForKey:@"radial"];
      _defines.radial = true;
    }

  if ([c containsValueForKey:@"startPoint"])
    {
      _startPoint = [c mg_decodeCGPointForKey:@"startPoint"];
      _defines.startPoint = true;
    }

  if ([c containsValueForKey:@"endPoint"])
    {
      _endPoint = [c mg_decodeCGPointForKey:@"endPoint"];
      _defines.endPoint = true;
    }

  if ([c containsValueForKey:@"startRadius"])
    {
      _startRadius = [c decodeDoubleForKey:@"startRadius"];
      _defines.startRadius = true;
    }

  if ([c containsValueForKey:@"endRadius"])
    {
      _endRadius = [c decodeDoubleForKey:@"endRadius"];
      _defines.endRadius = true;
    }

  if ([c containsValueForKey:@"drawsBeforeStart"])
    {
      _drawsBeforeStart = [c decodeBoolForKey:@"drawsBeforeStart"];
      _defines.drawsBeforeStart = true;
    }

  if ([c containsValueForKey:@"drawsAfterEnd"])
    {
      _drawsAfterEnd = [c decodeBoolForKey:@"drawsAfterEnd"];
      _defines.drawsAfterEnd = true;
    }

  return self;
}

@end
