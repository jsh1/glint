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

@property(nonatomic, assign) float alpha;
@property(nonatomic, assign) CGBlendMode blendMode;

/* Array of animations attached to this node. */

@property(nonatomic, copy) NSArray *animations;

- (void)insertAnimation:(MgAnimationNode *)anim atIndex:(NSInteger)idx;
- (void)removeAnimationAtIndex:(NSInteger)idx;

- (void)addAnimation:(MgAnimationNode *)anim;
- (void)removeAnimation:(MgAnimationNode *)anim;

/* Returns the new point created by mapping 'p' either into or out of
   the coordinate space containing the receiver. */

- (CGPoint)convertPointToParent:(CGPoint)p;
- (CGPoint)convertPointFromParent:(CGPoint)p;

/* Hit-testing. Does a depth-first search from top-to-bottom finding
   the deepest node that contains point 'p'. Point 'p' is defined in
   the coordinate space containing the receiver. */

- (MgDrawableNode *)hitTest:(CGPoint)p;

/* Returns true if the receiver or any of its descendants contain point
   'p'. Point 'p' is defined in the coordinate space containing the
   receiver. */

- (BOOL)containsPoint:(CGPoint)p;

/* Returns all nodes in the subgraph defined by the receiver that
   contain point 'p'. Point 'p' is defined in the coordinate space
   containing the receiver. */

- (NSSet *)nodesContainingPoint:(CGPoint)p;

/* Versions that allow the containing layer to be passed in. These are
   what subclasses should override. The corresponding methods above all
   call these methods with 'node' as a null pointer. */

- (MgDrawableNode *)hitTest:(CGPoint)p layerNode:(MgLayerNode *)node;
- (BOOL)containsPoint:(CGPoint)p layerNode:(MgLayerNode *)node;
- (void)addNodesContainingPoint:(CGPoint)p toSet:(NSMutableSet *)set
    layerNode:(MgLayerNode *)node;

/* Rendering to a CGContext. What can possibly go wrong? */

- (CFTimeInterval)renderInContext:(CGContextRef)ctx;
- (CFTimeInterval)renderInContext:(CGContextRef)ctx atTime:(CFTimeInterval)t;

@end
