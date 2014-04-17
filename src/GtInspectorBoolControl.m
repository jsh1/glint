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

#import "GtInspectorBoolControl.h"

#define BUTTON_WIDTH 20
#define BUTTON_HEIGHT 20

@implementation GtInspectorBoolControl
{
  NSButton *_button;
}

+ (instancetype)controlForItem:(GtInspectorItem *)item
    delegate:(id<GtInspectorDelegate>)delegate
{
  return [[self alloc] initWithItem:item delegate:delegate];
}

+ (CGFloat)controlHeightForItem:(GtInspectorItem *)item
{
  return BUTTON_HEIGHT;
}

- (id)initWithItem:(GtInspectorItem *)item
    delegate:(id<GtInspectorDelegate>)delegate
{
  self = [super initWithItem:item delegate:delegate];
  if (self == nil)
    return nil;

  _button = [[NSButton alloc] initWithFrame:NSZeroRect];

  [_button setButtonType:NSSwitchButton];
  [_button setTitle:@""];
  [[_button cell] setControlSize:NSSmallControlSize];
  [_button setAlignment:NSCenterTextAlignment];
  [_button setAction:@selector(takeValue:)];
  [_button setTarget:self];

  [self addSubview:_button];

  return self;
}

- (BOOL)isEnabled
{
  return [_button isEnabled];
}

- (void)setEnabled:(BOOL)flag
{
  [_button setEnabled:flag];
}

- (id)objectValue
{
  NSInteger state = [_button state];

  if (state == NSOnState)
    return @YES;
  else if (state == NSOffState)
    return @NO;
  else
    return nil;
}

- (void)setObjectValue:(id)obj
{
  [_button setState:obj != nil ? [obj boolValue] : NSMixedState];
}

- (void)layoutSubviews
{
  NSRect r = [self leftColumnRect];

  NSRect br = NSMakeRect(0, 0, BUTTON_WIDTH, BUTTON_HEIGHT);
  br.origin.x = round((r.size.width - BUTTON_WIDTH) * .5);
  br.origin.y = round((r.size.height - BUTTON_HEIGHT) * .5);

  [_button setFrame:br];
}

@end
