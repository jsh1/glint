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

@interface YuWindowController : NSWindowController <NSSplitViewDelegate>

@property(nonatomic, weak, readonly) YuDocument *document;

- (id)viewControllerWithClass:(Class)cls;

- (void)addSplitView:(YuSplitView *)view identifier:(NSString *)ident;
- (void)removeSplitView:(YuSplitView *)view identifier:(NSString *)ident;

- (void)saveWindowState;
- (void)applySavedWindowState;

- (IBAction)zoomInAction:(id)sender;
- (IBAction)zoomOutAction:(id)sender;
- (IBAction)zoomToAction:(id)sender;	/* zoom(2^[sender tag]) */
- (IBAction)zoomToFitAction:(id)sender;
- (IBAction)zoomToFillAction:(id)sender;

@end
