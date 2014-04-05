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

#import "MgBezierTimingFunction.h"

#import "MgCoderExtensions.h"
#import "MgUnitBezier.h"

#import <Foundation/Foundation.h>

@implementation MgBezierTimingFunction

- (CFTimeInterval)applyToTime:(CFTimeInterval)t epsilon:(double)eps
{
  return Mg::UnitBezier(_p0.x, _p0.y, _p1.x, _p1.y).solve(t, eps);
}

- (CFTimeInterval)applyInverseToTime:(CFTimeInterval)t epsilon:(double)eps
{
  return Mg::UnitBezier(_p0.x, _p0.y, _p1.x, _p1.y).invert(t, eps);
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgBezierTimingFunction *copy = [super copyWithZone:zone];

  copy->_p0 = _p0;
  copy->_p1 = _p1;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  [c mg_encodeCGPoint:_p0 forKey:@"p0"];
  [c mg_encodeCGPoint:_p1 forKey:@"p1"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  _p0 = [c mg_decodeCGPointForKey:@"p0"];
  _p1 = [c mg_decodeCGPointForKey:@"p1"];

  return self;
}

@end
