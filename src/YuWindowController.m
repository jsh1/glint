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
#import "YuTreeViewController.h"
#import "YuViewController.h"
#import "YuViewerView.h"
#import "YuViewerViewController.h"

#import "FoundationExtensions.h"

NSString *const YuWindowControllerSelectionDidChange = @"YuWindowControllerSelectionDidChange";

@implementation YuWindowController
{
  YuViewController *_viewController;
  NSSet *_selectedNodes;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
}

- (YuDocument *)document
{
  return [super document];
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
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self saveWindowState];
}

+ (BOOL)automaticallyNotifiesObserversOfSelectedNodes
{
  return NO;
}

- (NSSet *)selectedNodes
{
  return _selectedNodes;
}

- (void)setSelectedNodes:(NSSet *)set
{
  if (![_selectedNodes isEqual:set])
    {
      [self willChangeValueForKey:@"selectedNodes"];
      _selectedNodes = [set copy];
      [self didChangeValueForKey:@"selectedNodes"];

      [[NSNotificationCenter defaultCenter]
       postNotificationName:YuWindowControllerSelectionDidChange object:self];
    }
}

- (NSSet *)selectedLayerNodes
{
  return [_selectedNodes filteredSet:^BOOL (id obj)
    {
      return [obj isKindOfClass:[MgLayerNode class]];
    }];
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
