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

@interface GtViewController : NSViewController

+ (GtViewController *)viewControllerWithDictionary:(NSDictionary *)dict
    windowController:(GtWindowController *)windowController;

+ (NSString *)viewNibName;

- (NSString *)identifier;

@property(nonatomic, copy) NSString *identifierSuffix;

- (id)initWithWindowController:(GtWindowController *)windowController;

- (void)invalidate;

- (void)viewWillMount;
- (void)viewDidMount;

- (void)viewWillUnmount;
- (void)viewDidUnmount;

@property(nonatomic, weak, readonly) GtWindowController *windowController;
@property(nonatomic, weak, readonly) GtDocument *document;

- (GtViewController *)viewControllerWithClass:(Class)cls;
- (void)foreachViewControllerWithClass:(Class)cls
    handler:(void (^)(id obj))block;

- (GtViewController *)viewControllerWithIdentifier:(NSString *)ident;

@property(nonatomic, weak, readonly) GtViewController *superviewController;
@property(nonatomic, copy) NSArray *subviewControllers;

- (void)addSubviewController:(GtViewController *)controller;
- (void)addSubviewController:(GtViewController *)controller
    after:(GtViewController *)pred;
- (void)removeSubviewController:(GtViewController *)controller;

- (void)showSubviewController:(GtViewController *)controller;
- (void)hideSubviewController:(GtViewController *)controller;
- (void)maximizeSubviewController:(GtViewController *)controller;
- (void)toggleSubviewController:(GtViewController *)controller;
- (BOOL)subviewControllerIsVisible:(GtViewController *)controller;

@property(nonatomic, weak, readonly) NSView *initialFirstResponder;

- (void)addSavedViewState:(NSMutableDictionary *)dict;
- (void)applySavedViewState:(NSDictionary *)dict;

- (void)addToContainerView:(NSView *)view;
- (void)removeFromContainer;

/* For containers to implement, given an immediately sub-controller. */

- (BOOL)_isSubviewControllerVisible:(GtViewController *)controller;
- (void)_showSubviewController:(GtViewController *)controller;
- (BOOL)_hideSubviewController:(GtViewController *)controller;

@end
