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

#import "GtInspectorColorControl.h"

#define COLOR_WELL_WIDTH 40
#define COLOR_WELL_HEIGHT 20

@implementation GtInspectorColorControl
{
  NSColorWell *_colorWell;
}

+ (void)initialize
{
  if (self == [GtInspectorColorControl class])
    {
      [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    }
}

+ (instancetype)controlForItem:(GtInspectorItem *)item
    delegate:(id<GtInspectorDelegate>)delegate
{
  return [[self alloc] initWithItem:item delegate:delegate];
}

+ (CGFloat)controlHeightForItem:(GtInspectorItem *)item
{
  return COLOR_WELL_HEIGHT;
}

- (id)initWithItem:(GtInspectorItem *)item
    delegate:(id<GtInspectorDelegate>)delegate
{
  self = [super initWithItem:item delegate:delegate];
  if (self == nil)
    return nil;

  _colorWell = [[NSColorWell alloc] initWithFrame:NSZeroRect];

  [[_colorWell cell] setControlSize:NSSmallControlSize];
  [_colorWell setAction:@selector(takeValue:)];
  [_colorWell setTarget:self];

  [self addSubview:_colorWell];

  return self;
}

- (id)objectValue
{
  return (__bridge id)[[_colorWell color] CGColor];
}

- (void)setObjectValue:(id)obj
{
  [_colorWell setColor:[NSColor colorWithCGColor:(__bridge CGColorRef)obj]];
}

- (void)layoutSubviews
{
  NSRect r = [self leftColumnRect];

  NSRect cr = NSMakeRect(0, 0, COLOR_WELL_WIDTH, COLOR_WELL_HEIGHT);
  cr.origin.x = round((r.size.width - COLOR_WELL_WIDTH) * .5);
  cr.origin.y = round((r.size.height - COLOR_WELL_HEIGHT) * .5);

  [_colorWell setFrame:cr];
}

@end
