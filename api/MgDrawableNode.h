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

#import "MgNode.h"

@interface MgDrawableNode : MgNode

/* When true node is not drawn. This property is NOT animatable. */

@property(nonatomic, assign, getter=isHidden) BOOL hidden;

/* Array of animations attached to this node. */

@property(nonatomic, copy) NSArray *animations;

- (void)insertAnimation:(MgAnimationNode *)anim atIndex:(NSInteger)idx;
- (void)removeAnimationAtIndex:(NSInteger)idx;

- (void)addAnimation:(MgAnimationNode *)anim;
- (void)removeAnimation:(MgAnimationNode *)anim;

/* Hit-testing. */

- (BOOL)containsPoint:(CGPoint)p;
- (NSSet *)nodesContainingPoint:(CGPoint)p;

/* For subclasses to override. */

- (BOOL)containsPoint:(CGPoint)p layerBounds:(CGRect)r;
- (void)addNodesContainingPoint:(CGPoint)p toSet:(NSMutableSet *)set
    layerBounds:(CGRect)r;

/* Rendering to a CGContext. What can possibly go wrong? */

- (CFTimeInterval)renderInContext:(CGContextRef)ctx;
- (CFTimeInterval)renderInContext:(CGContextRef)ctx atTime:(CFTimeInterval)t;

@end
