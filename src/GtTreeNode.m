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

#import "GtTreeNode.h"

@implementation GtTreeNode
{
  MgNode *_node;
  __weak GtTreeNode *_parent;
  NSString *_parentKey;
  NSInteger _parentIndex;
  NSArray *_children;
  NSInteger _childrenVersion;
}

@synthesize node = _node;
@synthesize parent = _parent;
@synthesize parentKey = _parentKey;
@synthesize parentIndex = _parentIndex;

- (id)initWithNode:(MgNode *)node parent:(GtTreeNode *)parent
    parentKey:(NSString *)key parentIndex:(NSInteger)idx
{
  self = [super init];
  if (self == nil)
    return nil;

  _node = node;
  _parent = parent;
  _parentKey = [key copy];
  _parentIndex = idx;

  return self;
}

- (NSArray *)children
{
  if (_childrenVersion != _node.version)
    {
      NSMutableArray *children = [NSMutableArray array];

      NSMapTable *map = nil;
      if (_children != nil)
	{
	  map = [NSMapTable strongToStrongObjectsMapTable];
	  for (GtTreeNode *node in _children)
	    [map setObject:node forKey:node->_node];
	}

      [_node foreachNodeAndAttachmentInfo:^
        (MgNode *child, NSString *parentKey, NSInteger parentIndex)
        {
	  GtTreeNode *node = [map objectForKey:child];

	  if (node != nil
	      && node.parentIndex == parentIndex
	      && [node.parentKey isEqualToString:parentKey])
	    {
	      [map removeObjectForKey:child];
	    }
	  else
	    {
	      node = [[GtTreeNode alloc] initWithNode:child parent:self
		      parentKey:parentKey parentIndex:parentIndex];
	    }

	  [children addObject:node];
	}];

      _children = children;
      _childrenVersion = _node.version;
    }

  return _children != nil ? _children : @[];
}

- (BOOL)isLeaf
{
  return [self.children count] == 0;
}

- (BOOL)foreachNode:(void (^)(GtTreeNode *node, BOOL *stop))thunk
{
  BOOL stop = NO;
  thunk(self, &stop);
  if (stop)
    return NO;

  for (GtTreeNode *node in self.children)
    {
      if (![node foreachNode:thunk])
	return NO;
    }

  return YES;
}

- (GtTreeNode *)containingLayer
{
  for (GtTreeNode *n = self.parent; n != nil; n = n.parent)
    {
      if ([n.node isKindOfClass:[MgLayerNode class]])
	return n;
    }

  return nil;
}

- (BOOL)isDescendantOf:(GtTreeNode *)tn
{
  for (GtTreeNode *n = self; n != nil; n = n.parent)
    {
      if (n == tn)
	return YES;
    }

  return NO;
}

- (CGAffineTransform)rootTransform
{
  CGAffineTransform m = CGAffineTransformIdentity;

  for (GtTreeNode *n = self; n != nil; n = n.parent)
    {
      MgLayerNode *layer = (MgLayerNode *)n.node;

      if ([layer isKindOfClass:[MgLayerNode class]])
	m = CGAffineTransformConcat(m, [layer parentTransform]);
    }

  return m;
}

- (CGPoint)convertPointToRoot:(CGPoint)p
{
  CGAffineTransform m = [self rootTransform];
  return CGPointApplyAffineTransform(p, m);
}

- (CGPoint)convertPointFromRoot:(CGPoint)p
{
  CGAffineTransform m = [self rootTransform];
  return CGPointApplyAffineTransform(p, CGAffineTransformInvert(m));
}

- (BOOL)containsPoint:(CGPoint)p
{
  GtTreeNode *layer = [self containingLayer];

  return [(MgDrawableNode *)_node containsPoint:p layerNode:(MgLayerNode *)layer.node];
}

- (GtTreeNode *)hitTest:(CGPoint)p
{
  return [self hitTest:p layer:nil];
}

- (GtTreeNode *)hitTest:(CGPoint)p layer:(GtTreeNode *)layer
{
  if (![_node isKindOfClass:[MgDrawableNode class]])
    return nil;

  MgDrawableNode *drawable = (MgDrawableNode *)_node;

  CGPoint node_p = [drawable convertPointFromParent:p];
  GtTreeNode *node_layer = ([drawable isKindOfClass:[MgLayerNode class]]
			    ? self : layer);

  NSArray *children = self.children;
  NSInteger count = [children count];

  for (NSInteger i = count - 1; i >= 0; i--)
    {
      GtTreeNode *node = children[i];
      GtTreeNode *hit = [node hitTest:node_p layer:node_layer];
      if (hit != nil)
	return hit;
    }

  if ([drawable containsPoint:p layerNode:(MgLayerNode *)layer.node])
    return self;

  return nil;
}

@end
