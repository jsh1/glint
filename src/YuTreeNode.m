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
	    node = [[YuTreeNode alloc] initWithNode:child parent:node];

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

@end
