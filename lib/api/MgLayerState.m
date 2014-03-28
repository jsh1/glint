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

#import "MgLayerState.h"

#import "MgCoderExtensions.h"
#import "MgCoreGraphics.h"
#import "MgNodeTransition.h"

#import <Foundation/Foundation.h>

#define SUPERSTATE ((MgLayerState *)(self.superstate))

@implementation MgLayerState
{
  CGPoint _position;
  CGPoint _anchor;
  CGSize _size;
  CGPoint _origin;
  CGFloat _scale;
  CGFloat _squeeze;
  CGFloat _skew;
  double _rotation;
  float _alpha;
  CGBlendMode _blendMode;

  struct {
    bool position :1;
    bool anchor :1;
    bool size :1;
    bool origin :1;
    bool scale :1;
    bool squeeze :1;
    bool skew :1;
    bool rotation :1;
    bool alpha :1;
    bool blendMode :1;
  } _defines;
}

- (void)setDefaults
{
  [super setDefaults];

  _position = CGPointZero;
  _anchor = CGPointMake((CGFloat).5, (CGFloat).5);
  _size = CGSizeZero;
  _origin = CGPointZero;
  _scale = 1;
  _squeeze = 1;
  _skew = 0;
  _rotation = 0;
  _alpha = 1;
  _blendMode = kCGBlendModeNormal;

  _defines.position = true;
  _defines.anchor = true;
  _defines.size = true;
  _defines.origin = true;
  _defines.scale = true;
  _defines.squeeze = true;
  _defines.skew = true;
  _defines.rotation = true;
  _defines.alpha = true;
  _defines.blendMode = true;
}

- (BOOL)definesValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"position"])
    return _defines.position;
  else if ([key isEqualToString:@"anchor"])
    return _defines.anchor;
  else if ([key isEqualToString:@"size"])
    return _defines.size;
  else if ([key isEqualToString:@"origin"])
    return _defines.origin;
  else if ([key isEqualToString:@"scale"])
    return _defines.scale;
  else if ([key isEqualToString:@"squeeze"])
    return _defines.squeeze;
  else if ([key isEqualToString:@"skew"])
    return _defines.skew;
  else if ([key isEqualToString:@"rotation"])
    return _defines.rotation;
  else if ([key isEqualToString:@"alpha"])
    return _defines.alpha;
  else if ([key isEqualToString:@"blendMode"])
    return _defines.blendMode;
  else
    return [super definesValueForKey:key];
}

- (void)setDefinesValue:(BOOL)flag forKey:(NSString *)key
{
  if ([key isEqualToString:@"position"])
    _defines.position = flag;
  else if ([key isEqualToString:@"anchor"])
    _defines.anchor = flag;
  else if ([key isEqualToString:@"size"])
    _defines.size = flag;
  else if ([key isEqualToString:@"origin"])
    _defines.origin = flag;
  else if ([key isEqualToString:@"scale"])
    _defines.scale = flag;
  else if ([key isEqualToString:@"squeeze"])
    _defines.squeeze = flag;
  else if ([key isEqualToString:@"skew"])
    _defines.skew = flag;
  else if ([key isEqualToString:@"rotation"])
    _defines.rotation = flag;
  else if ([key isEqualToString:@"alpha"])
    _defines.alpha = flag;
  else if ([key isEqualToString:@"blendMode"])
    _defines.blendMode = flag;
  else
    [super setDefinesValue:flag forKey:key];
}

- (void)applyTransition:(MgTransition *)trans atTime:(double)t
    to:(MgNodeState *)to_
{
  MgLayerState *to = (MgLayerState *)to_;
  double t_;

  [super applyTransition:trans atTime:t to:to];

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"position"] : t;
  _position = MgPointMix(self.position, to.position, t_);
  _defines.position = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"anchor"] : t;
  _anchor = MgPointMix(self.anchor, to.anchor, t_);
  _defines.anchor = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"size"] : t;
  _size = MgSizeMix(self.size, to.size, t_);
  _defines.size = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"origin"] : t;
  _origin = MgPointMix(self.origin, to.origin, t_);
  _defines.origin = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"scale"] : t;
  _scale = MgFloatMix(self.scale, to.scale, t_);
  _defines.scale = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"squeeze"] : t;
  _squeeze = MgFloatMix(self.squeeze, to.squeeze, t_);
  _defines.squeeze = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"skew"] : t;
  _skew = MgFloatMix(self.skew, to.skew, t_);
  _defines.skew = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"rotation"] : t;
  _rotation = MgFloatMix(self.rotation, to.rotation, t_);
  _defines.rotation = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"alpha"] : t;
  _alpha = MgFloatMix(self.alpha, to.alpha, t_);
  _defines.alpha = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"blendMode"] : t;
  _blendMode = (t_ < .5) ? self.blendMode : to.blendMode;
  _defines.blendMode = true;
}

- (CGPoint)position
{
  if (_defines.position)
    return _position;
  else
    return SUPERSTATE.position;
}

- (void)setPosition:(CGPoint)p
{
  if (_defines.position)
    _position = p;
  else
    SUPERSTATE.position = p;
}

- (CGPoint)anchor
{
  if (_defines.anchor)
    return _anchor;
  else
    return SUPERSTATE.anchor;
}

- (void)setAnchor:(CGPoint)p
{
  if (_defines.anchor)
    _anchor = p;
  else
    SUPERSTATE.anchor = p;
}

