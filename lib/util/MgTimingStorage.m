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

#import "MgTimingStorage.h"

#import <Foundation/Foundation.h>

@implementation MgTimingStorage

@synthesize begin = _begin;
@synthesize duration = _duration;
@synthesize speed = _speed;
@synthesize offset = _offset;
@synthesize repeat = _repeat;
@synthesize autoreverses = _autoreverses;
@synthesize holdsBeforeStart = _holdsBeforeStart;
@synthesize holdsAfterEnd = _holdsAfterEnd;

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _duration = HUGE_VAL;
  _speed = 1;
  _repeat = 1;

  return self;
}

- (CFTimeInterval)applyToTime:(CFTimeInterval)t
{                                
  /* See SMIL spec for description of this timing math. */

  if (_speed != 0)
    {
      t = t - _begin;

      if (_holdsBeforeStart && t < 0)
	t = 0;
      else if (_holdsAfterEnd && isfinite(_duration))
	{
	  CFTimeInterval dur = !_autoreverses ? _duration : _duration * 2;
	  CFTimeInterval len = dur * _repeat * fabs(_speed);
	  if (!(t < len))
	    t = len - 1e-100;
	}

      t = t * _speed + _offset;
    }
  else
    t = _offset;

  if (t > 0 && isfinite(_duration))
    {
      CFTimeInterval dur = !_autoreverses ? _duration : _duration * 2;
      t = t - dur * floor(t / dur);
      if (_autoreverses && t > _duration)
	t = dur - t;
    }

  return t;
}

- (CFTimeInterval)applyInverseToTime:(CFTimeInterval)t
    currentTime:(CFTimeInterval)now
{
  /* FIXME: handle repeats, etc. */

  if (_speed != 0)
    {
      t = (t - _offset) / _speed;
      t = _begin + t;
    }
  else
    t = now;

  return t;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgTimingStorage *copy = [[MgTimingStorage alloc] init];

  copy->_begin = _begin;
  copy->_duration = _duration;
  copy->_speed = _speed;
  copy->_offset = _offset;
  copy->_repeat = _repeat;
  copy->_autoreverses = _autoreverses;
  copy->_holdsBeforeStart = _holdsBeforeStart;
  copy->_holdsAfterEnd = _holdsAfterEnd;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  if (_begin != 0)
    [c encodeDouble:_begin forKey:@"begin"];

  if (_duration != HUGE_VAL)
    [c encodeDouble:_duration forKey:@"duration"];

  if (_speed != 1)
    [c encodeDouble:_speed forKey:@"speed"];

  if (_offset != 0)
    [c encodeDouble:_offset forKey:@"offset"];

  if (_repeat != 0)
    [c encodeDouble:_repeat forKey:@"repeat"];

  if (_autoreverses)
    [c encodeBool:_autoreverses forKey:@"autoreverses"];

  if (_holdsBeforeStart)
    [c encodeBool:_holdsBeforeStart forKey:@"holdsBeforeStart"];

  if (_holdsAfterEnd)
    [c encodeBool:_holdsAfterEnd forKey:@"holdsAfterEnd"];
}

- (void)decodeWithCoder:(NSCoder *)c
{
  if ([c containsValueForKey:@"begin"])
    _begin = [c decodeDoubleForKey:@"begin"];

  if ([c containsValueForKey:@"duration"])
    _duration = [c decodeDoubleForKey:@"duration"];

  if ([c containsValueForKey:@"speed"])
    _speed = [c decodeDoubleForKey:@"speed"];

  if ([c containsValueForKey:@"offset"])
    _offset = [c decodeDoubleForKey:@"offset"];

  if ([c containsValueForKey:@"repeat"])
    _repeat = [c decodeDoubleForKey:@"repeat"];

  if ([c containsValueForKey:@"autoreverses"])
    _autoreverses = [c decodeBoolForKey:@"autoreverses"];

  if ([c containsValueForKey:@"holdsBeforeStart"])
    _holdsBeforeStart = [c decodeBoolForKey:@"holdsBeforeStart"];

  if ([c containsValueForKey:@"holdsAfterEnd"])
    _holdsAfterEnd = [c decodeBoolForKey:@"holdsAfterEnd"];
}

@end
