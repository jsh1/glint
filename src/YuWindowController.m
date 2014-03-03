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

@implementation YuWindowController
{
  NSMutableArray *_viewControllers;
  NSMutableDictionary *_splitViews;
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

  [self applySavedWindowState];

#if 0
  [window setInitialFirstResponder:
   [[self viewControllerWithClass:[YuCanvasViewController class]]
    initialFirstResponder]];
#endif

  [window makeFirstResponder:[window initialFirstResponder]];
}

- (YuViewController *)viewControllerWithClass:(Class)cls
{
  for (YuViewController *obj in _viewControllers)
    {
      YuViewController *sub = [obj viewControllerWithClass:cls];
      if (sub != nil)
	return sub;
    }

  return nil;
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

@end
