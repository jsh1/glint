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
#import "MgLayerInternal.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgGroupLayer
{
  BOOL _group;
  NSMutableArray *_contents;
}

+ (BOOL)automaticallyNotifiesObserversOfGroup
{
  return NO;
}

- (BOOL)group
{
  return _group;
}

- (void)setGroup:(BOOL)flag
{
  if (_group != flag)
    {
      [self willChangeValueForKey:@"group"];
      _group = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"group"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfContents
{
  return NO;
}

- (NSArray *)contents
{
  return _contents != nil ? _contents : @[];
}

- (void)setContents:(NSArray *)array
{
  if (_contents != array && ![_contents isEqual:array])
    {
      [self willChangeValueForKey:@"contents"];

      for (MgLayer *node in _contents)
	[node removeReference:self];

      _contents = [array copy];

      for (MgLayer *node in _contents)
	[node addReference:self];

      [self incrementVersion];
      [self didChangeValueForKey:@"contents"];
    }
}

- (void)addContent:(MgLayer *)node
{
  [self insertContent:node atIndex:NSIntegerMax];
}

- (void)removeContent:(MgLayer *)node
{
  while (true)
    {
      NSInteger idx = [_contents indexOfObjectIdenticalTo:node];
      if (idx == NSNotFound)
	break;

      [self removeContentAtIndex:idx];
    }
}

- (void)insertContent:(MgLayer *)node atIndex:(NSInteger)idx
{
  if (_contents == nil)
    _contents = [[NSMutableArray alloc] init];

  if (idx > [_contents count])
    idx = [_contents count];

  [self willChangeValueForKey:@"contents"];

  [_contents insertObject:node atIndex:idx];
  [node addReference:self];

  [self incrementVersion];
  [self didChangeValueForKey:@"contents"];
}

- (void)removeContentAtIndex:(NSInteger)idx
{
  if (idx < [_contents count])
    {
      [self willChangeValueForKey:@"contents"];

      [_contents[idx] removeReference:self];
      [_contents removeObjectAtIndex:idx];

      [self incrementVersion];
      [self didChangeValueForKey:@"contents"];
    }
}

- (void)foreachNode:(void (^)(MgNode *node))block
{
  for (MgLayer *node in _contents)
    block(node);

  [super foreachNode:block];
}

- (void)foreachNodeAndAttachmentInfo:(void (^)(MgNode *node,
    NSString *parentKey, NSInteger parentIndex))block
{
  NSArray *array = _contents;
  NSInteger count = [array count];

  for (NSInteger i = 0; i < count; i++)
    block(array[i], @"contents", i);

  [super foreachNodeAndAttachmentInfo:block];
}

- (BOOL)contentContainsPoint:(CGPoint)lp
{
  NSArray *array = self.contents;
  NSInteger count = [array count];

  for (NSInteger i = count - 1; i >= 0; i--)
    {
      MgLayer *node = array[i];
      if ([node containsPoint:lp])
	return YES;
    }

  return NO;
}

- (MgLayer *)hitTestContent:(CGPoint)lp
{
  for (MgLayer *node in self.contents)
    {
      MgLayer *hit = [node hitTest:lp];
      if (hit != nil)
	return hit;
    }

  return nil;
}

/** Rendering. **/

- (void)_renderLayerWithState:(MgLayerRenderState *)rs
{
  if ([self.contents count] == 0)
    return;

  BOOL group = self.group;

  MgLayerRenderState r = *rs;
  r.alpha = group ? 1 : rs->alpha;

  if (group)
    {
      CGContextSaveGState(r.ctx);
      CGContextBeginTransparencyLayer(r.ctx, NULL);
    }

  for (MgLayer *node in self.contents)
    {
      if (node.enabled)
	[node _renderWithState:&r];
    }

  if (group)
    {
      CGContextEndTransparencyLayer(r.ctx);
      CGContextRestoreGState(r.ctx);
    }

  rs->tnext = r.tnext;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgGroupLayer *copy = [super copyWithZone:zone];

  copy->_group = _group;

  if ([_contents count] != 0)
    {
      for (MgLayer *node in _contents)
	[node addReference:copy];

      copy->_contents = [_contents copy];
    }

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_group)
    [c encodeBool:_group forKey:@"group"];

  if ([_contents count] != 0)
    [c encodeObject:_contents forKey:@"contents"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"group"])
    _group = [c decodeBoolForKey:@"group"];

  if ([c containsValueForKey:@"contents"])
    {
      NSArray *array = [c decodeObjectOfClass:[NSArray class]
			forKey:@"contents"];

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
	  _contents = [array copy];

	  for (MgLayer *node in _contents)
	    [node addReference:self];
	}
    }

  return self;
}

@end
