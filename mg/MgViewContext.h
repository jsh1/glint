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

@protocol MgViewLayer;

@interface MgViewContext : NSObject

+ (MgViewContext *)contextWithLayer:(MgLayer *)layer;

- (id)initWithLayer:(MgLayer *)layer;

@property(nonatomic, assign) CGFloat contentsScale;

@property(nonatomic, strong, readonly) MgLayer *layer;

@property(nonatomic, strong, readonly) CALayer *viewLayer;

/* For view layers. */

- (void)updateViewLayer:(CALayer<MgViewLayer> *)layer;

- (CALayer<MgViewLayer> *)makeViewLayerForLayer:(MgLayer *)src
    candidate:(CALayer *)layer;

- (NSArray *)makeViewLayersForLayers:(NSArray *)array
    candidates:(NSArray *)layers culler:(BOOL (^)(MgLayer *src))pred;

+ (NSDictionary *)animationMap;

- (NSMutableArray *)makeAnimationsForTransition:(MgActiveTransition *)trans
    viewLayer:(CALayer<MgViewLayer> *)layer;

- (CAAnimation *)makeAnimationForTiming:(MgTransitionTiming *)timing
    key:(NSString *)key from:(id)fromValue to:(id)toValue;

@end

typedef CAAnimation *(^MgViewAnimationBlock)(MgViewContext *ctx,
    CALayer<MgViewLayer> *layer, NSString *key, MgTransitionTiming *timing,
    id fromValue, id toValue);

@protocol MgViewLayer

- (id)initWithMgLayer:(MgLayer *)layer viewContext:(MgViewContext *)ctx;

@property(nonatomic, strong, readonly) MgLayer *layer;
@property(nonatomic, weak, readonly) MgViewContext *viewContext;

- (void)update;

@optional

+ (NSDictionary *)animationMap;

- (NSArray *)makeAnimationsForTransition:(MgActiveTransition *)trans;

@end
