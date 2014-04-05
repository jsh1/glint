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

#import "MgTimingFunction.h"

#import "MgBezierTimingFunction.h"

#import <Foundation/Foundation.h>

NSString * const MgTimingFunctionDefault = @"default";
NSString * const MgTimingFunctionLinear = @"linear";
NSString * const MgTimingFunctionEaseIn = @"ease-in";
NSString * const MgTimingFunctionEaseOut = @"ease-out";
NSString * const MgTimingFunctionEaseInOut = @"ease-in-out";

@implementation MgTimingFunction

+ (instancetype)functionWithName:(NSString *)name
{
  static NSDictionary *functions;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      MgBezierTimingFunction *def = [[MgBezierTimingFunction alloc] init];
      def.p0 = CGPointMake(.25, .1);
      def.p1 = CGPointMake(.25, 1);

      MgBezierTimingFunction *linear = [[MgBezierTimingFunction alloc] init];
      linear.p0 = CGPointMake(0, 0);
      linear.p1 = CGPointMake(1, 1);

      MgBezierTimingFunction *e_in = [[MgBezierTimingFunction alloc] init];
      e_in.p0 = CGPointMake(0.42, 0);
      e_in.p1 = CGPointMake(1, 1);

      MgBezierTimingFunction *e_out = [[MgBezierTimingFunction alloc] init];
      e_out.p0 = CGPointMake(0, 0);
      e_out.p1 = CGPointMake(.58, 1);

      MgBezierTimingFunction *e_in_out = [[MgBezierTimingFunction alloc] init];
      e_in_out.p0 = CGPointMake(.42, 0);
      e_in_out.p1 = CGPointMake(.58, 1);

      functions = @{
	MgTimingFunctionDefault: def,
	MgTimingFunctionLinear: linear,
	MgTimingFunctionEaseIn: e_in,
	MgTimingFunctionEaseOut: e_out,
	MgTimingFunctionEaseInOut: e_in_out
      };
    });

  return functions[name];
}

- (NSInteger)domainDimension
{
  return 1;
}

- (NSInteger)rangeDimension
{
  return 1;
}

- (void)evaluate:(const double *)in result:(double *)out
{
  out[0] = [self applyToTime:in[0] epsilon:1e-5];
}

- (CFTimeInterval)applyToTime:(CFTimeInterval)t epsilon:(double)eps
{
  return t;
}

- (CFTimeInterval)applyInverseToTime:(CFTimeInterval)t epsilon:(double)eps
{
  return t;
}

@end
