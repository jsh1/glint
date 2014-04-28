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

#define CONTROL_HEIGHT 20

typedef NS_ENUM(NSInteger, GtInspectorNumberControlType)
{
  GtInspectorNumberControlTypeScalar,
  GtInspectorNumberControlTypePoint,
  GtInspectorNumberControlTypeSize,
  GtInspectorNumberControlTypeRect,
};

@implementation GtInspectorNumberControl
{
  GtInspectorNumberControlType _type;
  NSInteger _rowCount;
  NSMutableArray *_sliders;		/* NSArray<NSSlider> */
  NSMutableArray *_numberFields;	/* NSArray<GtNumericTextField> */
}

static GtInspectorNumberControlType
control_type(GtInspectorItem *item)
{
  NSString *type = item.type;
  if ([type isEqualToString:@"CGPoint"])
    return GtInspectorNumberControlTypePoint;
  else if ([type isEqualToString:@"CGSize"])
    return GtInspectorNumberControlTypeSize;
  else if ([type isEqualToString:@"CGRect"])
    return GtInspectorNumberControlTypeRect;
  else
    return GtInspectorNumberControlTypeScalar;
}

static GtNumberType
number_type(GtInspectorItem *item)
{
  NSString *units = item.units;
  if ([units isEqualToString:@"pixels"])
    return GtNumberTypePixels;
  else if ([units isEqualToString:@"angle"])
    return GtNumberTypeAngle;
  else if ([units isEqualToString:@"normalized"]
	   || [units isEqualToString:@"percentage"])
    return GtNumberTypePercentage;
  else
    return GtNumberTypeUnknown;
}

static NSInteger
control_row_count(GtInspectorNumberControlType type)
{
  switch (type)
    {
    case GtInspectorNumberControlTypeScalar:
      return 1;

    case GtInspectorNumberControlTypePoint:
    case GtInspectorNumberControlTypeSize:
      return 2;

    case GtInspectorNumberControlTypeRect:
      return 4;
    }
}

+ (instancetype)controlForItem:(GtInspectorItem *)item
    delegate:(id<GtInspectorDelegate>)delegate
{
  return [[self alloc] initWithItem:item delegate:delegate];
}

+ (CGFloat)controlHeightForItem:(GtInspectorItem *)item
{
  return CONTROL_HEIGHT * control_row_count(control_type(item));
}

- (id)initWithItem:(GtInspectorItem *)item
    delegate:(id<GtInspectorDelegate>)delegate
{
  self = [super initWithItem:item delegate:delegate];
  if (self == nil)
    return nil;

  _type = control_type(item);
  _rowCount = control_row_count(_type);

  _sliders = [NSMutableArray array];
  _numberFields = [NSMutableArray array];

  CGFloat slider_min = fmax(item.min, item.sliderMin);
  CGFloat slider_max = fmin(item.max, item.sliderMax);

  if (!isfinite(slider_min))
    slider_min = 0;
  if (!isfinite(slider_max))
    {
      if ([item.units isEqual:@"pixels"])
	slider_max = 1024;
      else
	slider_max = 1;
    }

  GtNumberType numberType = number_type(item);

  for (NSInteger i = 0; i < _rowCount; i++)
    {
      NSSlider *slider = [[NSSlider alloc] initWithFrame:NSZeroRect];

      [[slider cell] setControlSize:NSMiniControlSize];
      [slider setContinuous:YES];
      [slider setNumberOfTickMarks:5];
      [slider setTickMarkPosition:NSTickMarkBelow];
      [slider setMinValue:slider_min];
      [slider setMaxValue:slider_max];
      [slider setAction:@selector(takeValue:)];
      [slider setTarget:self];

      [_sliders addObject:slider];
      [self addSubview:slider];

      GtNumericTextField *field = [[GtNumericTextField alloc]
				   initWithFrame:NSZeroRect];

      field.type = numberType;

      [[field cell] setControlSize:NSSmallControlSize];
      [[field cell] setVerticallyCentered:YES];
//      [field setAlignment:NSCenterTextAlignment];
      [field setFont:
       [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
      [field setDrawsBackground:NO];
      [field setBordered:NO];
      [field setMinValue:item.min];
      [field setMaxValue:item.max];
      [field setIncrement:item.increment];
      [field setAction:@selector(takeValue:)];
      [field setTarget:self];

      [_numberFields addObject:field];
      [self addSubview:field];
    }

  return self;
}

- (BOOL)isEnabled
{
  return [_sliders[0] isEnabled];
}

- (void)setEnabled:(BOOL)flag
{
  for (NSInteger i = 0; i < _rowCount; i++)
    {
      [_numberFields[i] setEnabled:flag];
      [_sliders[i] setEnabled:flag];
    }
}

- (id)objectValue
{
  if (_type == GtInspectorNumberControlTypeScalar)
    {
      return [_numberFields[0] objectValue];
    }
  else
    {
      CGFloat vec[_rowCount];
      for (NSInteger i = 0; i < _rowCount; i++)
	vec[i] = [[_numberFields[i] objectValue] doubleValue];

      if (_type == GtInspectorNumberControlTypePoint)
	return [NSValue valueWithBytes:vec objCType:@encode(CGPoint)];
      else if (_type == GtInspectorNumberControlTypeSize)
	return [NSValue valueWithBytes:vec objCType:@encode(CGSize)];
      else if (_type == GtInspectorNumberControlTypeRect)
	return [NSValue valueWithBytes:vec objCType:@encode(CGRect)];
      else
	return nil;
    }
}

- (void)setObjectValue:(id)obj
{
  if (obj == nil)
    {
      for (NSInteger i = 0; i < _rowCount; i++)
	[_numberFields[i] setObjectValue:nil];
    }
  else if (_type == GtInspectorNumberControlTypeScalar)
    {
      [_numberFields[0] setObjectValue:obj];
    }
  else
    {
      CGFloat vec[_rowCount];
      [obj getValue:vec];

      for (NSInteger i = 0; i < _rowCount; i++)
	[_numberFields[i] setObjectValue:@(vec[i])];
    }

  for (NSInteger i = 0; i < _rowCount; i++)
    [_sliders[i] setObjectValue:[_numberFields[i] objectValue]];
}

- (void)layoutSubviews
{
  NSRect lc = [self leftColumnRect];
  NSRect rc = [self rightColumnRect];

  CGFloat y = lc.origin.y + lc.size.height;
  for (NSInteger i = 0; i < _rowCount; i++)
    {
      y -= CONTROL_HEIGHT;
      [_numberFields[i] setFrame:
       NSMakeRect(lc.origin.x, y, lc.size.width, CONTROL_HEIGHT)];
      [_sliders[i] setFrame:
       NSMakeRect(rc.origin.x, y, rc.size.width, CONTROL_HEIGHT)];
    }
}

- (IBAction)takeValue:(id)sender
{
  for (NSInteger i = 0; i < _rowCount; i++)
    {  
      if (sender == _sliders[i])
	[_numberFields[i] takeObjectValueFrom:sender];
      else if (sender == _numberFields[i])
	[_sliders[i] takeObjectValueFrom:sender];
    }

  [super takeValue:sender];
}

@end
