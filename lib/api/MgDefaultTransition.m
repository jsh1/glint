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

#import "MgDefaultTransition.h"

#import "MgTimingFunction.h"

#define DEFAULT_DURATION 1
#define DEFAULT_FUNCTION MgTimingFunctionEaseInOut

@implementation MgDefaultTransition
{
  double _duration;
  MgFunction *_function;
}

@synthesize duration = _duration;

- (id)initWithOptions:(NSDictionary *)dict
{
  self = [super init];
  if (self == nil)
    return nil;

  _duration = [dict[@"duration"] doubleValue];
  if (_duration == 0)
    _duration = DEFAULT_DURATION;

  _function = dict[@"function"];
  if (_function == nil)
    _function = [MgTimingFunction functionWithName:DEFAULT_FUNCTION];

  return self;
}

- (BOOL)definesTimingForKey:(NSString *)key
{
  return YES;
}

- (double)evaluateTime:(double)t forKey:(NSString *)key
{
  return [_function evaluateScalar:t / _duration];
}

@end
