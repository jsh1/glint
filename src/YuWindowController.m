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
  NSArray *_selection;
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

- (NSArray *)selection
{
  return _selection != nil ? _selection : @[];
}

- (void)setSelection:(NSArray *)array
{
  if (![_selection isEqual:array])
    {
      [self willChangeValueForKey:@"selection"];
      _selection = [array copy];
      [self didChangeValueForKey:@"selection"];
    }
}

- (IBAction)nextNodeAction:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  for (YuTreeNode *node in self.selection)
    {
      NSArray *node_children = node.children;
      if ([node_children count] != 0)
	{
	  [set addObject:[node_children firstObject]];
	  continue;
	}

      for (YuTreeNode *n = node; n != nil; n = n.parent)
	{
	  YuTreeNode *p = n.parent;
	  if (p == nil)
	    {
	      [set addObject:node];
	      break;
	    }

	  NSArray *p_children = p.children;
	  if (p_children == nil)
	    continue;

	  NSInteger idx = [p_children indexOfObjectIdenticalTo:n];
	  if (idx == NSNotFound)
	    continue;

	  if (idx + 1 < [p_children count])
	    {
	      [set addObject:p_children[idx + 1]];
	      break;
	    }
	}
    }

  if ([set count] == 0)
    [set addObject:self.tree];

  self.selection = [set allObjects];
}

static YuTreeNode *
deepestLastChild(YuTreeNode *n)
{
  while (1)
    {
      NSArray *children = n.children;

      NSInteger count = [children count];
      if (count == 0)
	break;

      n = children[count-1];
    }

  return n;
}

- (IBAction)previousNodeAction:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  for (YuTreeNode *node in self.selection)
    {
      YuTreeNode *p = node.parent;
      if (p == nil)
	{
	  [set addObject:node];
	  continue;
	}

      NSArray *p_children = p.children;
      if (p_children == nil)
	continue;

      NSInteger idx = [p_children indexOfObjectIdenticalTo:node];
      if (idx == NSNotFound)
	continue;

      if (idx > 0)
	[set addObject:deepestLastChild(p_children[idx - 1])];
      else
	[set addObject:p];
    }

  if ([set count] == 0)
    [set addObject:deepestLastChild(self.tree)];

  self.selection = [set allObjects];
}

- (IBAction)parentNodeAction:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  for (YuTreeNode *node in self.selection)
    {
      YuTreeNode *parent = node.parent;
      [set addObject:parent != nil ? parent : node];
    }

  if ([set count] == 0)
    [set addObject:self.tree];

  self.selection = [set allObjects];
}

- (IBAction)childNodeAction:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  for (YuTreeNode *node in self.selection)
    {
      YuTreeNode *child = [node.children firstObject];
      [set addObject:child != nil ? child : node];
    }

  if ([set count] == 0)
    [set addObject:self.tree];

  self.selection = [set allObjects];
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
