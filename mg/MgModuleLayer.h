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

#import "MgGroupLayer.h"

@interface MgModuleLayer : MgGroupLayer

/* The states of this module. Modifying this property does not
   currently modify the underlying MgNodeState properties for each item
   in the subgraph defined by the receiver. */

@property(nonatomic, copy) NSArray *moduleStates;

- (void)addModuleState:(MgModuleState *)state;
- (void)removeModuleState:(MgModuleState *)state;

- (void)insertModuleState:(MgModuleState *)state atIndex:(NSInteger)idx;
- (void)removeModuleStateAtIndex:(NSInteger)idx;

- (MgModuleState *)moduleStateWithName:(NSString *)name;

/* The current state of this module. */

@property(nonatomic, strong) MgModuleState *moduleState;

- (void)setModuleState:(MgModuleState *)state animated:(BOOL)flag;
- (void)setModuleState:(MgModuleState *)state options:(NSDictionary *)dict;

@end
