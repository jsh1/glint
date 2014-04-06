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

#import "MgNodeTransition.h"

#import "MgFunction.h"
#import "MgModuleState.h"
#import "MgNodeState.h"
#import "MgTransition.h"
#import "MgTransitionTiming.h"

#import <Foundation/Foundation.h>

@implementation MgNodeTransition
{
  NSMutableDictionary *_keyTiming;

  double _begin, _duration;
  BOOL _invalid;
}

+ (instancetype)transition
{
  return [[self alloc] init];
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _keyTiming = [[NSMutableDictionary alloc] init];

  return self;
}

- (void)_validate
{
  if ([_keyTiming count] == 0)
    _begin = _duration = 0;
  else
    {
      double start = HUGE_VAL, end = -HUGE_VAL;

      for (NSString *key in _keyTiming)
	{
	  MgTransitionTiming *timing = _keyTiming[key];

	  double begin = timing.begin;
	  double dur = timing.duration;

	  start = fmin(start, begin);
	  end = fmax(end, begin + dur);
	}

      _begin = start;
      _duration = end - start;
    }

  _invalid = NO;
}

- (double)begin
{
  if (_invalid)
    [self _validate];

  return _begin;
}

- (double)duration
{
  if (_invalid)
    [self _validate];

  return _duration;
}

- (MgTransitionTiming *)timingForKey:(NSString *)key
{
  return _keyTiming[key];
}

- (void)setTimingForKey:(MgTransitionTiming *)timing forKey:(NSString *)key
{
  _keyTiming[key] = timing;
  _invalid = YES;
}

- (BOOL)definesTimingForKey:(NSString *)key
{
  return _keyTiming[key] != nil;
}

- (double)evaluateTime:(double)t forKey:(NSString *)key
{
  MgTransitionTiming *timing = _keyTiming[key];

  if (timing != nil)
    t = [timing evaluate:t];

  return t;
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgNodeTransition *copy = [[[self class] alloc] init];

  copy->_from = [_from mg_conditionalGraphCopy:map];
  copy->_to = [_to mg_conditionalGraphCopy:map];

  if (_keyTiming != nil)
    {
      copy->_keyTiming = [NSMutableDictionary dictionary];

      for (NSString *key in _keyTiming)
	{
	  MgTransitionTiming *timing = _keyTiming[key];
	  [copy->_keyTiming setObject:[timing copy] forKey:key];
	}

      copy->_invalid = YES;
    }

  return copy;
}

/** NSSecureCoding methods. **/

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)c
{
  if (_from != nil)
    [c encodeConditionalObject:_from forKey:@"fromState"];
  if (_to != nil)
    [c encodeConditionalObject:_to forKey:@"toState"];
  if (_keyTiming != nil)
    [c encodeObject:_keyTiming forKey:@"keyTiming"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [self init];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"from"])
    _from = [c decodeObjectOfClass:[MgModuleState class] forKey:@"from"];
  if ([c containsValueForKey:@"to"])
    _to = [c decodeObjectOfClass:[MgModuleState class] forKey:@"to"];

  if ([c containsValueForKey:@"keyTiming"])
    {
      _keyTiming = [[c decodeObjectOfClass:[NSDictionary class]
		     forKey:@"keyTiming"] mutableCopy];
      _invalid = YES;
    }

  return self;
}

@end
