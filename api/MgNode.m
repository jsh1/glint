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

static NSUInteger version_counter;

@implementation MgNode
{
  NSPointerArray *_references;
  NSUInteger _version;
  uint32_t _mark;			/* for graph traversal */
}

- (void)incrementVersion
{
#if NSUIntegerMax == UINT64_MAX
  self.version = OSAtomicIncrement64((int64_t *)&version_counter);
#else
  self.version = OSAtomicIncrement32((int32_t *)&version_counter);
#endif
}

- (NSUInteger)version
{
  return _version;
}

- (void)setVersion:(NSUInteger)x
{
  if (_version < x)
    {
      _version = x;

      for (MgNode *ref in _references)
	ref.version = x;
    }
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

  assert (array != nil);

  NSInteger idx = 0;
  for (id ptr in array)
    {
      if (ptr == node)
	break;
      idx++;
    }

  assert (idx < [array count]);

  [self willChangeValueForKey:@"references"];

  [array removePointerAtIndex:idx];

  [self didChangeValueForKey:@"references"];
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

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  return [[[self class] alloc] init];
}

/** NSSecureCoding methods. **/

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)c
{
}

- (id)initWithCoder:(NSCoder *)c
{
  return [self init];
}

@end
