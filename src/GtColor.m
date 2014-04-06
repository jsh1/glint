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

#import "GtColor.h"

#define BG_HUE (204./360.)

@implementation GtColor

+ (NSColor *)windowBackgroundColor
{
  static NSColor *color;

  if (color == nil)
    {
      color = [NSColor colorWithCalibratedHue:BG_HUE
	       saturation:.02 brightness:.9 alpha:1];
    }

  return color;
}

+ (NSColor *)viewerBackgroundColor
{
  static NSColor *color;

  if (color == nil)
    {
      color = [NSColor colorWithCalibratedHue:BG_HUE
	       saturation:.2 brightness:.25 alpha:1];
    }

  return color;
}

+ (NSColor *)viewerBorderColor
{
  static NSColor *color;

  if (color == nil)
    {
      color = [NSColor colorWithCalibratedHue:BG_HUE
	       saturation:.2 brightness:.1 alpha:.7];
    }

  return color;
}

+ (NSColor *)timelineItemFillColor
{
  static NSColor *color;

  if (color == nil)
    {
      color = [NSColor colorWithCalibratedHue:BG_HUE
	       saturation:.3 brightness:1 alpha:1];
    }

  return color;
}

+ (NSColor *)timelineItemStrokeColor
{
  static NSColor *color;

  if (color == nil)
    color = [NSColor colorWithDeviceWhite:.2 alpha:.7];

  return color;
}

@end
