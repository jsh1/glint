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

#import "MgCoreGraphics.h"

#import "MgMacros.h"

CGColorRef
MgBlackColor(void)
{
  static CGColorRef color;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      CGFloat vec[4] = {0, 0, 0, 1};
      color = CGColorCreate(MgSRGBColorSpace(), vec);
    });

  return color;
}

CGColorRef
MgWhiteColor(void)
{
  static CGColorRef color;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      CGFloat vec[4] = {1, 1, 1, 1};
      color = CGColorCreate(MgSRGBColorSpace(), vec);
    });

  return color;
}

CGColorRef
MgCreateSRGBColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a)
{
  CGFloat vec[4] = {r, g, b, a};
  return CGColorCreate(MgSRGBColorSpace(), vec);
}

CGColorSpaceRef
MgSRGBColorSpace(void)
{
  static CGColorSpaceRef color_space;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      color_space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    });

  return color_space;
}

void
MgContextSetLineDash(CGContextRef ctx, CFArrayRef pattern, CGFloat phase)
{
  if (pattern == NULL)
    {
      CGContextSetLineDash(ctx, phase, NULL, 0);
      return;
    }

  size_t count = CFArrayGetCount(pattern);
  if (count == 0)
    {
      CGContextSetLineDash(ctx, phase, NULL, 0);
      return;
    }

  CGFloat *vec = STACK_ALLOC(CGFloat, count);
  if (vec == NULL)
    return;

  for (size_t i = 0; i < count; i++)
    {
      CFNumberGetValue(CFArrayGetValueAtIndex(pattern, i),
		       kCFNumberCGFloatType, &vec[i]);
    }

  CGContextSetLineDash(ctx, phase, vec, count);

  STACK_FREE(CGFloat, count, vec);
}

CGGradientRef
MgCreateGradient(CFArrayRef colors, CFArrayRef locations)
{
  if (colors == NULL)
    return NULL;

  size_t count = CFArrayGetCount(colors);

  if (locations != NULL && CFArrayGetCount(locations) != count)
    locations = NULL;

  CGGradientRef grad = NULL;

  if (locations == NULL)
    {
      grad = CGGradientCreateWithColors(MgSRGBColorSpace(), colors, NULL);
    }
  else
    {
      CGFloat *vec = STACK_ALLOC(CGFloat, count);
      if (vec != NULL)
	{
	  for (size_t i = 0; i < count; i++)
	    {
	      CFNumberGetValue(CFArrayGetValueAtIndex(locations, i),
			       kCFNumberCGFloatType, &vec[i]);
	    }

	  grad = CGGradientCreateWithColors(MgSRGBColorSpace(), colors, vec);

	  STACK_FREE(CGFloat, count, vec);
	}
    }

  return grad;
}

bool
MgAffineTransformIsRectilinear(const CGAffineTransform *m)
{
  if (m->a == 0 && m->d == 0)
    return true;
  else if (m->b == 0 && m->c == 0)
    return true;
  else
    return false;
}

void
MgRectGetCorners(CGRect r, CGPoint p[4])
{
  p[0] = r.origin;
  p[1] = CGPointMake(p[0].x + r.size.width, p[0].y);
  p[2] = CGPointMake(p[1].x, p[0].y + r.size.height);
  p[3] = CGPointMake(p[0].x, p[2].y);
}
