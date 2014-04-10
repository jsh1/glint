/* -*- c-style: gnu -*-

   Copyright (c) 2013 John Harper <jsh@unfactored.org>

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

#import "GtSplitView.h"

#import "GtColor.h"

@implementation GtSplitView

@synthesize indexOfResizableSubview = _indexOfResizableSubview;

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  if (self == nil)
    return nil;

  _indexOfResizableSubview = -1;

  return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self == nil)
    return nil;

  _indexOfResizableSubview = -1;

  return self;
}

- (CGFloat)dividerThickness
{
  return 2;
}

- (void)drawDividerInRect:(NSRect)rect
{
  NSRect subR = rect;
  if (![self isVertical])
    {
      subR.size.height = 1;
      [[NSColor lightGrayColor] setFill];
      [NSBezierPath fillRect:subR];
      subR.origin.y += 1;
      [[NSColor whiteColor] setFill];
      [NSBezierPath fillRect:subR];
    }
  else
    {
      [[[self window] backgroundColor] setFill];
      [NSBezierPath fillRect:rect];
    }
}

- (NSDictionary *)savedViewState
{
  NSArray *subviews = [self subviews];
  NSRect bounds = [self bounds];
  BOOL vertical = [self isVertical];
  CGFloat size = vertical ? bounds.size.width : bounds.size.height;

  NSMutableArray *data = [NSMutableArray array];

  for (NSView *subview in subviews)
    {
      NSRect frame = [subview frame];
      CGFloat x = vertical ? frame.origin.x : frame.origin.y;
      CGFloat w = vertical ? frame.size.width : frame.size.height;
      [data addObject:[NSNumber numberWithDouble:x / size]];
      [data addObject:[NSNumber numberWithDouble:w / size]];
      [data addObject:[NSNumber numberWithBool:[subview isHidden]]];
    }

  return @{@"values": data};
}

- (void)applySavedViewState:(NSDictionary *)dict
{
  NSArray *data = dict[@"values"];

  NSArray *subviews = [self subviews];
  NSInteger count = [subviews count];

  if ([data count] != count * 3)
    {
      data = self.initialSizes;
      if ([data count] == count)
	{
	  CGFloat width[count];
	  CGFloat p[count];

	  CGFloat total_width = 0;
	  NSInteger zero_count = 0;

	  for (NSInteger i = 0; i < count; i++)
	    {
	      width[i] = [data[i] doubleValue];
	      total_width += width[i];
	      zero_count += width[i] == 0;
	    }

	  CGFloat thick = [self dividerThickness];

	  NSRect bounds = [self bounds];
	  BOOL vertical = [self isVertical];
	  CGFloat size = vertical ? bounds.size.width : bounds.size.height;
	  CGFloat zs = floor(size - ((count - 1) * thick
				     + total_width) / zero_count);

	  for (NSInteger i = 0; i < count; i++)
	    {
	      p[i] = i == 0 ? 0 : p[i-1] + width[i-1] + thick;

	      if (zero_count > 0 && zs > 0)
		{
		  if (width[i] == 0)
		    width[i] = zs;
		}
	      else
		width[i] = floor((size - (count - 1) * thick) / count);
	    }

	  width[count-1] = size - p[count-1];
	}
    }
  else
    {
      NSRect bounds = [self bounds];
      BOOL vertical = [self isVertical];
      CGFloat size = vertical ? bounds.size.width : bounds.size.height;

      for (NSInteger i = 0; i < count; i++)
	{
	  CGFloat x = round([data[i*3+0] doubleValue] * size);
	  CGFloat w = round([data[i*3+1] doubleValue] * size);
	  BOOL flag = [data[i*3+2] boolValue];

	  NSView *subview = subviews[i];
	  NSRect frame = bounds;

	  if (vertical)
	    {
	      frame.origin.x = x;
	      frame.size.width = w;
	    }
	  else
	    {
	      frame.origin.y = x;
	      frame.size.height = w;
	    }

	  [subview setHidden:flag];
	  [subview setFrame:frame];
	}
    }

  [self adjustSubviews];
}

- (BOOL)setSubview:(NSView *)subview collapsed:(BOOL)flag
{
  if (flag != [subview isHidden])
    {
      if (flag)
	{
	  BOOL all_hidden = YES;

	  for (NSView *view in [self subviews])
	    {
	      if (view != subview && ![view isHidden])
		{
		  all_hidden = NO;
		  break;
		}
	    }

	  if (all_hidden)
	    return NO;
	}

      [subview setHidden:flag];

      _collapsingSubview = subview;
      [self adjustSubviews];
      _collapsingSubview = nil;
    }

  return YES;
}

- (void)resizeSubviewsWithOldSize:(NSSize)sz
{
  NSArray *subviews = [self subviews];

  if (_indexOfResizableSubview < 0
      || _indexOfResizableSubview >= [subviews count])
    {
      [self adjustSubviews];
      return;
    }

  NSRect bounds = [self bounds];
  NSInteger count = [subviews count];
  BOOL vertical = [self isVertical];
  CGFloat thick = [self dividerThickness];
  CGFloat p = vertical ? bounds.origin.x : bounds.origin.y;

  for (NSInteger idx = 0; idx < count; idx++)
    {
      NSView *view = subviews[idx];
      if ([view isHidden])
	continue;

      NSRect frame = [view frame];

      if (vertical)
	frame.origin.y = bounds.origin.y, frame.size.height=bounds.size.height;
      else
	frame.origin.x = bounds.origin.x, frame.size.width = bounds.size.width;

      if (vertical)
	frame.origin.x = p;
      else
	frame.origin.y = p;

      if (idx == _indexOfResizableSubview)
	{
	  if (vertical)
	    frame.size.width += bounds.size.width - sz.width;
	  else
	    frame.size.height += bounds.size.height - sz.height;
	}

      [view setFrame:frame];

      if (vertical)
	p += frame.size.width + thick;
      else
	p += frame.size.height + thick;
    }
}

- (BOOL)shouldAdjustSizeOfSubview:(NSView *)subview
{
  if (_collapsingSubview != nil)
    {
      if (subview == _collapsingSubview)
	return NO;

      // If more than two subviews, only move those adjacent to the
      // [un]collapsing view.

      NSArray *subviews = [self subviews];
      NSInteger idx1 = [subviews indexOfObjectIdenticalTo:_collapsingSubview];
      NSInteger idx2 = [subviews indexOfObjectIdenticalTo:subview];

      if (abs(idx1 - idx2) > 1)
	return NO;
    }

  return YES;
}

- (CGFloat)minimumSizeOfSubview:(NSView *)subview
{
  if ([subview respondsToSelector:@selector(minSize)])
    return [subview minSize];
  else
    return 100;
}

@end
