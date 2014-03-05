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

#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>

#import "MgMacros.h"

#if !__has_feature(objc_arc)
# error Requires Objective C ARC enabled.
#endif

static NSUInteger version_counter;

@implementation MgNode
{
  NSString *_name;
  NSPointerArray *_references;
  NSUInteger _version;
  uint32_t _mark;			/* for graph traversal */
  BOOL _enabled;
}

+ (instancetype)node
{
  return [[self alloc] init];
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _enabled = YES;
  _version = 1;

  return self;
}

+ (BOOL)automaticallyNotifiesObserversOfEnabled
{
  return NO;
}

- (BOOL)enabled
{
  return _enabled;
}

- (void)setEnabled:(BOOL)flag
{
  if (_enabled != flag)
    {
      [self willChangeValueForKey:@"enabled"];
      _enabled = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"enabled"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfName
{
  return NO;
}

- (NSString *)name
{
  return _name;
}

- (void)setName:(NSString *)str
{
  if (![_name isEqual:str])
    {
      [self willChangeValueForKey:@"name"];
      _name = [str copy];
      [self incrementVersion];
      [self didChangeValueForKey:@"name"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfVersion
{
  return NO;
}

- (NSUInteger)version
{
  return _version;
}

- (void)setVersion:(NSUInteger)x
{
  if (_version < x)
    {
      [self willChangeValueForKey:@"version"];
      _version = x;
      [self didChangeValueForKey:@"version"];

      for (MgNode *ref in _references)
	ref.version = x;
    }
}

- (void)incrementVersion
{
#if NSUIntegerMax == UINT64_MAX
  self.version = OSAtomicIncrement64((int64_t *)&version_counter);
#else
  self.version = OSAtomicIncrement32((int32_t *)&version_counter);
#endif
}

+ (BOOL)automaticallyNotifiesObserversOfReferences
{
  return NO;
}

- (NSPointerArray *)references
{
  return _references;
}

- (void)addReference:(MgNode *)node
{
  NSPointerArray *array = _references;
  if (array == nil)
    array = _references = [NSPointerArray weakObjectsPointerArray];
  else
    [array compact];

  [self willChangeValueForKey:@"references"];

  [array addPointer:(__bridge void *)node];

  /* A node's version must be no less than that any of the objects it
     refers to. */

  node.version = self.version;

  [self didChangeValueForKey:@"references"];
}

- (void)removeReference:(MgNode *)node
{
  NSPointerArray *array = _references;

  NSInteger idx = 0;
  for (id ptr in array)
    {
      if (ptr == node)
	break;
      idx++;
    }

  if (idx < [array count])
    {
      [self willChangeValueForKey:@"references"];
      [array removePointerAtIndex:idx];
      [self didChangeValueForKey:@"references"];
    }
}

struct foreach_node
{
  struct foreach_node *next;
  size_t len;
  __unsafe_unretained MgNode *node;
};

static void
foreach_path_to_node(MgNode *node, MgNode *root, bool reversed,
		     struct foreach_node *lst, void (^block)(NSArray *p))
{
  /* Cons 'node' onto 'lst' for the lifetime of this stack frame. */

  struct foreach_node n = {lst, lst ? lst->len + 1 : 1, node};
  lst = &n;

  if (root != nil ? (node == root) : ([node->_references count] == 0))
    {
      /* 'lst' is in order from root to self. */

      size_t count = lst->len;
      __unsafe_unretained id *objects = STACK_ALLOC(id, count);

      if (objects != nil)
	{
	  for (size_t i = 0; lst != NULL; i++, lst = lst->next)
	    objects[reversed ? i : (count - i - 1)] = lst->node;

	  block([NSArray arrayWithObjects:objects count:count]);

	  STACK_FREE(id, count, objects);
	}
    }
  else
    {
      for (id ptr in node->_references)
	foreach_path_to_node(ptr, root, reversed, lst, block);
    }
}

- (void)foreachPathToNode:(MgNode *)root handler:(void (^)(NSArray *p))block;
{
  foreach_path_to_node(self, root, false, NULL, block);
}

- (void)foreachPathFromNode:(MgNode *)root handler:(void (^)(NSArray *p))block;
{
  foreach_path_to_node(self, root, true, NULL, block);
}

- (void)foreachNode:(void (^)(MgNode *node))block
{
}

- (void)foreachNode:(void (^)(MgNode *node))block mark:(uint32_t)mark
{
  if (_mark != mark)
    {
      _mark = mark;
      [self foreachNode:block];
    }
}

+ (uint32_t)nextMark
{
  static int32_t counter;

  return OSAtomicIncrement32(&counter);
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgNode *copy = [[[self class] alloc] init];

  copy->_enabled = _enabled;

  return copy;
}

/** NSSecureCoding methods. **/

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)c
{
  if (!_enabled)
    [c encodeBool:_enabled forKey:@"enabled"];

  if (_name != nil)
    [c encodeObject:_name forKey:@"name"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [self init];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"enabled"])
    _enabled = [c decodeBoolForKey:@"enabled"];
  else
    _enabled = YES;

  if ([c containsValueForKey:@"name"])
    _name = [[c decodeObjectOfClass:[NSString class] forKey:@"name"] copy];

  return self;
}

@end
