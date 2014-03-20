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

#import "MgGroupLayer.h"

#import "MgCoderExtensions.h"
#import "MgGroupLayerState.h"
#import "MgLayerInternal.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

#define STATE ((MgGroupLayerState *)(self.state))

@implementation MgGroupLayer
{
  NSMutableArray *_sublayers;
}

+ (Class)stateClass
{
  return [MgGroupLayerState class];
}

+ (BOOL)automaticallyNotifiesObserversOfGroup
{
  return NO;
}

- (BOOL)isGroup
{
  return STATE.group;
}

- (void)setGroup:(BOOL)flag
{
  MgGroupLayerState *state = STATE;

  if (state.group != flag)
    {
      [self willChangeValueForKey:@"group"];
      state.group = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"group"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfSublayers
{
  return NO;
}

- (NSArray *)sublayers
{
  return _sublayers != nil ? _sublayers : @[];
}

- (void)setSublayers:(NSArray *)array
{
  if (_sublayers != array && ![_sublayers isEqual:array])
    {
      [self willChangeValueForKey:@"sublayers"];

      for (MgLayer *node in _sublayers)
	[node removeReference:self];

      _sublayers = [array copy];

      for (MgLayer *node in _sublayers)
	[node addReference:self];

      [self incrementVersion];
      [self didChangeValueForKey:@"sublayers"];
    }
}

- (void)addSublayer:(MgLayer *)node
{
  [self insertSublayer:node atIndex:NSIntegerMax];
}

- (void)removeSublayer:(MgLayer *)node
{
  while (true)
    {
      NSInteger idx = [_sublayers indexOfObjectIdenticalTo:node];
      if (idx == NSNotFound)
	break;

      [self removeSublayerAtIndex:idx];
    }
}

- (void)insertSublayer:(MgLayer *)node atIndex:(NSInteger)idx
{
  if (_sublayers == nil)
    _sublayers = [[NSMutableArray alloc] init];

  if (idx > [_sublayers count])
    idx = [_sublayers count];

  [self willChangeValueForKey:@"sublayers"];

  [_sublayers insertObject:node atIndex:idx];
  [node addReference:self];

  [self incrementVersion];
  [self didChangeValueForKey:@"sublayers"];
}

- (void)removeSublayerAtIndex:(NSInteger)idx
{
  if (idx < [_sublayers count])
    {
      [self willChangeValueForKey:@"sublayers"];

      [_sublayers[idx] removeReference:self];
      [_sublayers removeObjectAtIndex:idx];

      [self incrementVersion];
      [self didChangeValueForKey:@"sublayers"];
    }
}

- (void)foreachNode:(void (^)(MgNode *node))block
{
  for (MgLayer *node in _sublayers)
    block(node);

  [super foreachNode:block];
}

- (void)foreachNodeAndAttachmentInfo:(void (^)(MgNode *node,
    NSString *parentKey, NSInteger parentIndex))block
{
  NSArray *array = _sublayers;
  NSInteger count = [array count];

  for (NSInteger i = 0; i < count; i++)
    block(array[i], @"sublayers", i);

  [super foreachNodeAndAttachmentInfo:block];
}

- (BOOL)contentContainsPoint:(CGPoint)lp
{
  NSArray *array = self.sublayers;
  NSInteger count = [array count];

  for (NSInteger i = count - 1; i >= 0; i--)
    {
      MgLayer *node = array[i];
      if ([node containsPoint:lp])
	return YES;
    }

  return NO;
}

/** Rendering. **/

- (void)_renderLayerWithState:(MgLayerRenderState *)rs
{
  if ([self.sublayers count] == 0)
    return;

  BOOL group = self.group;

  MgLayerRenderState r = *rs;
  r.alpha = group ? 1 : rs->alpha;

  if (group)
    {
      CGContextSaveGState(r.ctx);
      CGContextBeginTransparencyLayer(r.ctx, NULL);
    }

  for (MgLayer *node in self.sublayers)
    {
      if (node.enabled)
	[node _renderWithState:&r];
    }

  if (group)
    {
      CGContextEndTransparencyLayer(r.ctx);
      CGContextRestoreGState(r.ctx);
    }
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgGroupLayer *copy = [super copyWithZone:zone];

  if ([_sublayers count] != 0)
    {
      for (MgLayer *node in _sublayers)
	[node addReference:copy];

      copy->_sublayers = [_sublayers copy];
    }

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if ([_sublayers count] != 0)
    [c encodeObject:_sublayers forKey:@"sublayers"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"sublayers"])
    {
      NSArray *array = [c decodeObjectOfClass:[NSArray class]
			forKey:@"sublayers"];

      BOOL valid = YES;
      for (id obj in array)
	{
	  if (![obj isKindOfClass:[MgLayer class]])
	    {
	      valid = NO;
	      break;
	    }
	}

      if (valid)
	{
	  _sublayers = [array copy];

	  for (MgLayer *node in _sublayers)
	    [node addReference:self];
	}
    }

  return self;
}

@end
