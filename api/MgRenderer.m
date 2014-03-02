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

#import "MgRenderer.h"

#import "MgDrawableNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgRenderer
{
  id _ctx;				/* CGContextRef */

  MgDrawableNode *_rootNode;
  CGRect _bounds;

  CFTimeInterval _frameTime;
}

@synthesize rootNode = _rootNode;
@synthesize bounds = _bounds;

+ (instancetype)rendererWithCGContext:(CGContextRef)ctx
{
  MgRenderer *r = [[self alloc] init];
  r->_ctx = (__bridge id)ctx;
  return r;
}

- (void)beginFrameAtTime:(CFTimeInterval)t
{
  _frameTime = t;
}

- (void)endFrame
{
  _frameTime = 0;
}

- (CFTimeInterval)render
{
  MgDrawableRenderState rs;
  rs.ctx = (__bridge CGContextRef)_ctx;
  rs.t = _frameTime;
  rs.tnext = HUGE_VAL;
  rs.bounds = _bounds;
  rs.cornerRadius = 0;
  rs.alpha = 1;

  [_rootNode renderWithState:&rs];

  return rs.tnext;
}

@end
