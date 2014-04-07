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

#import "MgActiveTransition.h"
#import "MgNodeState.h"
#import "MgModuleState.h"
#import "MgNodeTransition.h"
#import "MgTimingFunction.h"
#import "MgTransitionTiming.h"

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
  MgActiveTransition *_activetransition;
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
    options:(NSDictionary *)dict
{
  /* MgModuleLayer overrides -applyModuleState:mark: to terminate the
     recursion, so we apply the state to the root object here to avoid
     that. */

  [self _setModuleState:moduleState options:dict];

  uint32_t mark = [MgNode nextMark];

  [self foreachNode:^(MgNode *child)
    {
      [child applyModuleState:moduleState options:dict mark:mark];
    }
   mark:mark];
}

- (void)applyModuleState:(MgModuleState *)moduleState
    options:(NSDictionary *)dict mark:(uint32_t)mark
{
  [self _setModuleState:moduleState options:dict];

  [self foreachNode:^(MgNode *child)
    {
      [child applyModuleState:moduleState options:dict mark:mark];
    }
   mark:mark];
}

- (void)_setModuleState:(MgModuleState *)moduleState
    options:(NSDictionary *)dict
{
  MgNodeState *old_state = self.state;
  MgNodeState *new_state = [self moduleState:moduleState];

  if (old_state == new_state)
    return;

  MgActiveTransition *trans = nil;

  NSNumber *speed_value = dict[@"speed"];

  if (speed_value == nil || [speed_value doubleValue] != 0)
    {
      NSMutableArray *transitions = [NSMutableArray array];

      MgNodeTransition *explicit_trans = [self _transitionFrom:old_state
					  to:new_state];
      if (explicit_trans != nil)
	{
	  [transitions addObject:explicit_trans];
	}
      else
	{
	  /* No explicit transition between the two states, try to
	     synthesize one piecewise from the path between them. */

	  MgNodeState *root_state = [old_state ancestorSharedWith:new_state];

	  struct node
	    {
	      struct node *next;
	      __unsafe_unretained MgNodeState *state;
	    };

	  struct node *lst = NULL;

	  for (MgNodeState *state = old_state;
	       state != root_state; state = state.superstate)
	    {
	      struct node *tem = alloca(sizeof(*tem));
	      tem->next = lst;
	      tem->state = state;
	      lst = tem;
	    }

	  for (MgNodeState *state = new_state;
	       state != root_state; state = state.superstate)
	    {
	      MgNodeTransition *trans = [self _transitionTo:state];
	      if (trans != nil)
		[transitions addObject:trans];
	    }

	  for (struct node *it = lst; it != NULL; it = it->next)
	    {
	      MgNodeTransition *trans = [self _transitionFrom:it->state];
	      if (trans != nil)
		[transitions addObject:trans];
	    }
	}

      double begin = [dict[@"begin"] doubleValue];
      if (begin == 0)
	begin = CACurrentMediaTime();

      double speed = speed_value != nil ? [speed_value doubleValue] : 1;

      double duration = [dict[@"duration"] doubleValue];
      if (duration == 0)
	duration = .25;

      MgFunction *function = dict[@"function"];
      if (function == nil)
	function = [MgTimingFunction functionWithName:MgTimingFunctionDefault];

      MgTransitionTiming *default_timing = [[MgTransitionTiming alloc] init];
      default_timing.duration = duration;
      default_timing.function = function;

      MgNodeState *trans_from = old_state;

      /* If there's already an active transition running, sample it at
	 the begin time of the new transition and use that as the from-
	 state of the new transition. */

      MgActiveTransition *old_trans = self.activeTransition;
      if (old_trans != nil)
	trans_from = [old_state evaluateTransition:old_trans atTime:begin];

      trans = [[MgActiveTransition alloc] init];

      trans.begin = begin;
      trans.speed = speed;
      trans.fromState = trans_from;
      trans.nodeTransitions = transitions;
      trans.defaultTiming = default_timing;
    }

  self.state = new_state;
  self.activeTransition = trans;
}

- (MgNodeTransition *)_transitionFrom:(MgNodeState *)from to:(MgNodeState *)to
{
  MgModuleState *from_s = from.moduleState;
  MgModuleState *to_s = to.moduleState;

  for (MgNodeTransition *t in self.transitions)
    {
      if (t.from == from_s && t.to == to_s)
	return t;
    }

  return nil;
}

- (MgNodeTransition *)_transitionFrom:(MgNodeState *)from
{
  MgModuleState *from_s = from.moduleState;

  for (MgNodeTransition *t in self.transitions)
    {
      if (t.from == from_s && t.to == nil)
	return t;
    }

  return nil;
}

- (MgNodeTransition *)_transitionTo:(MgNodeState *)to
{
  MgModuleState *to_s = to.moduleState;

  for (MgNodeTransition *t in self.transitions)
    {
      if (t.from == nil && t.to == to_s)
	return t;
    }

  return nil;
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

- (void)withPresentationTime:(CFTimeInterval)t handler:(void (^)(void))thunk
{
  MgNodeState *old_state = self.state;
  MgNodeState *new_state = nil;

  MgActiveTransition *trans = self.activeTransition;

  if (trans != nil)
    {
      double tt = (t - trans.begin) * trans.speed;
      new_state = [old_state evaluateTransition:trans atTime:tt];
    }

  if (new_state != nil)
    self.state = new_state;

  thunk();

  if (new_state != nil)
    self.state = old_state;
}

- (CFTimeInterval)markPresentationTime:(CFTimeInterval)t
{
  MgActiveTransition *trans = self.activeTransition;

  if (trans != nil)
    {
      double tt = (t - trans.begin) * trans.speed;

      if (!(tt < trans.duration))
	{
	  self.activeTransition = nil;
	  trans = nil;
	}
    }

  return trans == nil ? HUGE_VAL : t;
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
