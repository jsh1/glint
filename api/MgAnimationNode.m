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

#import "MgAnimationNode.h"

#import "MgNodeInternal.h"
#import "MgTimingFunction.h"
#import "MgTimingStorage.h"

#import <Foundation/Foundation.h>

@implementation MgAnimationNode
{
  MgTimingStorage *_timing;
  NSString *_keyPath;
  MgTimingFunction *_timingFunction;
  MgFunction *_valueFunction;
}

- (CFTimeInterval)begin
{
  return _timing != nil ? _timing.begin : 0;
}

- (void)setBegin:(CFTimeInterval)t
{
  if (_timing == nil && t != 0)
    _timing = [[MgTimingStorage alloc] init];

  _timing.begin = t;
}

- (CFTimeInterval)duration
{
  return _timing != nil ? _timing.duration : 0;
}

- (void)setDuration:(CFTimeInterval)t
{
  if (_timing == nil && t != HUGE_VAL)
    _timing = [[MgTimingStorage alloc] init];

  _timing.duration = t;
}

- (double)speed
{
  return _timing != nil ? _timing.speed : 0;
}

- (void)setSpeed:(double)t
{
  if (_timing == nil && t != 1)
    _timing = [[MgTimingStorage alloc] init];

  _timing.speed = t;
}

- (CFTimeInterval)offset
{
  return _timing != nil ? _timing.offset : 0;
}

- (void)setOffset:(CFTimeInterval)t
{
  if (_timing == nil && t != 0)
    _timing = [[MgTimingStorage alloc] init];

  _timing.offset = t;
}

- (double)repeat
{
  return _timing != nil ? _timing.repeat : 0;
}

- (void)setRepeat:(double)t
{
  if (_timing == nil && t != 1)
    _timing = [[MgTimingStorage alloc] init];

  _timing.repeat = t;
}

- (BOOL)autoreverses
{
  return _timing != nil ? _timing.autoreverses : NO;
}

- (void)setAutoreverses:(BOOL)flag
{
  if (_timing == nil && flag)
    _timing = [[MgTimingStorage alloc] init];

  _timing.autoreverses = flag;
}

- (BOOL)holdsBeforeStart
{
  return _timing != nil ? _timing.holdsBeforeStart : NO;
}

- (void)setHoldsBeforeStart:(BOOL)flag
{
  if (_timing == nil && flag)
    _timing = [[MgTimingStorage alloc] init];

  _timing.holdsBeforeStart = flag;
}

- (BOOL)holdsAfterEnd
{
  return _timing != nil ? _timing.holdsAfterEnd : NO;
}

- (void)setHoldsAfterEnd:(BOOL)flag
{
  if (_timing == nil && flag)
    _timing = [[MgTimingStorage alloc] init];

  _timing.holdsAfterEnd = flag;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgAnimationNode *copy = [super copyWithZone:zone];

  if (_timing != nil)
    copy->_timing = [_timing copy];

  copy->_keyPath = [_keyPath copy];
  copy->_timingFunction = [_timingFunction copy];
  copy->_valueFunction = [_valueFunction copy];

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  /* Don't encode MgTimingStorage as its own object, embed its values
     in this classes (in case we want to change the implementation in
     the future). */

  if (_timing != nil)
    {
      [c encodeBool:YES forKey:@"_hasTiming"];
      [_timing encodeWithCoder:c];
    }

  if (_keyPath != nil)
    [c encodeObject:_keyPath forKey:@"keyPath"];

  if (_timingFunction != nil)
    [c encodeObject:_timingFunction forKey:@"timingFunction"];

  if (_valueFunction != nil)
    [c encodeObject:_valueFunction forKey:@"valueFunction"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c decodeBoolForKey:@"_hasTiming"])
    {
      _timing = [[MgTimingStorage alloc] init];
      [_timing decodeWithCoder:c];
    }

  if ([c containsValueForKey:@"keyPath"])
    _keyPath = [c decodeObjectOfClass:[NSString class] forKey:@"keyPath"];

  if ([c containsValueForKey:@"timingFunction"])
    _timingFunction = [c decodeObjectOfClass:[MgTimingFunction class] forKey:@"timingFunction"];

  if ([c containsValueForKey:@"valueFunction"])
    _valueFunction = [c decodeObjectOfClass:[MgFunction class] forKey:@"valueFunction"];

  return self;
}

@end
