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

#import "GtBase.h"

@protocol GtTreeNodeOwner;

@interface GtTreeNode : NSObject

- (id)initWithNode:(MgNode *)node parent:(GtTreeNode *)parent
    parentKey:(NSString *)key parentIndex:(NSInteger)idx;

@property(nonatomic, strong, readonly) MgNode *node;
@property(nonatomic, weak, readonly) GtTreeNode *parent;
@property(nonatomic, copy, readonly) NSString *parentKey;
@property(nonatomic, assign, readonly) NSInteger parentIndex;
@property(nonatomic, readonly) NSArray *children;
@property(nonatomic, assign, readonly, getter=isLeaf) BOOL leaf;

/* Returns YES if all nodes were iterated over. */

- (BOOL)foreachNode:(void (^)(GtTreeNode *node, BOOL *stop))thunk;

- (GtTreeNode *)containingLayer;
- (GtTreeNode *)containingGroup;

- (BOOL)isDescendantOf:(GtTreeNode *)tn;
- (GtTreeNode *)ancestorSharedWith:(GtTreeNode *)tn;

- (CGPoint)convertPointToRoot:(CGPoint)p;
- (CGPoint)convertPointFromRoot:(CGPoint)p;

- (BOOL)containsPoint:(CGPoint)p;
- (GtTreeNode *)hitTest:(CGPoint)p;

@end
