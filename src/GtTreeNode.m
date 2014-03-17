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

- (BOOL)isRoot
{
  return self.parent == nil;
}

- (BOOL)isLeaf
{
  return [self.children count] == 0;
}

- (void)updateChildren
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

	  if (node != nil)
	    {
	      node->_parentIndex = parentIndex;
	      node->_parentKey = [parentKey copy];
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
}

- (NSArray *)children
{
  [self updateChildren];
  return _children != nil ? _children : @[];
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

- (GtTreeNode *)containingGroup
{
  for (GtTreeNode *n = self.parent; n != nil; n = n.parent)
    {
      if ([n.node isKindOfClass:[MgGroupLayer class]])
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

static size_t
tree_depth(GtTreeNode *tn)
{
  size_t depth = 0;
  while (tn != nil)
    tn = tn->_parent, depth++;
  return depth;
}

- (GtTreeNode *)ancestorSharedWith:(GtTreeNode *)n2
{
  GtTreeNode *n1 = self;

  if (n1 == nil)
    return n2;
  if (n2 == nil)
    return n1;
  if (n1 == n2)
    return n1;

  size_t n1_depth = tree_depth(n1);
  size_t n2_depth = tree_depth(n2);

  while (n1_depth > n2_depth)
    n1 = n1->_parent, n1_depth--;
  while (n2_depth > n1_depth)
    n2 = n2->_parent, n2_depth--;

  while (n1 != n2)
    {
      n1 = n1->_parent;
      n2 = n2->_parent;
    }

  return n1;
}

- (CGAffineTransform)rootTransform
{
  CGAffineTransform m = CGAffineTransformIdentity;

  for (GtTreeNode *n = self; n != nil; n = n.parent)
    {
      MgLayer *layer = (MgLayer *)n.node;

      if ([layer isKindOfClass:[MgLayer class]])
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
  return [(MgLayer *)_node containsPoint:p];
}

- (GtTreeNode *)hitTest:(CGPoint)p
{
  if (![_node isKindOfClass:[MgLayer class]])
    return nil;

  MgLayer *layer = (MgLayer *)_node;

  CGPoint node_p = [layer convertPointFromParent:p];

  NSArray *children = self.children;
  NSInteger count = [children count];

  for (NSInteger i = count - 1; i >= 0; i--)
    {
      GtTreeNode *node = children[i];
      GtTreeNode *hit = [node hitTest:node_p];
      if (hit != nil)
	return hit;
    }

  if (!self.root && [layer containsPoint:p])
    return self;

  return nil;
}

@end
