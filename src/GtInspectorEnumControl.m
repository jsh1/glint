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

#import "GtInspectorEnumControl.h"

#import "GtInspectorItem.h"

#define BUTTON_HEIGHT 22

@implementation GtInspectorEnumControl
{
  NSPopUpButton *_button;
}

+ (instancetype)controlForItem:(GtInspectorItem *)item
    controller:(GtInspectorViewController *)controller
{
  return [[self alloc] initWithItem:item controller:controller];
}

+ (CGFloat)controlHeightForItem:(GtInspectorItem *)item
{
  return BUTTON_HEIGHT;
}

- (id)initWithItem:(GtInspectorItem *)item
    controller:(GtInspectorViewController *)controller
{
  self = [super initWithItem:item controller:controller];
  if (self == nil)
    return nil;

  _button = [[NSPopUpButton alloc] initWithFrame:NSZeroRect];

  [[_button cell] setControlSize:NSSmallControlSize];
  [[_button cell] setArrowPosition:NSPopUpArrowAtBottom];
  [_button setBezelStyle:NSSmallSquareBezelStyle];
  [_button setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  [_button setAlignment:NSCenterTextAlignment];
  [_button setAction:@selector(takeValue:)];
  [_button setTarget:self];

  NSArray *order = item.displayOrder;
  if (order != nil)
    {
      NSArray *values = item.values;
      for (NSNumber *n in order)
	{
	  NSInteger x = [n integerValue];
	  if (x >= 0)
	    {
	      [_button addItemWithTitle:values[x]];
	      [[[_button itemArray] lastObject] setTag:x];
	    }
	  else
	    [[_button menu] addItem:[NSMenuItem separatorItem]];
	}
    }
  else
    {
      NSInteger idx = 0;
      for (NSString *name in item.values)
	{
	  if ([name length] != 0)
	    {
	      [_button addItemWithTitle:name];
	      [[[_button itemArray] lastObject] setTag:idx];
	    }
	  idx++;
	}
    }

  [self addSubview:_button];

  return self;
}

- (id)objectValue
{
  return @([[_button selectedItem] tag]);
}

- (void)setObjectValue:(id)obj
{
  if (obj == nil)
    [_button selectItem:nil];
  else
    [_button selectItemWithTag:[obj integerValue]];
}

- (void)layoutSubviews
{
  [_button setFrame:[self rightColumnRect]];
}

@end
