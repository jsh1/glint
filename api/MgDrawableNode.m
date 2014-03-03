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
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgDrawableNode
{
  BOOL _hidden;
  NSMutableArray *_animations;
}

- (void)dealloc
{
  for (MgAnimationNode *anim in _animations)
    [anim removeReference:self];
}

+ (BOOL)automaticallyNotifiesObserversOfHidden
{
  return NO;
}

- (BOOL)hidden
{
  return _hidden;
}

- (void)setHidden:(BOOL)flag
{
  if (_hidden != flag)
    {
      [self willChangeValueForKey:@"hidden"];
      _hidden = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"hidden"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfAnimations
{
  return NO;
}

- (NSArray *)animations
{
  return _animations != nil ? _animations : [NSArray array];
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
  [super foreachNode:block];

  for (MgAnimationNode *anim in _animations)
    block(anim);
}

- (NSArray *)nodesContainingPoint:(CGPoint)p
{
  return [self nodesContainingPoint:p layerBounds:CGRectNull];
}

- (NSArray *)nodesContainingPoint:(CGPoint)p layerBounds:(CGRect)r
{
  return [NSArray array];
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
  rs.bounds = CGRectNull;
  rs.cornerRadius = 0;
  rs.alpha = 1;

  [self renderWithState:&rs];

  return rs.tnext;
}

- (void)renderWithState:(MgDrawableRenderState *)rs
{
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgDrawableNode *copy = [super copyWithZone:zone];

  copy->_hidden = _hidden;

  for (MgAnimationNode *anim in self.animations)
    [copy addAnimation:[anim copyWithZone:zone]];

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_hidden)
    [c encodeBool:_hidden forKey:@"hidden"];

  if (_animations != nil)
    [c encodeObject:_animations forKey:@"animations"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"hidden"])
    _hidden = [c decodeBoolForKey:@"hidden"];

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
