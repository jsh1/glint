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

#import "MgNode.h"

@interface MgNodeState : NSObject <MgGraphCopying, NSSecureCoding>

+ (instancetype)state;

+ (instancetype)defaultState;

+ (NSSet *)allProperties;

- (id)init;

- (void)setDefaults;

/* The state this is part of. */

@property(nonatomic, strong) MgModuleState *moduleState;

/* The state that this state derives from. Any values not defined by
   this state will be dereferenced in its superstate. */

@property(nonatomic, strong) MgNodeState *superstate;

/* Returns true if the receiver explicitly defines a value for the
   property with name 'key'. */

- (BOOL)definesValueForKey:(NSString *)key;
- (void)setDefinesValue:(BOOL)flag forKey:(NSString *)key;

/* 'trans' may be nil, in which case property timing is identity. */

- (MgNodeState *)evaluateTransition:(MgNodeTransition *)trans
    atTime:(double)t to:(MgNodeState *)to;

/** MgNode properties. **/

@property(nonatomic, assign, getter=isEnabled) BOOL enabled;

@end
