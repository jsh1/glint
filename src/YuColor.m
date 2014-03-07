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

#import "YuColor.h"

@implementation YuColor

+ (NSColor *)windowBackgroundColor
{
  return [NSColor colorWithCalibratedWhite:.9 alpha:1];
}

+ (NSArray *)controlAlternatingRowBackgroundColors
{
  static NSArray *colors;

  if (colors == nil)
    {
      colors = @[
	[self colorWithCalibratedWhite:.85 alpha:1],
	[self colorWithCalibratedWhite:.8 alpha:1],
      ];
    }

  return colors;
}

+ (NSColor *)viewerBackgroundColor
{
  static NSColor *color;

  if (color == nil)
    color = [NSColor colorWithCalibratedWhite:.4 alpha:1];

  return color;
}

+ (NSColor *)viewerOverlayColor
{
  static NSColor *color;

  if (color == nil)
    color = [NSColor colorWithCalibratedRed:255/255. green:244/255. blue:0/255. alpha:1];

  return color;
}

@end
