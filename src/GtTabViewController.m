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

#import "GtTabViewController.h"

@implementation GtTabViewController
{
  NSInteger _indexOfSelectedView;
  GtViewController *_selectedViewController;
}

+ (NSString *)viewNibName
{
  return @"GtTabView";
}

- (id)initWithWindowController:(GtWindowController *)controller
{
  self = [super initWithWindowController:controller];
  if (self == nil)
    return nil;

  _indexOfSelectedView = 0;

  return self;
}

- (NSView *)initialFirstResponder
{
  return [self.subviewControllers[self.indexOfSelectedView]
	  initialFirstResponder];
}

- (void)viewDidLoad
{
  [self updateSegments];
}

- (void)viewWillMount
{
  [self updateSelectedView];
}

- (void)addSavedViewState:(NSMutableDictionary *)dict
{
  NSString *ident = [self identifier];
  if (ident == nil)
    return;

  NSDictionary *state = @{@"indexOfSelectedView": @(self.indexOfSelectedView)};

  dict[ident] = state;

  [super addSavedViewState:dict];
}

- (void)applySavedViewState:(NSDictionary *)dict
{
  NSString *ident = [self identifier];
  if (ident == nil)
    return;

  NSDictionary *state = dict[ident];

  if (state != nil)
    self.indexOfSelectedView = [state[@"indexOfSelectedView"] integerValue];

  [super applySavedViewState:dict];
}

- (NSInteger)indexOfSelectedView
{
  return _indexOfSelectedView;
}

- (void)setIndexOfSelectedView:(NSInteger)idx
{
  if (_indexOfSelectedView != idx)
    {
      _indexOfSelectedView = idx;

      [self updateSelectedView];
    }  
}

- (void)updateSegments
{
  NSArray *array = self.subviewControllers;
  NSInteger count = [array count];

  NSSegmentedControl *control = self.segmentedControl;

  [control setSegmentCount:count];

  for (NSInteger i = 0; i < count; i++)
    {
      GtViewController *c = array[i];
      [control setLabel:[c title] forSegment:i];
    }

  [control sizeToFit];
}

- (void)updateSelectedView
{
  NSArray *array = self.subviewControllers;
  NSInteger count = [array count];

  if ([self.segmentedControl segmentCount] != count)
    [self updateSegments];

  NSInteger idx = _indexOfSelectedView;
  GtViewController *c = idx >= 0 && idx < count ? array[idx] : nil;

  if (_selectedViewController != c)
    {
      [_selectedViewController removeFromContainer];

      _selectedViewController = c;

      [c addToContainerView:self.contentView];

      [self.segmentedControl setSelectedSegment:idx];
    }
}

- (IBAction)controlAction:(id)sender
{
  self.indexOfSelectedView = [self.segmentedControl selectedSegment];
}

- (BOOL)_isSubviewControllerVisible:(GtViewController *)c
{
  return self.subviewControllers[self.indexOfSelectedView] == c;
}

- (void)_showSubviewController:(GtViewController *)c
{
  NSInteger idx = [self.subviewControllers indexOfObjectIdenticalTo:c];
  if (idx == NSNotFound)
    return;

  self.indexOfSelectedView = idx;
}

@end
