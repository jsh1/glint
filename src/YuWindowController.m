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

#import "YuWindowController.h"

#import "YuAppDelegate.h"
#import "YuColor.h"
#import "YuDocument.h"
#import "YuSplitViewController.h"
#import "YuTreeNode.h"
#import "YuTreeViewController.h"
#import "YuViewController.h"
#import "YuViewerView.h"
#import "YuViewerViewController.h"

#import "FoundationExtensions.h"

@implementation YuWindowController
{
  YuViewController *_viewController;
  YuTreeNode *_tree;
  NSSet *_selection;
}

- (void)invalidate
{
  [_viewController invalidate];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
}

- (void)dealloc
{
  [self invalidate];
}

- (YuDocument *)document
{
  return [super document];
}

- (YuTreeNode *)tree
{
  MgNode *rootNode = self.document.documentNode;

  if (_tree == nil || _tree.node != rootNode)
    _tree = [[YuTreeNode alloc] initWithNode:rootNode parent:nil];

  return _tree;
}

- (NSString *)windowNibName
{
  return @"YuWindow";
}

- (void)windowDidLoad
{
  NSWindow *window = [self window];

  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(windowWillClose:)
   name:NSWindowWillCloseNotification object:window];

  [window setBackgroundColor:[YuColor windowBackgroundColor]];

  /* FIXME: replace by something else. */

  YuSplitViewController *split = [[YuSplitViewController alloc]
				  initWithController:self];
  YuTreeViewController *tree = [[YuTreeViewController alloc]
				initWithController:self];
  YuViewerViewController *viewer = [[YuViewerViewController alloc]
				    initWithController:self];

  split.vertical = YES;
  split.indexOfResizableSubview = 1;
  split.identifierSuffix = @".main";

  [split addSubviewController:tree];
  [split addSubviewController:viewer];

  [split addToContainerView:self.mainView];

  _viewController = split;

  [self applySavedWindowState];

  [window setInitialFirstResponder:[viewer initialFirstResponder]];

  [window makeFirstResponder:[window initialFirstResponder]];
}

- (id)viewControllerWithClass:(Class)cls
{
  return [_viewController viewControllerWithClass:cls];
}

- (void)foreachViewControllerWithClass:(Class)cls
    handler:(void (^)(id obj))block
{
  [_viewController foreachViewControllerWithClass:cls handler:block];
}

- (void)saveWindowState
{
  if (![self isWindowLoaded] || [self window] == nil)
    return;

  NSMutableDictionary *controllers = [NSMutableDictionary dictionary];

  [_viewController addSavedViewState:controllers];

  NSDictionary *dict = @{
    @"YuViewControllers": controllers,
  };

  [[NSUserDefaults standardUserDefaults]
   setObject:dict forKey:@"YuSavedWindowState"];
}

- (void)applySavedWindowState
{
  NSDictionary *state = [[NSUserDefaults standardUserDefaults]
			 dictionaryForKey:@"YuSavedWindowState"];
  if (state == nil)
    return;

  NSDictionary *controllers = [state objectForKey:@"YuViewControllers"];

  [_viewController applySavedViewState:controllers];
}

- (void)windowWillClose:(NSNotification *)note
{
  [self saveWindowState];
  [self invalidate];
}

+ (BOOL)automaticallyNotifiesObserversOfSelection
{
  return NO;
}

- (NSSet *)selection
{
  return _selection;
}

- (void)setSelection:(NSSet *)set
{
  if (![_selection isEqual:set])
    {
      [self willChangeValueForKey:@"selection"];
      _selection = [set copy];
      [self didChangeValueForKey:@"selection"];
    }
}

- (IBAction)zoomInAction:(id)sender
{
  [self foreachViewControllerWithClass:[YuViewerViewController class]
   handler:^(id obj)
    {
      YuViewerView *view = ((YuViewerViewController *)obj).contentView;
      view.viewScale *= 2;
    }];
}

- (IBAction)zoomOutAction:(id)sender
{
  [self foreachViewControllerWithClass:[YuViewerViewController class]
   handler:^(id obj)
    {
      YuViewerView *view = ((YuViewerViewController *)obj).contentView;
      view.viewScale *= .5;
    }];
}

- (IBAction)zoomToAction:(id)sender
{
  CGFloat scale = pow(2, [sender tag]);

  [self foreachViewControllerWithClass:[YuViewerViewController class]
   handler:^(id obj)
    {
      YuViewerView *view = ((YuViewerViewController *)obj).contentView;
      if (view.viewScale != scale)
	view.viewScale = scale;
      else
	{
	  CGRect bounds = [view bounds];
	  view.viewCenter = CGPointMake(CGRectGetMidX(bounds),
					CGRectGetMidY(bounds));
	}
    }];
}

- (IBAction)zoomToFitAction:(id)sender
{
  [self foreachViewControllerWithClass:[YuViewerViewController class]
   handler:^(id obj)
    {
      YuViewerView *view = ((YuViewerViewController *)obj).contentView;
      view.viewScale = view.zoomToFitScale;
    }];
}

- (IBAction)zoomToFillAction:(id)sender
{
  [self foreachViewControllerWithClass:[YuViewerViewController class]
   handler:^(id obj)
    {
      YuViewerView *view = ((YuViewerViewController *)obj).contentView;
      view.viewScale = view.zoomToFillScale;
    }];
}

@end
