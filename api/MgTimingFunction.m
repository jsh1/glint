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

#import <Foundation/Foundation.h>

@implementation MgTimingFunction

- (void)applyToValues:(const CGFloat *)src count:(size_t)n
    handler:(void (^)(const CGFloat *dst, size_t n))block
{
  if (n == 1)
    {
      CGFloat ret = [self applyToTime:src[0] epsilon:1e-6];
      block(&ret, 1);
    }
  else
    block(NULL, 0);
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
