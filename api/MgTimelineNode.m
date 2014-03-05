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

#import "MgTimelineNode.h"

#import "MgDrawableNodeInternal.h"
#import "MgNodeInternal.h"
#import "MgTimingStorage.h"

#import <Foundation/Foundation.h>

@implementation MgTimelineNode
{
  MgTimingStorage *_timing;
  MgDrawableNode *_node;
}

+ (BOOL)automaticallyNotifiesObserversOfBegin
{
  return NO;
}

- (CFTimeInterval)begin
{
  return _timing != nil ? _timing.begin : 0;
}

- (void)setBegin:(CFTimeInterval)t
{
  if (_timing == nil && t != 0)
    _timing = [[MgTimingStorage alloc] init];

  if (_timing.begin != t)
    {
      [self willChangeValueForKey:@"begin"];
      _timing.begin = t;
      [self incrementVersion];
      [self didChangeValueForKey:@"begin"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfDuration
{
  return NO;
}

- (CFTimeInterval)duration
{
  return _timing != nil ? _timing.duration : 0;
}

- (void)setDuration:(CFTimeInterval)t
{
  if (_timing == nil && t != HUGE_VAL)
    _timing = [[MgTimingStorage alloc] init];

  if (_timing.duration != t)
    {
      [self willChangeValueForKey:@"duration"];
      _timing.duration = t;
      [self incrementVersion];
      [self didChangeValueForKey:@"duration"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfSpeed
{
  return NO;
}

- (double)speed
{
  return _timing != nil ? _timing.speed : 0;
}

- (void)setSpeed:(double)t
{
  if (_timing == nil && t != 1)
    _timing = [[MgTimingStorage alloc] init];

  if (_timing.speed != t)
    {
      [self willChangeValueForKey:@"speed"];
      _timing.speed = t;
      [self incrementVersion];
      [self didChangeValueForKey:@"speed"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfOffset
{
  return NO;
}

- (CFTimeInterval)offset
{
  return _timing != nil ? _timing.offset : 0;
}

- (void)setOffset:(CFTimeInterval)t
{
  if (_timing == nil && t != 0)
    _timing = [[MgTimingStorage alloc] init];

  if (_timing.offset != t)
    {
      [self willChangeValueForKey:@"offset"];
      _timing.offset = t;
      [self incrementVersion];
      [self didChangeValueForKey:@"offset"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfRepeat
{
  return NO;
}

- (double)repeat
{
  return _timing != nil ? _timing.repeat : 0;
}

- (void)setRepeat:(double)t
{
  if (_timing == nil && t != 1)
    _timing = [[MgTimingStorage alloc] init];

  if (_timing.repeat != t)
    {
      [self willChangeValueForKey:@"repeat"];
      _timing.repeat = t;
      [self incrementVersion];
      [self didChangeValueForKey:@"repeat"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfAutoreverses
{
  return NO;
}

- (BOOL)autoreverses
{
  return _timing != nil ? _timing.autoreverses : NO;
}

- (void)setAutoreverses:(BOOL)flag
{
  if (_timing == nil && flag)
    _timing = [[MgTimingStorage alloc] init];

  if (_timing.autoreverses != flag)
    {
      [self willChangeValueForKey:@"autoreverses"];
      _timing.autoreverses = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"autoreverses"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfHoldsBeforeStart
{
  return NO;
}

- (BOOL)holdsBeforeStart
{
  return _timing != nil ? _timing.holdsBeforeStart : NO;
}

- (void)setHoldsBeforeStart:(BOOL)flag
{
  if (_timing == nil && flag)
    _timing = [[MgTimingStorage alloc] init];

  if (_timing.holdsBeforeStart != flag)
    {
      [self willChangeValueForKey:@"holdsBeforeStart"];
      _timing.holdsBeforeStart = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"holdsBeforeStart"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfHoldsAfterEnd
{
  return NO;
}

- (BOOL)holdsAfterEnd
{
  return _timing != nil ? _timing.holdsAfterEnd : NO;
}

- (void)setHoldsAfterEnd:(BOOL)flag
{
  if (_timing == nil && flag)
    _timing = [[MgTimingStorage alloc] init];

  if (_timing.holdsAfterEnd != flag)
    {
      [self willChangeValueForKey:@"holdsAfterEnd"];
      _timing.holdsAfterEnd = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"holdsAfterEnd"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfNode
{
  return NO;
}

- (MgDrawableNode *)node
{
  return _node;
}

- (void)setNode:(MgDrawableNode *)node
{
  if (_node != node)
    {
      [self willChangeValueForKey:@"node"];
      [_node removeReference:self];
      _node = node;
      [_node addReference:self];
      [self incrementVersion];
      [self didChangeValueForKey:@"node"];
    }
}

- (void)foreachNode:(void (^)(MgNode *node))block
{
  if (_node != nil)
    block(_node);

  [super foreachNode:block];
}

- (BOOL)containsPoint:(CGPoint)p layerNode:(MgLayerNode *)node
{
  return [_node containsPoint:p layerNode:node];
}

- (void)addNodesContainingPoint:(CGPoint)p toSet:(NSMutableSet *)set
    layerNode:(MgLayerNode *)node
{
  [_node addNodesContainingPoint:p toSet:set layerNode:node];
}

- (void)_renderWithState:(MgDrawableRenderState *)rs
{
  if (_node == nil)
    return;

  MgDrawableRenderState r = *rs;
  r.t = _timing != nil ? [_timing applyToTime:rs->t] : rs->t;
  r.tnext = HUGE_VAL;

  [_node _renderWithState:&r];

  if (r.tnext < rs->tnext)
    rs->tnext = r.tnext;
}

- (void)_renderMaskWithState:(MgDrawableRenderState *)rs
{
  MgDrawableRenderState r = *rs;
  r.t = _timing != nil ? [_timing applyToTime:rs->t] : rs->t;
  r.tnext = HUGE_VAL;

  [_node _renderMaskWithState:&r];

  if (r.tnext < rs->tnext)
    rs->tnext = r.tnext;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgTimelineNode *copy = [super copyWithZone:zone];

  if (_timing != nil)
    copy->_timing = [_timing copy];

  copy->_node = _node;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  /* Don't encode MgTimingStorage as its own object, embed its values
     in this classes (in case we want to change the implementation in
     the future). */

  if (_timing != nil)
    {
      [c encodeBool:YES forKey:@"_hasTiming"];
      [_timing encodeWithCoder:c];
    }

  if (_node != nil)
    [c encodeObject:_node forKey:@"node"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c decodeBoolForKey:@"_hasTiming"])
    {
      _timing = [[MgTimingStorage alloc] init];
      [_timing decodeWithCoder:c];
    }

  if ([c containsValueForKey:@"node"])
    _node = [c decodeObjectOfClass:[MgDrawableNode class] forKey:@"node"];

  return self;
}

@end
