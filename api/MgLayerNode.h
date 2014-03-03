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

#import "MgDrawableNode.h"
#import "MgTiming.h"

@interface MgLayerNode : MgDrawableNode

/** Geometry properties. **/

@property(nonatomic, assign) CGPoint position;
@property(nonatomic, assign) CGPoint anchor;
@property(nonatomic, assign) CGRect bounds;
@property(nonatomic, assign) CGFloat cornerRadius;

@property(nonatomic, assign) CGFloat scale;
@property(nonatomic, assign) CGFloat squeeze;
@property(nonatomic, assign) CGFloat skew;
@property(nonatomic, assign) double rotation;

@property(nonatomic, readonly) CGAffineTransform parentTransform;

/** Compositing properties. **/

@property(nonatomic, assign, getter=isGroup) BOOL group;
@property(nonatomic, assign) float alpha;
@property(nonatomic, assign) CGBlendMode blendMode;
@property(nonatomic, assign) BOOL masksToBounds;
@property(nonatomic, retain) MgDrawableNode *maskNode;

/** Content nodes. **/

@property(nonatomic, copy) NSArray *contentNodes;

- (void)addContentNode:(MgDrawableNode *)node;
- (void)removeContentNode:(MgDrawableNode *)node;

- (void)insertContentNode:(MgDrawableNode *)node atIndex:(NSInteger)idx;
- (void)removeContentNodeAtIndex:(NSInteger)idx;

@end
