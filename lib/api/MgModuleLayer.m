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

#import "MgModuleLayer.h"

#import "MgModuleState.h"
#import "MgNodeInternal.h"
#import "MgNodeState.h"

#import <Foundation/Foundation.h>

@implementation MgModuleLayer
{
  NSMutableArray *_moduleStates;
  MgModuleState *_moduleState;
}

+ (BOOL)automaticallyNotifiesObserversOfModuleStates
{
  return NO;
}

- (NSArray *)moduleStates
{
  return _moduleStates != nil ? _moduleStates : @[];
}

- (void)setModuleStates:(NSArray *)array
{
  if (_moduleStates != array && ![_moduleStates isEqual:array])
    {
      [self willChangeValueForKey:@"moduleStates"];
      _moduleStates = [array copy];
      [self incrementVersion];
      [self didChangeValueForKey:@"moduleStates"];
    }
}

- (void)addModuleState:(MgModuleState *)state
{
  [self insertModuleState:state atIndex:NSIntegerMax];
}

- (void)removeModuleState:(MgModuleState *)state
{
  while (true)
    {
      NSInteger idx = [_moduleStates indexOfObjectIdenticalTo:state];
      if (idx == NSNotFound)
	break;

      [self removeModuleStateAtIndex:idx];
    }
}

- (void)insertModuleState:(MgModuleState *)state atIndex:(NSInteger)idx
{
  if (_moduleStates == nil)
    _moduleStates = [[NSMutableArray alloc] init];

  if (idx > [_moduleStates count])
    idx = [_moduleStates count];

  [self willChangeValueForKey:@"moduleStates"];

  [_moduleStates insertObject:state atIndex:idx];

  [self incrementVersion];
  [self didChangeValueForKey:@"moduleStates"];
}

- (void)removeModuleStateAtIndex:(NSInteger)idx
{
  if (idx < [_moduleStates count])
    {
      [self willChangeValueForKey:@"moduleStates"];

      [_moduleStates removeObjectAtIndex:idx];

      [self incrementVersion];
      [self didChangeValueForKey:@"moduleStates"];
    }
}

- (MgModuleState *)moduleStateWithName:(NSString *)name
{
  for (MgModuleState *state in self.moduleStates)
    {
      NSString *state_name = state.name;
      if (state_name == name || [state_name isEqualToString:name])
	return state;
    }

  return nil;
}

+ (BOOL)automaticallyNotifiesObserversOfModuleState
{
  return NO;
}

- (MgModuleState *)moduleState
{
  return _moduleState;
}

- (void)setModuleState:(MgModuleState *)state
{
  if (_moduleState != state)
    {
      [self willChangeValueForKey:@"moduleState"];
      _moduleState = state;
      [self applyModuleState:state options:@{}];
      [self didChangeValueForKey:@"moduleState"];
    }
}

- (void)applyModuleState:(MgModuleState *)moduleState
    options:(NSDictionary *)dict mark:(uint32_t)mark
{
  /* Do nothing. This represents a new sub-graph with its own state
     tree. */
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  /* Copy our states before calling super, this is so any conditional
     calls to copy the states from our sublayers (which will happen
     within the call to super) will find the copied objects. */

  NSMutableArray *array = [NSMutableArray array];
  for (MgModuleState *state in _moduleStates)
    [array addObject:[state mg_graphCopy:map]];

  MgModuleLayer *copy = [super graphCopy:map];

  copy->_moduleStates = array;
  copy->_moduleState = [_moduleState mg_graphCopy:map];

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_moduleStates != nil)
    [c encodeObject:_moduleStates forKey:@"moduleStates"];

  if (_moduleState != nil)
    [c encodeObject:_moduleState forKey:@"moduleState"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"moduleStates"])
    {
      _moduleStates = [c decodeObjectOfClass:[NSArray class]
		       forKey:@"moduleStates"];
    }

  if ([c containsValueForKey:@"moduleState"])
    {
      _moduleState = [c decodeObjectOfClass:[MgModuleState class]
		      forKey:@"moduleState"];
    }

  return self;
}

@end
