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

#import "MgCoderExtensions.h"
#import "MgImageLayer.h"
#import "MgImageProvider.h"

#import <Foundation/Foundation.h>

#define SUPERSTATE ((MgImageLayerState *)(self.superstate))

@implementation MgImageLayerState
{
  id<MgImageProvider> _imageProvider;
  CGRect _cropRect;
  CGRect _centerRect;
  BOOL _repeats;

  struct {
    bool imageProvider;
    bool cropRect;
    bool centerRect;
    bool repeats;
  } _defines;
}

- (void)setDefaults
{
  [super setDefaults];

  self.imageProvider = nil;
  self.cropRect = CGRectZero;
  self.centerRect = CGRectZero;
  self.repeats = NO;
}

- (BOOL)hasValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"imageProvider"])
    return _defines.imageProvider;
  else if ([key isEqualToString:@"cropRect"])
    return _defines.cropRect;
  else if ([key isEqualToString:@"centerRect"])
    return _defines.centerRect;
  else if ([key isEqualToString:@"repeats"])
    return _defines.repeats;
  else
    return [super hasValueForKey:key];
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
  _imageProvider = p;
  _defines.imageProvider = true;
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
  _cropRect = r;
  _defines.cropRect = true;
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
  _centerRect = r;
  _defines.centerRect = true;
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
  _repeats = flag;
  _defines.repeats = true;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgImageLayerState *copy = [super copyWithZone:zone];

  copy->_imageProvider = _imageProvider;
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
