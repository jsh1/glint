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

#import "YuBase.h"

@interface YuViewController : NSViewController

+ (NSString *)viewNibName;

- (NSString *)identifier;

@property(nonatomic, copy) NSString *identifierSuffix;

- (id)initWithController:(YuWindowController *)controller;

@property(nonatomic, assign, readonly) BOOL viewHasBeenLoaded;

- (void)viewDidLoad;

- (void)viewWillAppear;
- (void)viewDidAppear;

- (void)viewWillDisappear;
- (void)viewDidDisappear;

@property(nonatomic, weak, readonly) YuWindowController *controller;
@property(nonatomic, weak, readonly) YuDocument *document;

- (YuViewController *)viewControllerWithClass:(Class)cls;
- (void)foreachViewControllerWithClass:(Class)cls
    handler:(void (^)(id obj))block;

@property(nonatomic, weak, readonly) YuViewController *superviewController;
@property(nonatomic, copy) NSArray *subviewControllers;

- (void)addSubviewController:(YuViewController *)controller;
- (void)addSubviewController:(YuViewController *)controller
    after:(YuViewController *)pred;
- (void)removeSubviewController:(YuViewController *)controller;

@property(nonatomic, weak, readonly) NSView *initialFirstResponder;

- (void)addSavedViewState:(NSMutableDictionary *)dict;
- (void)applySavedViewState:(NSDictionary *)dict;

- (void)addToContainerView:(NSView *)view;
- (void)removeFromContainer;

@end
