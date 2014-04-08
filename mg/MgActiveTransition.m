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

#import "MgActiveTransition.h"

#import "MgNodeState.h"
#import "MgNodeTransition.h"
#import "MgTimingFunction.h"
#import "MgTransitionTiming.h"

#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>

@implementation MgActiveTransition
{
  NSInteger _identifier;
  double _begin;
  double _speed;
  MgNodeState *_fromState;
  NSArray *_nodeTransitions;
  NSSet *_properties;
  MgTransitionTiming *_defaultTiming;

  double _duration;
}

- (id)init
{
  static int32_t next_id;

  self = [super init];
  if (self == nil)
    return nil;

  _identifier = OSAtomicIncrement32(&next_id);

  _speed = 1;
  _nodeTransitions = @[];
  _properties = [NSSet set];

  static MgTransitionTiming *default_timing;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      default_timing = [[MgTransitionTiming alloc] init];
      default_timing.duration = .25;
      default_timing.function = [MgTimingFunction functionWithName:
				 MgTimingFunctionDefault];
    });

  _defaultTiming = default_timing;

  _duration = -1;

  return self;
}

- (NSArray *)nodeTransitions
{
  return _nodeTransitions;
}

- (void)setNodeTransitions:(NSArray *)array
{
  if (![_nodeTransitions isEqual:array])
    {
      _nodeTransitions = [array copy];
      _duration = -1;
    }
}

- (MgTransitionTiming *)defaultTiming
{
  return _defaultTiming;
}

- (void)setDefaultTiming:(MgTransitionTiming *)obj
{
  if (_defaultTiming != obj)
    {
      _defaultTiming = [obj copy];
      _duration = -1;
    }
}

- (double)duration
{
  if (_duration < 0)
    {
      double dur = _defaultTiming.begin + _defaultTiming.duration;

      for (MgNodeTransition *trans in _nodeTransitions)
	{
	  dur = fmax(dur, trans.begin + trans.duration);
	}

      _duration = dur;
    }

  return _duration;
}

- (MgTransitionTiming *)timingForKey:(NSString *)key
{
  for (MgNodeTransition *trans in _nodeTransitions)
    {
      MgTransitionTiming *timing = [trans timingForKey:key];
      if (timing != nil)
	return timing;
    }

  return _defaultTiming;
}

- (double)evaluateTime:(double)t forKey:(NSString *)key
{
  MgTransitionTiming *timing = [self timingForKey:key];

  return timing != nil ? [timing evaluate:t] : t;
}

@end
