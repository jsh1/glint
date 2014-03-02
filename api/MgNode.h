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

@interface MgNode : NSObject <NSCopying, NSSecureCoding>

/* Value that increments whenever this node changes (or a node that it
   transitively refers to changes). */

@property(nonatomic, readonly) NSUInteger version;

/* Calls `block(node)' for each node referred to by the receiver. (Note
   that this includes all kinds of nodes, e.g. including animations.)  */

- (void)foreachNode:(void (^)(MgNode *node))block;

/* Calls `block(node)' for each node referred to by the receiver, iff
   their current mark value is not `mark'. Before `block(node)' is
   called, `node' has its mark value set to `mark'. */

- (void)foreachNode:(void (^)(MgNode *node))block mark:(uint32_t)mark;

@end