- (CGSize)size
{
  if (_defines.size)
    return _size;
  else
    return SUPERSTATE.size;
}

- (void)setSize:(CGSize)s
{
  if (_defines.size)
    _size = s;
  else
    SUPERSTATE.size = s;
}

- (CGPoint)origin
{
  if (_defines.origin)
    return _origin;
  else
    return SUPERSTATE.origin;
}

- (void)setOrigin:(CGPoint)p
{
  if (_defines.origin)
    _origin = p;
  else
    SUPERSTATE.origin = p;
}

- (CGFloat)scale
{
  if (_defines.scale)
    return _scale;
  else
    return SUPERSTATE.scale;
}

- (void)setScale:(CGFloat)x
{
  if (_defines.scale)
    _scale = x;
  else
    SUPERSTATE.scale = x;
}

- (CGFloat)squeeze
{
  if (_defines.squeeze)
    return _squeeze;
  else
    return SUPERSTATE.squeeze;
}

- (void)setSqueeze:(CGFloat)x
{
  if (_defines.squeeze)
    _squeeze = x;
  else
    SUPERSTATE.squeeze = x;
}

- (CGFloat)skew
{
  if (_defines.skew)
    return _skew;
  else
    return SUPERSTATE.skew;
}

- (void)setSkew:(CGFloat)x
{
  if (_defines.skew)
    _skew = x;
  else
    SUPERSTATE.skew = x;
}

- (double)rotation
{
  if (_defines.rotation)
    return _rotation;
  else
    return SUPERSTATE.rotation;
}

- (void)setRotation:(double)x
{
  if (_defines.rotation)
    _rotation = x;
  else
    SUPERSTATE.rotation = x;
}

- (float)alpha
{
  if (_defines.alpha)
    return _alpha;
  else
    return SUPERSTATE.alpha;
}

- (void)setAlpha:(float)x
{
  if (_defines.alpha)
    _alpha = x;
  else
    SUPERSTATE.alpha = x;
}

- (CGBlendMode)blendMode
{
  if (_defines.blendMode)
    return _blendMode;
  else
    return SUPERSTATE.blendMode;
}

- (void)setBlendMode:(CGBlendMode)x
{
  if (_defines.blendMode)
    _blendMode = x;
  else
    SUPERSTATE.blendMode = x;
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgLayerState *copy = [super graphCopy:map];

  copy->_position = _position;
  copy->_anchor = _anchor;
  copy->_size = _size;
  copy->_origin = _origin;
  copy->_scale = _scale;
  copy->_squeeze = _squeeze;
  copy->_skew = _skew;
  copy->_rotation = _rotation;
  copy->_alpha = _alpha;
  copy->_blendMode = _blendMode;
  copy->_defines = _defines;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_defines.position)
    [c mg_encodeCGPoint:_position forKey:@"position"];

  if (_defines.anchor)
    [c mg_encodeCGPoint:_anchor forKey:@"anchor"];

  if (_defines.size)
    [c mg_encodeCGSize:_size forKey:@"size"];

  if (_defines.origin)
    [c mg_encodeCGPoint:_origin forKey:@"origin"];

  if (_defines.scale)
    [c encodeDouble:_scale forKey:@"scale"];

  if (_defines.squeeze)
    [c encodeDouble:_squeeze forKey:@"squeeze"];

  if (_defines.skew)
    [c encodeDouble:_skew forKey:@"skew"];

  if (_defines.rotation)
    [c encodeDouble:_rotation forKey:@"rotation"];

  if (_defines.alpha)
    [c encodeFloat:_alpha forKey:@"alpha"];

  if (_defines.blendMode)
    [c encodeInt:_blendMode forKey:@"blendMode"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"position"])
    {
      _position = [c mg_decodeCGPointForKey:@"position"];
      _defines.position = true;
    }

  if ([c containsValueForKey:@"anchor"])
    {
      _anchor = [c mg_decodeCGPointForKey:@"anchor"];
      _defines.anchor = true;
    }

  if ([c containsValueForKey:@"size"])
    {
      _size = [c mg_decodeCGSizeForKey:@"size"];
      _defines.size = true;
    }

  if ([c containsValueForKey:@"origin"])
    {
      _origin = [c mg_decodeCGPointForKey:@"origin"];
      _defines.origin = true;
    }

  if ([c containsValueForKey:@"scale"])
    {
      _scale = [c decodeDoubleForKey:@"scale"];
      _defines.scale = true;
    }

  if ([c containsValueForKey:@"squeeze"])
    {
      _squeeze = [c decodeDoubleForKey:@"squeeze"];
      _defines.squeeze = true;
    }

  if ([c containsValueForKey:@"skew"])
    {
      _skew = [c decodeDoubleForKey:@"skew"];
      _defines.skew = true;
    }

  if ([c containsValueForKey:@"rotation"])
    {
      _rotation = [c decodeDoubleForKey:@"rotation"];
      _defines.rotation = true;
    }

  if ([c containsValueForKey:@"alpha"])
    {
      _alpha = [c decodeFloatForKey:@"alpha"];
      _defines.alpha = true;
    }

  if ([c containsValueForKey:@"blendMode"])
    {
      _blendMode = (CGBlendMode)[c decodeIntForKey:@"blendMode"];
      _defines.blendMode = true;
    }

  return self;
}

@end
