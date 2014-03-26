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

#import <Foundation/Foundation.h>

MG_HIDDEN_CLASS
@interface MgNodeTransitionTiming : NSObject <NSCopying, NSSecureCoding>
@property(nonatomic, assign) double begin;
@property(nonatomic, assign) double duration;
@property(nonatomic, copy) MgFunction *function;
@end

@implementation MgNodeTransition
{
  MgNodeTransitionTiming *_timing;
  NSMutableDictionary *_keyTiming;
}

+ (instancetype)transition
{
  return [[self alloc] init];
}

- (double)begin
{
  return _timing != nil ? _timing.begin : 0;
}

- (void)setBegin:(double)x
{
  if (_timing == nil)
    _timing = [[MgNodeTransitionTiming alloc] init];
  _timing.begin = x;
}

- (double)duration
{
  return _timing != nil ? _timing.duration : 1;
}

- (void)setDuration:(double)x
{
  if (_timing == nil)
    _timing = [[MgNodeTransitionTiming alloc] init];
  _timing.duration = x;
}

- (MgFunction *)function
{
  return _timing != nil ? _timing.function : 0;
}

- (void)setFunction:(MgFunction *)x
{
  if (_timing == nil)
    _timing = [[MgNodeTransitionTiming alloc] init];
  _timing.function = x;
}

- (double)beginForKey:(NSString *)key
{
  MgNodeTransitionTiming *timing = _keyTiming[key];

  return timing != nil ? timing.begin : 0;
}

- (void)setBeginForKey:(double)t forKey:(NSString *)key
{
  MgNodeTransitionTiming *timing = _keyTiming[key];

  if (timing == nil)
    {
      timing = [[MgNodeTransitionTiming alloc] init];
      if (_keyTiming == nil)
	_keyTiming = [[NSMutableDictionary alloc] init];
      _keyTiming[key] = timing;
    }

  timing.begin = t;
}

- (double)durationForKey:(NSString *)key
{
  MgNodeTransitionTiming *timing = _keyTiming[key];

  return timing != nil ? timing.duration : 1;
}

- (void)setDuration:(double)t forKey:(NSString *)key
{
  MgNodeTransitionTiming *timing = _keyTiming[key];

  if (timing == nil)
    {
      timing = [[MgNodeTransitionTiming alloc] init];
      if (_keyTiming == nil)
	_keyTiming = [[NSMutableDictionary alloc] init];
      _keyTiming[key] = timing;
    }

  timing.duration = t;
}

- (MgFunction *)functionForKey:(NSString *)key
{
  MgNodeTransitionTiming *timing = _keyTiming[key];

  return timing.function;
}

- (void)setFunction:(MgFunction *)fun forKey:(NSString *)key
{
  MgNodeTransitionTiming *timing = _keyTiming[key];

  if (timing == nil)
    {
      timing = [[MgNodeTransitionTiming alloc] init];
      if (_keyTiming == nil)
	_keyTiming = [[NSMutableDictionary alloc] init];
      _keyTiming[key] = timing;
    }

  timing.function = fun;
}

- (CFTimeInterval)evaluateTime:(CFTimeInterval)t forKey:(NSString *)key
{
  MgNodeTransitionTiming *timing = _keyTiming[key];
  if (timing == nil)
    return t;

  t = (t - timing.begin) / timing.duration;
  
  MgFunction *fun = timing.function;

  if (fun != nil)
    t = [fun evaluateScalar:t];

  return t;
}

- (MgNodeState *)evaluateAtTime:(CFTimeInterval)t from:(MgNodeState *)from
    to:(MgNodeState *)to
{
  t = (t - self.begin) / self.duration;

  MgFunction *fun = self.function;

  if (fun != nil)
    t = [fun evaluateScalar:t];

  if (!(t > 0))
    return from;
  if (!(t < 1))
    return nil;

  return [from evaluateTransition:self atTime:t to:to];
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgNodeTransition *copy = [[[self class] alloc] init];

  copy->_fromState = [_fromState mg_conditionalGraphCopy:map];
  copy->_toState = [_toState mg_conditionalGraphCopy:map];
  copy->_reversible = _reversible;

  if (_timing != nil)
    copy->_timing = [_timing copy];

  if (_keyTiming != nil)
    {
      copy->_keyTiming = [[NSMutableDictionary alloc] init];

      for (NSString *key in _keyTiming)
	{
	  MgNodeTransitionTiming *timing = _keyTiming[key];
	  [copy->_keyTiming setObject:[timing copy] forKey:key];
	}
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
  if (_fromState != nil)
    [c encodeConditionalObject:_fromState forKey:@"fromState"];
  if (_toState != nil)
    [c encodeConditionalObject:_toState forKey:@"toState"];
  if (_reversible)
    [c encodeBool:_reversible forKey:@"reversible"];
  if (_timing != nil)
    [c encodeObject:_timing forKey:@"timing"];
  if (_keyTiming != nil)
    [c encodeObject:_keyTiming forKey:@"keyTiming"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [self init];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"fromState"])
    {
      _fromState = [c decodeObjectOfClass:[MgModuleState class]
		    forKey:@"fromState"];
    }
  if ([c containsValueForKey:@"toState"])
    {
      _toState = [c decodeObjectOfClass:[MgModuleState class]
		  forKey:@"toState"];
    }

  if ([c containsValueForKey:@"reversible"])
    _reversible = [c decodeBoolForKey:@"reversible"];

  if ([c containsValueForKey:@"timing"])
    {
      _timing = [[c decodeObjectOfClass:[MgNodeTransitionTiming class]
		  forKey:@"timing"] mutableCopy];
    }

  if ([c containsValueForKey:@"timing"])
    {
      _keyTiming = [[c decodeObjectOfClass:[NSDictionary class]
		     forKey:@"keyTiming"] mutableCopy];
    }

  return self;
}

@end

@implementation MgNodeTransitionTiming

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _begin = 0;
  _duration = 1;

  return self;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgNodeTransitionTiming *copy = [[[self class] alloc] init];

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

  if ([c containsValueForKey:@"begin"])
    _begin = [c decodeDoubleForKey:@"begin"];

  if ([c containsValueForKey:@"duration"])
    _duration = [c decodeDoubleForKey:@"duration"];

  if ([c containsValueForKey:@"function"])
    _function = [c decodeObjectOfClass:[MgFunction class] forKey:@"function"];

  return self;
}

@end
