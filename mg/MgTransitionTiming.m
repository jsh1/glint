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

#import "MgTransitionTiming.h"

#import "MgFunction.h"

#import <Foundation/Foundation.h>

@implementation MgTransitionTiming

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _enabled = YES;
  _begin = 0;
  _duration = 1;

  return self;
}

- (double)evaluate:(double)t
{
  if (!_enabled)
    return 1;

  t = (t - _begin) / _duration;
  
  if (_function != nil)
    t = [_function evaluateScalar:t];

  return t;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgTransitionTiming *copy = [[[self class] alloc] init];

  copy->_enabled = _enabled;
  copy->_begin = _begin;
  copy->_duration = _duration;
  copy->_function = _function;

  return copy;
}

/** NSSecureCoding methods. **/

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)c
{
  if (!_enabled)
    [c encodeBool:_enabled forKey:@"enabled"];
  if (_begin != 0)
    [c encodeDouble:_begin forKey:@"begin"];
  if (_duration != 1)
    [c encodeDouble:_duration forKey:@"duration"];
  if (_function != nil)
    [c encodeObject:_function forKey:@"function"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [self init];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"enabled"])
    _enabled = [c decodeDoubleForKey:@"enabled"];

  if ([c containsValueForKey:@"begin"])
    _begin = [c decodeDoubleForKey:@"begin"];

  if ([c containsValueForKey:@"duration"])
    _duration = [c decodeDoubleForKey:@"duration"];

  if ([c containsValueForKey:@"function"])
    _function = [c decodeObjectOfClass:[MgFunction class] forKey:@"function"];

  return self;
}

@end
