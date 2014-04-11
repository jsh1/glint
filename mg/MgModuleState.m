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

#import "MgModuleState.h"

#import "MgNode.h"
#import "MgModuleLayer.h"

#import <Foundation/Foundation.h>

@implementation MgModuleState

+ (instancetype)moduleState
{
  return [[self alloc] init];
}

- (id)init
{
  return [super init];
}

- (BOOL)isDescendantOf:(MgModuleState *)state
{
  for (MgModuleState *s = self; s != nil; s = s.superstate)
    {
      if (s == state)
	return YES;
    }

  return state == nil;
}

static size_t
state_depth(MgModuleState *s)
{
  size_t depth = 0;
  while (s != nil)
    s = s.superstate, depth++;
  return depth;
}

- (MgModuleState *)ancestorSharedWith:(MgModuleState *)s2
{
  MgModuleState *s1 = self;

  if (s1 == nil)
    return s2;
  if (s2 == nil)
    return s1;
  if (s1 == s2)
    return s1;

  size_t s1_depth = state_depth(s1);
  size_t s2_depth = state_depth(s2);

  while (s1_depth > s2_depth)
    s1 = s1.superstate, s1_depth--;
  while (s2_depth > s1_depth)
    s2 = s2.superstate, s2_depth--;

  while (s1 != s2)
    {
      s1 = s1.superstate;
      s2 = s2.superstate;
    }

  return s1;
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgModuleState *copy = [[[self class] alloc] init];

  copy->_name = [_name copy];
  copy->_superstate = [_superstate mg_graphCopy:map];

  return copy;
}

/** NSSecureCoding methods. **/

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)c
{
  if (_name != nil)
    [c encodeObject:_name forKey:@"name"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [self init];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"name"])
    _name = [[c decodeObjectOfClass:[NSString class] forKey:@"name"] copy];

  return self;
}

@end
