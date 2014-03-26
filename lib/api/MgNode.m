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

#import "MgNodeState.h"
#import "MgModuleState.h"

#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>

#import "MgMacros.h"

#if !__has_feature(objc_arc)
# error Requires Objective C ARC enabled.
#endif

NSString *const MgNodeType = @"org.unfactored.mg-node";
NSString *const MgArchiveType = @"org.unfactored.mg-archive";

static NSUInteger version_counter;

@implementation MgNode
{
  MgNodeState *_state;
  NSMutableArray *_states;
  NSArray *_transitions;
  NSString *_name;
  NSPointerArray *_references;
  NSUInteger _version;
  uint32_t _mark;			/* for graph traversal */
}

+ (instancetype)node
{
  return [[self alloc] init];
}

+ (Class)stateClass
{
  return [MgNodeState class];
}

+ (BOOL)accessInstanceVariablesDirectly
{
  /* -valueForUndefinedKey: and -setValue:forUndefinedKey: aren't called
     unless this method returns false. And if those methods aren't called
     we can't manually call our accessor methods for CF object types. */

  return NO;
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _version = 1;

  Class state_class = [[self class] stateClass];

  _state = [state_class defaultState];
  _states = [NSMutableArray arrayWithObject:_state];

  return self;
}

+ (BOOL)automaticallyNotifiesObserversOfState
{
  return NO;
}

- (MgNodeState *)state
{
  return _state;
}

- (void)setState:(MgNodeState *)state
{
  if (_state != state)
    {
      [self willChangeValueForKey:@"state"];
      _state = state;
      [self incrementVersion];
      [self didChangeValueForKey:@"state"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfStates
{
  return NO;
}

- (NSArray *)states
{
  return _states != nil ? _states : @[];
}

- (void)setStates:(NSArray *)array
{
  if (![_states isEqual:array])
    {
      [self willChangeValueForKey:@"states"];
      _states = [array mutableCopy];
      [self incrementVersion];
      [self didChangeValueForKey:@"states"];
    }
}

- (void)addState:(MgNodeState *)state
{
  [self willChangeValueForKey:@"states"];
  if (_states == nil)
    _states = [NSMutableArray array];
  [_states addObject:state];
  [self incrementVersion];
  [self didChangeValueForKey:@"states"];
}

- (MgNodeState *)moduleState:(MgModuleState *)moduleState
{
  while (1)
    {
      for (MgNodeState *state in _states)
	{
	  if (state.moduleState == moduleState)
	    return state;
	}

      if (moduleState == nil)
	break;

      moduleState = moduleState.superstate;
    }

  return nil;
}

- (MgNodeState *)addModuleState:(MgModuleState *)moduleState
{
  for (MgNodeState *state in _states)
    {
      if (state.moduleState == moduleState)
	return state;
    }

  MgNodeState *state = [[[self class] stateClass] state];

  state.superstate = [self addModuleState:moduleState.superstate];

  [self addState:state];

  return state;
}

- (void)applyModuleState:(MgModuleState *)moduleState
{
  /* MgModuleLayer overrides -applyModuleState:mark: to terminate the
     recursion, so we apply the state to the root object here to avoid
     that. */

  self.state = [self moduleState:moduleState];

  uint32_t mark = [MgNode nextMark];

  [self foreachNode:^(MgNode *child)
    {
      [child applyModuleState:moduleState mark:mark];
    }
   mark:mark];
}

- (void)applyModuleState:(MgModuleState *)moduleState mark:(uint32_t)mark
{
  self.state = [self moduleState:moduleState];

  [self foreachNode:^(MgNode *child)
    {
      [child applyModuleState:moduleState mark:mark];
    }
   mark:mark];
}

+ (BOOL)automaticallyNotifiesObserversOfTransitions
{
  return NO;
}

- (NSArray *)transitions
{
  return _transitions != nil ? _transitions : @[];
}

- (void)setTransitions:(NSArray *)array
{
  if (![_transitions isEqual:array])
    {
      [self willChangeValueForKey:@"transitions"];
      _transitions = [array copy];
      [self incrementVersion];
      [self didChangeValueForKey:@"transitions"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfEnabled
{
  return NO;
}

- (BOOL)isEnabled
{
  return self.state.enabled;
}

- (void)setEnabled:(BOOL)flag
{
  MgNodeState *state = self.state;
  if (state.enabled != flag)
    {
      [self willChangeValueForKey:@"enabled"];
      state.enabled = flag;
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

- (void)foreachNode:(void (^)(MgNode *node))block
{
}

- (void)foreachNodeAndAttachmentInfo:(void (^)(MgNode *node,
    NSString *parentKey, NSInteger parentIndex))block
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

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgNode *copy = [[[self class] alloc] init];

  copy->_states = [NSMutableArray array];

  for (MgNodeState *state in _states)
    {
      MgNodeState *state_copy = [state mg_graphCopy:map];

      [copy->_states addObject:state_copy];

      if (state == _state)
	copy->_state = state_copy;
    }

  copy->_name = [_name copy];

  return copy;
}

/** NSSecureCoding methods. **/

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)c
{
  [c encodeObject:_states forKey:@"states"];
  [c encodeObject:_state forKey:@"state"];

  if (_name != nil)
    [c encodeObject:_name forKey:@"name"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [self init];
  if (self == nil)
    return nil;

  _states = [[c decodeObjectOfClass:[NSArray class] forKey:@"states"]
	     mutableCopy];
  _state = [c decodeObjectOfClass:[MgNodeState class] forKey:@"state"];

  if ([c containsValueForKey:@"name"])
    _name = [[c decodeObjectOfClass:[NSString class] forKey:@"name"] copy];

  return self;
}

@end
