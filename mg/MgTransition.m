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

#import "MgTransition.h"

#import "MgCompositeTransition.h"
#import "MgDefaultTransition.h"
#import "MgNodeState.h"
#import "MgTimedTransition.h"

#import <Foundation/Foundation.h>

@implementation MgTransition

+ (instancetype)defaultTransitionWithOptions:(NSDictionary *)dict
{
  return [[MgDefaultTransition alloc] initWithOptions:dict];
}

+ (instancetype)transitionWithArray:(NSArray *)array
{
  switch ([array count])
    {
    case 0:
      return nil;

    case 1:
      return array[0];

    default:
      return [[MgCompositeTransition alloc] initWithArray:array];
    }
}

- (instancetype)transitionWithBegin:(double)begin speed:(double)speed;
{
  MgTimedTransition *tx = [[MgTimedTransition alloc] initWithTransition:self];

  tx.begin = begin;
  tx.speed = speed;

  return tx;
}

- (double)begin
{
  return 0;
}

- (double)duration
{
  return 1;
}

- (BOOL)definesTimingForKey:(NSString *)key
{
  return NO;
}

- (CFTimeInterval)evaluateTime:(CFTimeInterval)t forKey:(NSString *)key
{
  return t;
}

- (MgNodeState *)evaluateAtTime:(CFTimeInterval)t from:(MgNodeState *)from
    to:(MgNodeState *)to
{
  return nil;
}

@end
