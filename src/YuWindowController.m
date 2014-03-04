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
#import "YuDocument.h"
#import "YuSplitView.h"
#import "YuViewController.h"
#import "YuViewerView.h"
#import "YuViewerViewController.h"

#import "FoundationExtensions.h"

NSString *const YuWindowControllerSelectionDidChange = @"YuWindowControllerSelectionDidChange";

@implementation YuWindowController
{
  NSMutableArray *_viewControllers;
  NSMutableDictionary *_splitViews;
  NSSet *_selectedNodes;
}

- (id)init
{
  self = [super initWithWindow:nil];
  if (self == nil)
    return nil;

  _viewControllers = [[NSMutableArray alloc] init];
  _splitViews = [[NSMutableDictionary alloc] init];

  return self;
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

  [self addViewController:[YuViewerViewController class]];

  [self applySavedWindowState];

  YuViewerViewController *viewer
    = [self viewControllerWithClass:[YuViewerViewController class]];

  /* FIXME: replace by something else. */

  [window setContentView:[viewer view]];

  [window setInitialFirstResponder:[viewer initialFirstResponder]];

  [window makeFirstResponder:[window initialFirstResponder]];
}

- (id)addViewController:(Class)cls
{
  YuViewController *obj = [[cls alloc] initWithController:self];

  if (obj != nil)
    [_viewControllers addObject:obj];

  return obj;
}

- (id)viewControllerWithClass:(Class)cls
{
  for (YuViewController *obj in _viewControllers)
    {
      YuViewController *sub = [obj viewControllerWithClass:cls];
      if (sub != nil)
	return sub;
    }

  return nil;
}

- (void)foreachViewControllerWithClass:(Class)cls
    handler:(void (^)(id obj))block
{
  for (YuViewController *obj in _viewControllers)
    [obj foreachViewControllerWithClass:cls handler:block];
}

- (void)addSplitView:(YuSplitView *)view identifier:(NSString *)ident
{
  [view setDelegate:self];
  _splitViews[ident] = view;
}

- (void)removeSplitView:(YuSplitView *)view identifier:(NSString *)ident
{
  [_splitViews removeObjectForKey:ident];
  [view setDelegate:nil];
}

- (void)saveWindowState
{
  if (![self isWindowLoaded] || [self window] == nil)
    return;

  NSMutableDictionary *controllers = [NSMutableDictionary dictionary];

  for (YuViewController *controller in _viewControllers)
    [controller addSavedViewState:controllers];

  NSMutableDictionary *split = [NSMutableDictionary dictionary];

  for (NSString *ident in _splitViews)
    {
      YuSplitView *view = _splitViews[ident];
      NSDictionary *sub = [view savedViewState];
      if ([sub count] != 0)
	split[ident] = sub;
    }

  NSDictionary *dict = @{
    @"YuViewControllers": controllers,
    @"YuSplitViews": split,
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

  for (YuViewController *controller in _viewControllers)
    [controller applySavedViewState:controllers];

  NSDictionary *split = [state objectForKey:@"YuSplitViews"];
  NSArray *split_keys = [[_splitViews allKeys] sortedArrayUsingSelector:
			 @selector(caseInsensitiveCompare:)];

  for (NSString *ident in split_keys)
    {
      YuSplitView *view = _splitViews[ident];
      NSDictionary *sub = split[ident];
      if (sub != nil)
	[view applySavedViewState:sub];
    }
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
