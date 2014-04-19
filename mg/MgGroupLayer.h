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

#import "MgLayer.h"

@interface MgGroupLayer : MgLayer

/* When true the layer pre-composites all its content into a buffer,
   before sending anything to the render server. The behavior is
   undefined if the content extends outside the bounds of the receiver.
   Defaults to false. */

@property(nonatomic, assign) BOOL flattensSublayers;

/* When false, the layer also creates a compositing group, otherwise it
   acts as a transform-only group, i.e. no compositing group is
   created, and the layer's blend mode and mask are ignored, similar to
   the "Pass Through" blend mode in Photoshop. Defaults to true. */

@property(nonatomic, assign, getter=isPassThrough) BOOL passThrough;

/* The array of sublayers comprising this group. */

@property(nonatomic, copy) NSArray *sublayers;

- (void)addSublayer:(MgLayer *)node;
- (void)removeSublayer:(MgLayer *)node;

- (void)insertSublayer:(MgLayer *)node atIndex:(NSInteger)idx;
- (void)removeSublayerAtIndex:(NSInteger)idx;

@end
