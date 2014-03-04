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

#import "YuViewController.h"

#import "YuWindowController.h"

@implementation YuViewController
{
  __weak YuWindowController *_controller;
  __weak YuViewController *_superviewController;
  NSMutableArray *_subviewControllers;
  NSString *_identifierSuffix;
  BOOL _viewHasBeenLoaded;
}

@synthesize controller = _controller;
@synthesize identifierSuffix = _identifierSuffix;
@synthesize superviewController = _superviewController;
@synthesize viewHasBeenLoaded = _viewHasBeenLoaded;

+ (NSString *)viewNibName
{
  return nil;
}

- (id)initWithController:(YuWindowController *)controller
{
  self = [super initWithNibName:[[self class] viewNibName]
	  bundle:[NSBundle mainBundle]];
  if (self == nil)
    return nil;

  _controller = controller;
  _subviewControllers = [[NSMutableArray alloc] init];

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
}

- (YuDocument *)document
{
  return _controller.document;
}

- (NSString *)identifier
{
  NSString *ident = NSStringFromClass([self class]);

  if (_identifierSuffix != nil)
    ident = [ident stringByAppendingString:_identifierSuffix];

  return ident;
}

- (YuViewController *)viewControllerWithClass:(Class)cls
{
  if ([self class] == cls)
    return self;

  for (YuViewController *obj in _subviewControllers)
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
  if ([self isKindOfClass:cls])
    block(self);

  for (YuViewController *obj in _subviewControllers)
    [obj foreachViewControllerWithClass:cls handler:block];
}

- (NSArray *)subviewControllers
{
  return _subviewControllers;
}

- (void)setSubviewControllers:(NSArray *)array
{
  for (YuViewController *c in _subviewControllers)
    c->_superviewController = nil;

  _subviewControllers = [array mutableCopy];

  for (YuViewController *c in _subviewControllers)
    c->_superviewController = self;
}

- (void)addSubviewController:(YuViewController *)controller
{
  [_subviewControllers addObject:controller];
  controller->_superviewController = self;
}

- (void)addSubviewController:(YuViewController *)controller
    after:(YuViewController *)pred
{
  NSInteger idx = [_subviewControllers indexOfObjectIdenticalTo:pred];

  if (idx != NSNotFound)
    [_subviewControllers insertObject:controller atIndex:idx+1];
  else
    [_subviewControllers addObject:controller];

  controller->_superviewController = self;
}

- (void)removeSubviewController:(YuViewController *)controller
{
  NSInteger idx = [_subviewControllers indexOfObjectIdenticalTo:controller];

  if (idx != NSNotFound)
    {
      controller->_superviewController = nil;
      [_subviewControllers removeObjectAtIndex:idx];
    }
}

- (NSView *)initialFirstResponder
{
  return nil;
}

- (void)viewDidLoad
{
}

- (void)loadView
{
  [super loadView];

  _viewHasBeenLoaded = YES;

  if ([self view] != nil)
    [self viewDidLoad];
}

- (void)viewWillAppear
{
}

- (void)viewDidAppear
{
}

- (void)viewWillDisappear
{
}

- (void)viewDidDisappear
{
}

- (void)addSavedViewState:(NSMutableDictionary *)dict
{
  for (YuViewController *controller in _subviewControllers)
    [controller addSavedViewState:dict];
}

- (void)applySavedViewState:(NSDictionary *)dict
{
  for (YuViewController *controller in _subviewControllers)
    [controller applySavedViewState:dict];
}

- (void)addToContainerView:(NSView *)superview
{
  NSView *view = [self view];

  if (view != nil)
    {
      assert([view superview] == nil);

      [view setFrame:[superview bounds]];

      [self viewWillAppear];

      [superview addSubview:view];

      [self viewDidAppear];
    }
}

- (void)removeFromContainer
{
  [self viewWillDisappear];

  [[self view] removeFromSuperview];

  [self viewDidDisappear];
}

@end
