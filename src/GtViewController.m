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

#import "GtWindowController.h"

@implementation GtViewController
{
  __weak GtWindowController *_windowController;
  __weak GtViewController *_superviewController;
  NSMutableArray *_subviewControllers;
  NSString *_identifierSuffix;
  BOOL _viewHasBeenLoaded;
}

@synthesize windowController = _windowController;
@synthesize identifierSuffix = _identifierSuffix;
@synthesize superviewController = _superviewController;
@synthesize viewHasBeenLoaded = _viewHasBeenLoaded;

+ (GtViewController *)viewControllerWithDictionary:(NSDictionary *)dict
    windowController:(GtWindowController *)windowController
{
  Class cls = NSClassFromString(dict[@"class"]);
  if (![cls isSubclassOfClass:self])
    return nil;

  GtViewController *c = [[cls alloc] initWithWindowController:
			 windowController];

  for (NSString *key in dict)
    {
      if ([key isEqualToString:@"class"])
	continue;

      if ([key isEqualToString:@"subviewControllers"])
	{
	  for (NSDictionary *sub_dict in dict[key])
	    {
	      GtViewController *sc = [self viewControllerWithDictionary:
				sub_dict windowController:windowController];
	      if (sc != nil)
		[c addSubviewController:sc];
	    }
	}
      else
	[c setValue:dict[key] forKey:key];
    }

  return c;
}

+ (NSString *)viewNibName
{
  return nil;
}

- (id)initWithWindowController:(GtWindowController *)windowController
{
  self = [super initWithNibName:[[self class] viewNibName]
	  bundle:[NSBundle mainBundle]];
  if (self == nil)
    return nil;

  _windowController = windowController;
  _subviewControllers = [[NSMutableArray alloc] init];

  return self;
}

- (void)invalidate
{
  for (GtViewController *obj in _subviewControllers)
    [obj invalidate];

  _windowController = nil;
  _subviewControllers = nil;

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
}

- (void)dealloc
{
  [self invalidate];
}

- (GtDocument *)document
{
  return _windowController.document;
}

- (NSString *)title
{
  return NSStringFromClass([self class]);
}

- (NSString *)identifier
{
  NSString *ident = NSStringFromClass([self class]);

  if (_identifierSuffix != nil)
    ident = [ident stringByAppendingString:_identifierSuffix];

  return ident;
}

- (GtViewController *)viewControllerWithClass:(Class)cls
{
  if ([self class] == cls)
    return self;

  for (GtViewController *obj in _subviewControllers)
    {
      GtViewController *sub = [obj viewControllerWithClass:cls];
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

  for (GtViewController *obj in _subviewControllers)
    [obj foreachViewControllerWithClass:cls handler:block];
}

- (NSArray *)subviewControllers
{
  return _subviewControllers;
}

- (void)setSubviewControllers:(NSArray *)array
{
  for (GtViewController *c in _subviewControllers)
    c->_superviewController = nil;

  _subviewControllers = [array mutableCopy];

  for (GtViewController *c in _subviewControllers)
    c->_superviewController = self;
}

- (void)addSubviewController:(GtViewController *)controller
{
  [_subviewControllers addObject:controller];
  controller->_superviewController = self;
}

- (void)addSubviewController:(GtViewController *)controller
    after:(GtViewController *)pred
{
  NSInteger idx = [_subviewControllers indexOfObjectIdenticalTo:pred];

  if (idx != NSNotFound)
    [_subviewControllers insertObject:controller atIndex:idx+1];
  else
    [_subviewControllers addObject:controller];

  controller->_superviewController = self;
}

- (void)removeSubviewController:(GtViewController *)controller
{
  NSInteger idx = [_subviewControllers indexOfObjectIdenticalTo:controller];

  if (idx != NSNotFound)
    {
      controller->_superviewController = nil;
      [_subviewControllers removeObjectAtIndex:idx];
    }
}

- (void)showSubviewController:(GtViewController *)controller
{
  while (controller != nil && controller != self)
    {
      GtViewController *parent = controller->_superviewController;
      [parent _showSubviewController:controller];
      controller = parent;
    }
}

- (void)hideSubviewController:(GtViewController *)controller
{
  while (controller != nil && controller != self)
    {
      GtViewController *parent = controller->_superviewController;
      if ([parent _hideSubviewController:controller])
	break;
      controller = parent;
    }
}

- (void)toggleSubviewController:(GtViewController *)controller
{
  GtViewController *parent = controller->_superviewController;
  if (parent == nil)
    return;

  if (![self subviewControllerIsVisible:controller])
    [self showSubviewController:controller];
  else
    [self hideSubviewController:controller];
}

- (BOOL)subviewControllerIsVisible:(GtViewController *)controller
{
  while (controller != nil && controller != self)
    {
      GtViewController *parent = controller->_superviewController;
      if (![parent _isSubviewControllerVisible:controller])
	return NO;
      controller = parent;
    }

  return YES;
}

- (BOOL)_isSubviewControllerVisible:(GtViewController *)controller
{
  return YES;
}

- (void)_showSubviewController:(GtViewController *)controller
{
}

- (BOOL)_hideSubviewController:(GtViewController *)controller
{
  return NO;
}

- (NSView *)initialFirstResponder
{
  return [self view];
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
  for (GtViewController *c in _subviewControllers)
    [c viewWillAppear];
}

- (void)viewDidAppear
{
  for (GtViewController *c in _subviewControllers)
    [c viewDidAppear];
}

- (void)viewWillDisappear
{
  for (GtViewController *c in _subviewControllers)
    [c viewWillDisappear];
}

- (void)viewDidDisappear
{
  for (GtViewController *c in _subviewControllers)
    [c viewDidDisappear];
}

- (void)addSavedViewState:(NSMutableDictionary *)dict
{
  for (GtViewController *controller in _subviewControllers)
    [controller addSavedViewState:dict];
}

- (void)applySavedViewState:(NSDictionary *)dict
{
  for (GtViewController *controller in _subviewControllers)
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
