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

@interface MgNodeTransition : NSObject <MgGraphCopying, NSSecureCoding>

+ (instancetype)transition;

@property(nonatomic, weak) MgModuleState *fromState;
@property(nonatomic, weak) MgModuleState *toState;
@property(nonatomic, assign, getter=isReversible) BOOL reversible;

/** Transition timing. **/

@property(nonatomic, assign) double begin;
@property(nonatomic, assign) double duration;
@property(nonatomic, copy) MgFunction *function;

- (double)beginForKey:(NSString *)key;
- (void)setBeginForKey:(double)t forKey:(NSString *)key;

- (double)durationForKey:(NSString *)key;
- (void)setDuration:(double)t forKey:(NSString *)key;

- (MgFunction *)functionForKey:(NSString *)key;
- (void)setFunction:(MgFunction *)fun forKey:(NSString *)key;

@end
