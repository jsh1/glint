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

#import "GtViewController.h"

typedef NS_ENUM(NSInteger, GtTransitionViewControllerDragMode)
{
  GtTransitionViewControllerDragNone,
  GtTransitionViewControllerDragStart,
  GtTransitionViewControllerDragEnd,
  GtTransitionViewControllerDragInside,
};

@interface GtTransitionViewController : GtViewController
    <NSOutlineViewDataSource, NSOutlineViewDelegate,
     NSTableViewDataSource, NSTableViewDelegate>

@property(nonatomic, weak) IBOutlet NSTableView *tableView;
@property(nonatomic, weak) IBOutlet NSOutlineView *outlineView;

@property(nonatomic, strong) GtTreeNode *moduleNode;
@property(nonatomic, strong) MgModuleLayer *currentModule;
@property(nonatomic, strong) MgModuleState *fromState;
@property(nonatomic, strong) MgModuleState *toState;

@property(nonatomic, assign) double timelineStart, timelineScale;

@property(nonatomic, copy, readonly) MgTransitionTiming *defaultTiming;

- (MgNodeTransition *)nodeTransition:(GtTreeNode *)tn;
- (MgNodeTransition *)nodeTransition:(GtTreeNode *)tn onlyIfExists:(BOOL)flag;

- (BOOL)mouseDown:(NSEvent *)e inTimingView:(GtTransitionTimingView *)view
  dragMode:(GtTransitionViewControllerDragMode)mode;

@end
