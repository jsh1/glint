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

#import "MgDrawableNodeInternal.h"

#import "MgAnimationNode.h"
#import "MgLayerNode.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgDrawableNode
{
  float _alpha;
  CGBlendMode _blendMode;
  NSMutableArray *_animations;
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _alpha = 1;
  _blendMode = kCGBlendModeNormal;

  return self;
}

+ (BOOL)automaticallyNotifiesObserversOfAlpha
{
  return NO;
}

- (float)alpha
{
  return _alpha;
}

- (void)setAlpha:(float)x
{
  if (_alpha != x)
    {
      [self willChangeValueForKey:@"alpha"];
      _alpha = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"alpha"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfBlendMode
{
  return NO;
}

- (CGBlendMode)blendMode
{
  return _blendMode;
}

- (void)setBlendMode:(CGBlendMode)x
{
  if (_blendMode != x)
    {
      [self willChangeValueForKey:@"blendMode"];
      _blendMode = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"blendMode"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfAnimations
{
  return NO;
}

- (NSArray *)animations
{
  return _animations != nil ? _animations : @[];
}

- (void)setAnimations:(NSArray *)array
{
  if (_animations != array)
    {
      [self willChangeValueForKey:@"animations"];

      for (MgAnimationNode *anim in _animations)
	[anim removeReference:self];

      _animations = [array mutableCopy];

      for (MgAnimationNode *anim in _animations)
	[anim addReference:self];

      [self incrementVersion];
      [self didChangeValueForKey:@"animations"];
    }
}

- (void)insertAnimation:(MgAnimationNode *)anim atIndex:(NSInteger)idx
{
  if (_animations == nil)
    _animations = [[NSMutableArray alloc] init];

  if ([_animations indexOfObjectIdenticalTo:anim] == NSNotFound)
    {
      [self willChangeValueForKey:@"animations"];

      if (idx > [_animations count])
	idx = [_animations count];

      [_animations insertObject:anim atIndex:idx];
      [anim addReference:self];

      [self incrementVersion];
      [self didChangeValueForKey:@"animations"];
    }
}

- (void)removeAnimationAtIndex:(NSInteger)idx
{
  if (idx < [_animations count])
    {
      [self willChangeValueForKey:@"animations"];

      [_animations[idx] removeReference:self];
      [_animations removeObjectAtIndex:idx];

      [self incrementVersion];
      [self didChangeValueForKey:@"animations"];
    }
}

- (void)addAnimation:(MgAnimationNode *)anim
{
  [self insertAnimation:anim atIndex:NSIntegerMax];
}

- (void)removeAnimation:(MgAnimationNode *)anim
{
  while (true)
    {
      NSInteger idx = [_animations indexOfObjectIdenticalTo:anim];
      if (idx == NSNotFound)
	break;

      [self removeAnimationAtIndex:idx];
    }
}

- (void)foreachNode:(void (^)(MgNode *node))block
{
  for (MgAnimationNode *anim in _animations)
    block(anim);

  [super foreachNode:block];
}

- (void)foreachNodeAndAttachmentInfo:(void (^)(MgNode *node,
    NSString *parentKey, NSInteger parentIndex))block
{
  NSArray *array = _animations;
  NSInteger count = [array count];

  for (NSInteger i = 0; i < count; i++)
    block(array[i], @"animations", i);

  [super foreachNodeAndAttachmentInfo:block];
}

- (CGPoint)convertPointToParent:(CGPoint)p
{
  return p;
}

- (CGPoint)convertPointFromParent:(CGPoint)p
{
  return p;
}

- (MgDrawableNode *)hitTest:(CGPoint)p
{
  return [self hitTest:p layerNode:nil];
}

- (MgDrawableNode *)hitTest:(CGPoint)p layerNode:(MgLayerNode *)node
{
  if ([self containsPoint:p layerNode:node])
    return self;
  else
    return nil;
}

- (BOOL)containsPoint:(CGPoint)p
{
  return [self containsPoint:p layerNode:nil];
}

- (BOOL)containsPoint:(CGPoint)p layerNode:(MgLayerNode *)node
{
  return CGRectContainsPoint(node.bounds, p);
}

- (NSSet *)nodesContainingPoint:(CGPoint)p
{
  NSMutableSet *set = [[NSMutableSet alloc] init];
  [self addNodesContainingPoint:p toSet:set layerNode:nil];
  return set;
}

- (void)addNodesContainingPoint:(CGPoint)p toSet:(NSMutableSet *)set
    layerNode:(MgLayerNode *)node
{
  if (![set containsObject:self] && [self containsPoint:p layerNode:node])
    [set addObject:self];
}

- (CFTimeInterval)renderInContext:(CGContextRef)ctx
{
  return [self renderInContext:ctx atTime:CACurrentMediaTime()];
}

- (CFTimeInterval)renderInContext:(CGContextRef)ctx atTime:(CFTimeInterval)t
{
  MgDrawableRenderState rs;
  rs.ctx = ctx;
  rs.t = t;
  rs.tnext = HUGE_VAL;
  rs.layer = nil;
  rs.alpha = 1;

  [self _renderWithState:&rs];

  return rs.tnext;
}

- (void)_renderWithState:(MgDrawableRenderState *)rs
{
}

- (void)_renderMaskWithState:(MgDrawableRenderState *)rs
{
  /* FIXME: implement this in terms of -_renderWithState: */
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgDrawableNode *copy = [super copyWithZone:zone];

  copy->_alpha = _alpha;
  copy->_blendMode = _blendMode;

  for (MgAnimationNode *anim in self.animations)
    [copy addAnimation:[anim copyWithZone:zone]];

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_alpha != 1)
    [c encodeFloat:_alpha forKey:@"alpha"];

  if (_blendMode != kCGBlendModeNormal)
    [c encodeInt:_blendMode forKey:@"blendMode"];

  if (_animations != nil)
    [c encodeObject:_animations forKey:@"animations"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"alpha"])
    _alpha = [c decodeFloatForKey:@"alpha"];
  else
    _alpha = 1;

  if ([c containsValueForKey:@"blendMode"])
    _blendMode = (CGBlendMode)[c decodeIntForKey:@"blendMode"];
  else
    _blendMode = kCGBlendModeNormal;

  if ([c containsValueForKey:@"animations"])
    {
      NSArray *array = [c decodeObjectOfClass:
			[NSArray class] forKey:@"animations"];
      for (id obj in array)
	{
	  if ([obj isKindOfClass:[MgAnimationNode class]])
	    [self addAnimation:obj];
	}
    }

  return self;
}

@end
