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

#import "MgCompositeTransition.h"

@implementation MgCompositeTransition
{
  NSArray *_transitions;
  double _begin;
  double _duration;
}

- (id)initWithArray:(NSArray *)transitions
{
  self = [super init];
  if (self == nil)
    return nil;

  _transitions = [transitions copy];

  double start = 0, end = 0;
  
  for (MgTransition *trans in _transitions)
    {
      double begin = trans.begin;
      double dur = trans.duration;

      start = fmin(start, begin);
      end = fmax(end, begin + dur);
    }

  _begin = start;
  _duration = end - start;

  return self;
}

- (double)begin
{
  return _begin;
}

- (double)duration
{
  return _duration;
}

- (BOOL)definesTimingForKey:(NSString *)key
{
  for (MgTransition *trans in _transitions)
    {
      if ([trans definesTimingForKey:key])
	return YES;
    }

  return NO;
}

- (double)evaluateTime:(double)t forKey:(NSString *)key
{
  for (MgTransition *trans in _transitions)
    {
      if ([trans definesTimingForKey:key])
	{
	  return [trans evaluateTime:t forKey:key];
	}
    }

  return t;
}

@end
