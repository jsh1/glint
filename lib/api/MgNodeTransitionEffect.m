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

#import "MgNodeTransitionEffect.h"

@implementation MgNodeTransitionEffect

- (MgNodeState *)evaluateAtTime:(CFTimeInterval)t
{
  t = (t - self.begin) / self.duration;

  if (self.reversed)
    t = 1 - t;

  MgFunction *fun = self.function;

  if (fun != nil)
    t = [fun evaluateScalar:t];

  if (!(t > 0))
    return self.from;
  if (!(t < 1))
    return nil;

  MgNodeTransition *trans = self.transition;

  if (trans == nil)
    return [self.from evaluateTransition:nil atTime:t to:self.to];
  else
    return [trans evaluateAtTime:t from:self.from to:self.to];
}

@end
