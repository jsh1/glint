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

#import "GtSplitViewController.h"

#import "GtSplitView.h"

#import "FoundationExtensions.h"

@implementation GtSplitViewController

- (id)initWithWindowController:(GtWindowController *)controller
{
  self = [super initWithWindowController:controller];
  if (self == nil)
    return nil;

  _indexOfResizableSubview = -1;

  return self;
}

- (void)loadView
{
  GtSplitView *view = [[GtSplitView alloc] initWithFrame:NSZeroRect];

  [view setVertical:self.vertical];
  [view setDividerStyle:NSSplitViewDividerStyleThin];
  [view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [view setDelegate:self];

  [self setView:view];
}

- (void)viewWillAppear
{
  GtSplitView *view = (GtSplitView *)[self view];

  [view setSubviews:@[]];

  for (GtViewController *c in self.subviewControllers)
    {
      NSView *sub = [c view];
      [sub setFrame:[view bounds]];
      [view addSubview:sub];
    }

  [view adjustSubviews];
  [view setPosition:300 ofDividerAtIndex:0];
  [view setIndexOfResizableSubview:self.indexOfResizableSubview];
}

- (void)addSavedViewState:(NSMutableDictionary *)dict
{
  NSString *ident = [self identifier];
  if (ident == nil)
    return;

  NSDictionary *state = [(GtSplitView *)[self view] savedViewState];
  if (state != nil)
    dict[ident] = state;
}

- (void)applySavedViewState:(NSDictionary *)dict
{
  NSString *ident = [self identifier];
  if (ident == nil)
    return;

  NSDictionary *state = dict[ident];
  if (state != nil)
    [(GtSplitView *)[self view] applySavedViewState:state];
}

- (BOOL)_isSubviewControllerVisible:(GtViewController *)c
{
  return ![(GtSplitView *)[self view] isSubviewCollapsed:[c view]];
}

- (void)_showSubviewController:(GtViewController *)c
{
  [(GtSplitView *)[self view] setSubview:[c view] collapsed:NO];
}

+ (BOOL)_canHideSubviewControllers;
{
  return YES;
}

- (void)_hideSubviewController:(GtViewController *)c
{
  [(GtSplitView *)[self view] setSubview:[c view] collapsed:YES];
}

/** NSSplitViewDelegate methods. **/

- (CGFloat)splitView:(GtSplitView *)view minimumSizeOfSubview:(NSView *)subview
{
  return 250;
}

- (BOOL)splitView:(NSSplitView *)view canCollapseSubview:(NSView *)subview
{
  return YES;
}

- (BOOL)splitView:(NSSplitView *)view shouldCollapseSubview:(NSView *)subview
    forDoubleClickOnDividerAtIndex:(NSInteger)idx
{
  return YES;
}

- (BOOL)splitView:(NSSplitView *)view shouldHideDividerAtIndex:(NSInteger)idx
{
  return YES;
}

- (CGFloat)splitView:(NSSplitView *)view constrainMinCoordinate:(CGFloat)p
    ofSubviewAt:(NSInteger)idx
{
  NSView *subview = [[view subviews] objectAtIndex:idx];
  CGFloat min_size = [(GtSplitView *)view minimumSizeOfSubview:subview];

  return p + min_size;
}

- (CGFloat)splitView:(NSSplitView *)view constrainMaxCoordinate:(CGFloat)p
    ofSubviewAt:(NSInteger)idx
{
  NSView *subview = [[view subviews] objectAtIndex:idx+1];
  CGFloat min_size = [(GtSplitView *)view minimumSizeOfSubview:subview];

  return p - min_size;
}

- (BOOL)splitView:(NSSplitView *)view
    shouldAdjustSizeOfSubview:(NSView *)subview
{
  if ([view isKindOfClass:[GtSplitView class]])
    return [(GtSplitView *)view shouldAdjustSizeOfSubview:subview];
  else
    return YES;
}

@end
