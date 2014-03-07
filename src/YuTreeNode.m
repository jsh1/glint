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

#import "YuTreeNode.h"

@implementation YuTreeNode
{
  MgNode *_node;
  __weak YuTreeNode *_parent;
  NSArray *_children;
  NSInteger _childrenVersion;
}

- (id)initWithNode:(MgNode *)node parent:(YuTreeNode *)parent
{
  self = [super init];
  if (self == nil)
    return nil;

  _node = node;
  _parent = parent;

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
	  for (YuTreeNode *node in _children)
	    [map setObject:node forKey:node->_node];
	}

      [_node foreachNode:^(MgNode *child)
        {
	  YuTreeNode *node = [map objectForKey:child];

	  if (node != nil)
	    [map removeObjectForKey:child];
	  else
	    node = [[YuTreeNode alloc] initWithNode:child parent:self];

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

- (BOOL)foreachNode:(void (^)(YuTreeNode *node, BOOL *stop))thunk
{
  BOOL stop = NO;
  thunk(self, &stop);
  if (stop)
    return NO;

  for (YuTreeNode *node in self.children)
    {
      if (![node foreachNode:thunk])
	return NO;
    }

  return YES;
}

- (YuTreeNode *)containingLayer
{
  for (YuTreeNode *n = self.parent; n != nil; n = n.parent)
    {
      if ([n.node isKindOfClass:[MgLayerNode class]])
	return n;
    }

  return nil;
}

- (CGAffineTransform)rootTransform
{
  CGAffineTransform m = CGAffineTransformIdentity;

  for (YuTreeNode *n = self; n != nil; n = n.parent)
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
  YuTreeNode *layer = [self containingLayer];

  return [(MgDrawableNode *)_node containsPoint:p layerNode:(MgLayerNode *)layer.node];
}

- (YuTreeNode *)hitTest:(CGPoint)p
{
  return [self hitTest:p layer:nil];
}

- (YuTreeNode *)hitTest:(CGPoint)p layer:(YuTreeNode *)layer
{
  if (![_node isKindOfClass:[MgDrawableNode class]])
    return nil;

  MgDrawableNode *drawable = (MgDrawableNode *)_node;

  CGPoint node_p = [drawable convertPointFromParent:p];
  YuTreeNode *node_layer = ([drawable isKindOfClass:[MgLayerNode class]]
			    ? self : layer);

  NSArray *children = self.children;
  NSInteger count = [children count];

  for (NSInteger i = count - 1; i >= 0; i--)
    {
      YuTreeNode *node = children[i];
      YuTreeNode *hit = [node hitTest:node_p layer:node_layer];
      if (hit != nil)
	return hit;
    }

  if ([drawable containsPoint:p layerNode:(MgLayerNode *)layer.node])
    return self;

  return nil;
}

@end
