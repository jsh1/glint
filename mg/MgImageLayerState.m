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

#import "MgImageLayerState.h"

#import "MgActiveTransition.h"
#import "MgCoreGraphics.h"
#import "MgCoderExtensions.h"
#import "MgImageLayer.h"
#import "MgImageProvider.h"
#import "MgNodeTransition.h"

#import <Foundation/Foundation.h>

#define SUPERSTATE ((MgImageLayerState *)(self.superstate))

@implementation MgImageLayerState
{
  id<MgImageProvider> _imageProvider;
  CGInterpolationQuality _interpolationQuality;
  CGRect _cropRect;
  CGRect _centerRect;
  BOOL _repeats;

  struct {
    bool imageProvider;
    bool interpolationQuality;
    bool cropRect;
    bool centerRect;
    bool repeats;
  } _defines;
}

- (void)setDefaults
{
  [super setDefaults];

  _imageProvider = nil;
  _interpolationQuality = kCGInterpolationDefault;
  _cropRect = CGRectZero;
  _centerRect = CGRectZero;
  _repeats = NO;

  _defines.imageProvider = true;
  _defines.interpolationQuality = true;
  _defines.cropRect = true;
  _defines.centerRect = true;
  _defines.repeats = true;
}

- (BOOL)definesValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"imageProvider"])
    return _defines.imageProvider;
  else if ([key isEqualToString:@"interpolationQuality"])
    return _defines.interpolationQuality;
  else if ([key isEqualToString:@"cropRect"])
    return _defines.cropRect;
  else if ([key isEqualToString:@"centerRect"])
    return _defines.centerRect;
  else if ([key isEqualToString:@"repeats"])
    return _defines.repeats;
  else
    return [super definesValueForKey:key];
}

- (void)setDefinesValue:(BOOL)flag forKey:(NSString *)key
{
  if ([key isEqualToString:@"imageProvider"])
    _defines.imageProvider = flag;
  else if ([key isEqualToString:@"interpolationQuality"])
    _defines.interpolationQuality = flag;
  else if ([key isEqualToString:@"cropRect"])
    _defines.cropRect = flag;
  else if ([key isEqualToString:@"centerRect"])
    _defines.centerRect = flag;
  else if ([key isEqualToString:@"repeats"])
    _defines.repeats = flag;
  else
    [super setDefinesValue:flag forKey:key];
}

- (void)applyTransition:(MgActiveTransition *)trans atTime:(double)t
    to:(MgNodeState *)to_
{
  MgImageLayerState *to = (MgImageLayerState *)to_;
  double t_;

  [super applyTransition:trans atTime:t to:to];

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"imageProvider"] : t;
  _imageProvider = t_ < .5 ? self.imageProvider : to.imageProvider;
  _defines.imageProvider = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"interpolationQuality"] : t;
  _interpolationQuality = t_ < .5 ? self.interpolationQuality : to.interpolationQuality;
  _defines.interpolationQuality = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"cropRect"] : t;
  _cropRect = MgRectMix(self.cropRect, to.cropRect, t_);
  _defines.cropRect = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"centerRect"] : t;
  _centerRect = MgRectMix(self.centerRect, to.centerRect, t_);
  _defines.centerRect = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"repeats"] : t;
  _repeats = t_ < .5 ? self.repeats : to.repeats;
  _defines.repeats = true;
}

- (id<MgImageProvider>)imageProvider
{
  if (_defines.imageProvider)
    return _imageProvider;
  else
    return SUPERSTATE.imageProvider;
}

- (void)setImageProvider:(id<MgImageProvider>)p
{
  if (_defines.imageProvider)
    _imageProvider = p;
  else
    SUPERSTATE.imageProvider = p;
}

- (CGInterpolationQuality)interpolationQuality
{
  if (_defines.interpolationQuality)
    return _interpolationQuality;
  else
    return SUPERSTATE.interpolationQuality;
}

- (void)setInterpolationQuality:(CGInterpolationQuality)q
{
  if (_defines.interpolationQuality)
    _interpolationQuality = q;
  else
    SUPERSTATE.interpolationQuality = q;
}

- (CGRect)cropRect
{
  if (_defines.cropRect)
    return _cropRect;
  else
    return SUPERSTATE.cropRect;
}

- (void)setCropRect:(CGRect)r
{
  if (_defines.cropRect)
    _cropRect = r;
  else
    SUPERSTATE.cropRect = r;
}

- (CGRect)centerRect
{
  if (_defines.centerRect)
    return _centerRect;
  else
    return SUPERSTATE.centerRect;
}

- (void)setCenterRect:(CGRect)r
{
  if (_defines.centerRect)
    _centerRect = r;
  else
    SUPERSTATE.centerRect = r;
}

- (BOOL)repeats
{
  if (_defines.repeats)
    return _repeats;
  else
    return SUPERSTATE.repeats;
}

- (void)setRepeats:(BOOL)flag
{
  if (_defines.repeats)
    _repeats = flag;
  else
    SUPERSTATE.repeats = flag;
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgImageLayerState *copy = [super graphCopy:map];

  copy->_imageProvider = _imageProvider;
  copy->_interpolationQuality = _interpolationQuality;
  copy->_cropRect = _cropRect;
  copy->_centerRect = _centerRect;
  copy->_repeats = _repeats;
  copy->_defines = _defines;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_defines.imageProvider
      && [_imageProvider conformsToProtocol:@protocol(NSSecureCoding)])
    {
      [c encodeObject:_imageProvider forKey:@"imageProvider"];
    }

  if (_defines.interpolationQuality)
    [c encodeInt:_interpolationQuality forKey:@"interpolationQuality"];

  if (_defines.cropRect)
    [c mg_encodeCGRect:_cropRect forKey:@"cropRect"];

  if (_defines.centerRect)
    [c mg_encodeCGRect:_centerRect forKey:@"centerRect"];

  if (_defines.repeats)
    [c encodeBool:_repeats forKey:@"repeats"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"imageProvider"])
    {
      _imageProvider = [c decodeObjectOfClasses:
			[MgImageLayer imageProviderClasses]
			forKey:@"imageProvider"];
      _defines.imageProvider = true;
    }

  if ([c containsValueForKey:@"interpolationQuality"])
    {
      _interpolationQuality = [c decodeIntForKey:@"interpolationQuality"];
      _defines.interpolationQuality = true;
    }

  if ([c containsValueForKey:@"cropRect"])
    {
      _cropRect = [c mg_decodeCGRectForKey:@"cropRect"];
      _defines.cropRect = true;
    }

  if ([c containsValueForKey:@"centerRect"])
    {
      _centerRect = [c mg_decodeCGRectForKey:@"centerRect"];
      _defines.centerRect = true;
    }

  if ([c containsValueForKey:@"repeats"])
    {
      _repeats = [c decodeBoolForKey:@"repeats"];
      _defines.repeats = true;
    }

  return self;
}

@end
