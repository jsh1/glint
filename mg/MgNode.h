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

#import "MgBase.h"

extern NSString *const MgNodeType;	/* UTI: org.unfactored.mg-node */
extern NSString *const MgArchiveType;	/* UTI: org.unfactored.mg-archive */

@interface MgNode : NSObject <MgGraphCopying, NSSecureCoding>

+ (instancetype)node;

+ (Class)stateClass;

/* Designated initializer. */

- (id)init;

/* The current state of the receiver. */

@property(nonatomic, strong) MgNodeState *state;

/* All states implemented by the receiver, an array of MgNodeState
   instances. */

@property(nonatomic, copy) NSArray *states;

/* Returns the closest substate matching moduleState implemented by
   the receiver. */

- (MgNodeState *)moduleState:(MgModuleState *)moduleState;

/* If necessary, adds a state to the receiver for `moduleState'. */

- (MgNodeState *)addModuleState:(MgModuleState *)moduleState;

/* Applies `moduleState' to the subtree rooted at the receiver. */

- (void)applyModuleState:(MgModuleState *)moduleState
    options:(NSDictionary *)dict;

/* The explicit transitions defined by the receiver, an array of
   MgNodeTransition instances. */

@property(nonatomic, copy) NSArray *transitions;

/* The currently active state transition. */

@property(nonatomic, retain) MgActiveTransition *activeTransition;

/* The name of the receiver. This property is global, i.e. does not
   vary by state. */

@property(nonatomic, copy) NSString *name;

/* Value that increments whenever this node changes (or a node that it
   transitively refers to changes). */

@property(nonatomic, readonly) NSUInteger version;

/* Calls `block(node)' for each node referred to by the receiver. (Note
   that this includes all kinds of nodes, e.g. including animations.)  */

- (void)foreachNode:(void (^)(MgNode *node))block;

/* Similar but also tells the caller which property each child node is
   stored in and, if that property is an array, the index in the array.
   (If not an array, NSNotFound is passed as 'parentIndex'.) */

- (void)foreachNodeAndAttachmentInfo:(void (^)(MgNode *node,
    NSString *parentKey, NSInteger parentIndex))block;

/* Calls `block(node)' for each node referred to by the receiver, iff
   their current mark value is not `mark'. Before `block(node)' is
   called, `node' has its mark value set to `mark'. */

- (void)foreachNode:(void (^)(MgNode *node))block mark:(uint32_t)mark;

/* Returns a new unused mark value for calling -foreachNode:mark: */

+ (uint32_t)nextMark;

/* Calls 'thunk' such that when it queries animatable values of the
   receiver they will be the values defined by transitions at time 't'.
   Setting any properties of the receiver will have undefined results. */

- (void)withPresentationTime:(CFTimeInterval)t handler:(void (^)(void))thunk;

/* Tells the runtime that time 't' will not be seen again, i.e. that
   any temporal events strictly before that time may be discarded.
   Returns the time at which the receiver's next temporal event occurs. */

- (CFTimeInterval)markPresentationTime:(CFTimeInterval)t;

@end

/** Keys for -applyModuleState:options: dictionary. **/

extern NSString *const MgNodeAnimated;
extern NSString *const MgNodeTransitionSpeed;
extern NSString *const MgNodeTransitionBegin;
extern NSString *const MgNodeTransitionDuration;
extern NSString *const MgNodeTransitionFunction;
