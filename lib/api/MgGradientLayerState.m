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
#import "MgCoreGraphics.h"
#import "MgNodeTransition.h"

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

  _colors = @[];
  _locations = @[];
  _radial = NO;
  _startPoint = CGPointZero;
  _endPoint = CGPointZero;
  _startRadius = 0;
  _endRadius = 0;
  _drawsBeforeStart = NO;
  _drawsAfterEnd = NO;

  _defines.colors = true;
  _defines.locations = true;
  _defines.radial = true;
  _defines.startPoint = true;
  _defines.endPoint = true;
  _defines.startRadius = true;
  _defines.endRadius = true;
  _defines.drawsBeforeStart = true;
  _defines.drawsAfterEnd = true;
}

- (BOOL)definesValueForKey:(NSString *)key
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
    return [super definesValueForKey:key];
}

- (void)setDefinesValue:(BOOL)flag forKey:(NSString *)key
{
  if ([key isEqualToString:@"colors"])
    _defines.colors = flag;
  else if ([key isEqualToString:@"locations"])
    _defines.locations = flag;
  else if ([key isEqualToString:@"radial"])
    _defines.radial = flag;
  else if ([key isEqualToString:@"startPoint"])
    _defines.startPoint = flag;
  else if ([key isEqualToString:@"endPoint"])
    _defines.endPoint = flag;
  else if ([key isEqualToString:@"startRadius"])
    _defines.startRadius = flag;
  else if ([key isEqualToString:@"endRadius"])
    _defines.endRadius = flag;
  else if ([key isEqualToString:@"drawsBeforeStart"])
    _defines.drawsBeforeStart = flag;
  else if ([key isEqualToString:@"drawsAfterEnd"])
    _defines.drawsAfterEnd = flag;
  else
    [super setDefinesValue:flag forKey:key];
}

- (void)applyTransition:(MgTransition *)trans atTime:(double)t
    to:(MgNodeState *)to_
{
  MgGradientLayerState *to = (MgGradientLayerState *)to_;
  double t_;

  [super applyTransition:trans atTime:t to:to];

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"colors"] : t;
  _colors = MgColorArrayMix(self.colors, to.colors, t_);
  _defines.colors = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"locations"] : t;
  _locations = MgFloatArrayMix(self.locations, to.locations, t_);
  _defines.locations = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"radial"] : t;
  _radial = t_ < .5 ? self.radial : to.radial;
  _defines.radial = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"startPoint"] : t;
  _startPoint = MgPointMix(self.startPoint, to.startPoint, t_);
  _defines.startPoint = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"endPoint"] : t;
  _endPoint = MgPointMix(self.endPoint, to.endPoint, t_);
  _defines.endPoint = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"startRadius"] : t;
  _startRadius = MgFloatMix(self.startRadius, to.startRadius, t_);
  _defines.startRadius = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"endRadius"] : t;
  _endRadius = MgFloatMix(self.endRadius, to.endRadius, t_);
  _defines.endRadius = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"drawsBeforeStart"] : t;
  _drawsBeforeStart = MgBoolMix(self.drawsBeforeStart, to.drawsBeforeStart, t_);
  _defines.drawsBeforeStart = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"drawsAfterEnd"] : t;
  _drawsAfterEnd = MgBoolMix(self.drawsAfterEnd, to.drawsAfterEnd, t_);
  _defines.drawsAfterEnd = true;
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
  if (_defines.colors)
    _colors = [array copy];
  else
    SUPERSTATE.colors = array;
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
  if (_defines.locations)
    _locations = [array copy];
  else
    SUPERSTATE.locations = array;
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
  if (_defines.radial)
    _radial = flag;
  else
    SUPERSTATE.radial = flag;
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
  if (_defines.startPoint)
    _startPoint = p;
  else
    SUPERSTATE.startPoint = p;
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
  if (_defines.endPoint)
    _endPoint = p;
  else
    SUPERSTATE.endPoint = p;
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
  if (_defines.startRadius)
    _startRadius = x;
  else
    SUPERSTATE.startRadius = x;
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
  if (_defines.endRadius)
    _endRadius = x;
  else
    SUPERSTATE.endRadius = x;
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
  if (_defines.drawsBeforeStart)
    _drawsBeforeStart = flag;
  else
    SUPERSTATE.drawsBeforeStart = flag;
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
  if (_defines.drawsAfterEnd)
    _drawsAfterEnd = flag;
  else
    SUPERSTATE.drawsAfterEnd = flag;
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgGradientLayerState *copy = [super graphCopy:map];

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
