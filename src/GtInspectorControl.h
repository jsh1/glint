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

@protocol GtInspectorDelegate <NSObject>

- (id)inspectedValueForKey:(NSString *)key;

- (void)setInspectedValue:(id)value forKey:(NSString *)key;

@end


@interface GtInspectorControl : NSView

+ (instancetype)controlForItem:(GtInspectorItem *)item
    delegate:(id<GtInspectorDelegate>)delegate;

+ (CGFloat)controlHeightForItem:(GtInspectorItem *)item;

/* designated initializer, should only be called by subclasses. */

- (id)initWithItem:(GtInspectorItem *)item
    delegate:(id<GtInspectorDelegate>)delegate;

@property(nonatomic, retain, readonly) GtInspectorItem *item;
@property(nonatomic, weak, readonly) id<GtInspectorDelegate> delegate;

@property(nonatomic, retain) id objectValue;

- (void)layoutSubviews;

- (IBAction)takeValue:(id)sender;

/* Values for laying out controls. */

@property(nonatomic, assign, readonly) CGRect leftColumnRect;
@property(nonatomic, assign, readonly) CGRect rightColumnRect;

@end
