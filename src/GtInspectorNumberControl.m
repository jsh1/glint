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

#import "GtInspectorNumberControl.h"

#import "GtInspectorItem.h"
#import "GtNumericTextField.h"

#import "AppKitExtensions.h"

@implementation GtInspectorNumberControl
{
  NSSlider *_slider;
  GtNumericTextField *_numberField;
}

+ (instancetype)controlForItem:(GtInspectorItem *)item
    controller:(GtInspectorViewController *)controller
{
  return [[self alloc] initWithItem:item controller:controller];
}

+ (CGFloat)controlHeightForItem:(GtInspectorItem *)item
{
  return 20;
}

- (id)initWithItem:(GtInspectorItem *)item
    controller:(GtInspectorViewController *)controller
{
  self = [super initWithItem:item controller:controller];
  if (self == nil)
    return nil;

  _slider = [[NSSlider alloc] initWithFrame:NSZeroRect];

  [[_slider cell] setControlSize:NSMiniControlSize];
  [_slider setContinuous:YES];
  [_slider setNumberOfTickMarks:5];
  [_slider setTickMarkPosition:NSTickMarkBelow];
  [_slider setMinValue:fmax(item.min, item.sliderMin)];
  [_slider setMaxValue:fmin(item.max, item.sliderMax)];
  [_slider setAction:@selector(takeValue:)];
  [_slider setTarget:self];

  [self addSubview:_slider];

  _numberField = [[GtNumericTextField alloc] initWithFrame:NSZeroRect];

  [[_numberField cell] setControlSize:NSSmallControlSize];
  [[_numberField cell] setVerticallyCentered:YES];
  [_numberField setAlignment:NSCenterTextAlignment];
  [_numberField setFont:
   [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  [_numberField setDrawsBackground:NO];
  [_numberField setBordered:NO];
  [_numberField setMinValue:item.min];
  [_numberField setMaxValue:item.max];
  [_numberField setIncrement:item.increment];
  [_numberField setAction:@selector(takeValue:)];
  [_numberField setTarget:self];

  [self addSubview:_numberField];

  return self;
}

- (id)objectValue
{
  return _numberField.objectValue;
}

- (void)setObjectValue:(id)obj
{
  _numberField.objectValue = obj;
  _slider.objectValue = obj;
}

- (void)layoutSubviews
{
  NSRect r = [self bounds];

  NSRect r1, r2;
  NSDivideRect(r, &r1, &r2, [GtInspectorControl controlWidth], NSMinXEdge);

  [_numberField setFrame:r1];
  [_slider setFrame:NSInsetRect(r2, 8, 0)];
}

- (IBAction)takeValue:(id)sender
{
  if (sender == _slider)
    [_numberField takeObjectValueFrom:sender];
  else if (sender == _numberField)
    [_slider takeObjectValueFrom:sender];

  [super takeValue:sender];
}

@end
