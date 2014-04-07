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

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <QuartzCore/QuartzCore.h>

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
MgContextSetLineDash(CGContextRef ctx, NSArray *pattern, CGFloat phase)
{
  size_t count = [pattern count];
  if (count == 0)
    {
      CGContextSetLineDash(ctx, phase, NULL, 0);
      return;
    }

  CGFloat *vec = STACK_ALLOC(CGFloat, count);
  if (vec == NULL)
    return;

  for (size_t i = 0; i < count; i++)
    vec[i] = [pattern[i] doubleValue];

  CGContextSetLineDash(ctx, phase, vec, count);

  STACK_FREE(CGFloat, count, vec);
}

CGGradientRef
MgCreateGradient(NSArray *colors, NSArray *locations)
{
  size_t count = [colors count];
  if (count == 0)
    return NULL;

  if (locations != nil && [locations count] != count)
    locations = nil;

  CGGradientRef grad = NULL;

  if (locations == nil)
    {
      grad = CGGradientCreateWithColors(MgSRGBColorSpace(),
					(__bridge CFArrayRef)colors, NULL);
    }
  else
    {
      CGFloat *vec = STACK_ALLOC(CGFloat, count);
      if (vec != NULL)
	{
	  for (size_t i = 0; i < count; i++)
	    vec[i] = [locations[i] doubleValue];

	  grad = CGGradientCreateWithColors(MgSRGBColorSpace(),
					    (__bridge CFArrayRef)colors, vec);

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

CGPathRef
MgPathCreateWithRoundRect(CGRect rect, CGFloat radius)
{
  /* Avoid these assertions:

	corner_height >= 0 && 2 * corner_height <= CGRectGetHeight(rect)
	corner_width >= 0 && 2 * corner_width <= CGRectGetWidth(rect)

     I can't believe I'm still dealing with this crap. */

  radius = fmax(0, radius);
  radius = fmin(radius, CGRectGetWidth(rect) * (CGFloat).5 - 1e-3);
  radius = fmin(radius, CGRectGetHeight(rect) * (CGFloat).5 - 1e-3);

  return CGPathCreateWithRoundedRect(rect, radius, radius, NULL);
}

CGImageRef
MgImageCreateByDrawing(size_t w, size_t h, bool opaque,
		       void (^block)(CGContextRef ctx))
{
  CGContextRef ctx = CGBitmapContextCreate(NULL, w, h, 8, 0,
	MgSRGBColorSpace(), (opaque ? kCGImageAlphaNoneSkipFirst
	: kCGImageAlphaPremultipliedFirst) | kCGBitmapByteOrder32Host);

  if (ctx == NULL)
    return NULL;

  block(ctx);

  CGImageRef im = CGBitmapContextCreateImage(ctx);

  CGContextRelease(ctx);

  return im;
}

CFDataRef
MgImageCreateData(CGImageRef im, CFStringRef type)
{
  CFMutableDataRef data = CFDataCreateMutable(NULL, 0);
  if (data == NULL)
    return NULL;

  CGImageDestinationRef dest
    = CGImageDestinationCreateWithData(data, type, 1, NULL);

  if (dest == NULL)
    {
      CFRelease(data);
      return NULL;
    }

  CGImageDestinationAddImage(dest, im, NULL);
  CGImageDestinationFinalize(dest);
  CFRelease(dest);

  return data;
}

CGRect
MgRectMix(CGRect a, CGRect b, double t)
{
  CGFloat a_x0 = a.origin.x;
  CGFloat a_y0 = a.origin.y;
  CGFloat a_x1 = a_x0 + a.size.width;
  CGFloat a_y1 = a_y0 + a.size.height;

  CGFloat b_x0 = b.origin.x;
  CGFloat b_y0 = b.origin.y;
  CGFloat b_x1 = b_x0 + b.size.width;
  CGFloat b_y1 = b_y0 + b.size.height;

  CGFloat c_x0 = MgFloatMix(a_x0, b_x0, t);
  CGFloat c_x1 = MgFloatMix(a_x1, b_x1, t);
  CGFloat c_y0 = MgFloatMix(a_y0, b_y0, t);
  CGFloat c_y1 = MgFloatMix(a_y1, b_y1, t);

  return CGRectMake(c_x0, c_y0, c_x1 - c_x0, c_y1 - c_y0);
}

CGColorRef
MgColorMix(CGColorRef a, CGColorRef b, double t)
{
  CGColorSpaceRef space = CGColorGetColorSpace(a);

  if (CGColorGetColorSpace(b) == space)
    {
      size_t count = CGColorSpaceGetNumberOfComponents(space) + 1;

      const CGFloat *va = CGColorGetComponents(a);
      const CGFloat *vb = CGColorGetComponents(b);

      CGFloat vc[count];
      for (size_t i = 0; i < count; i++)
	vc[i] = MgFloatMix(va[i], vb[i], t);

      return CGColorCreate(space, vc);
    }
  else
    {
      /* FIXME: will this do the right thing for non-sRGB colors..? */

      CIColor *ca = [CIColor colorWithCGColor:a];
      CIColor *cb = [CIColor colorWithCGColor:b];

      CGFloat vc[4];
      vc[0] = MgFloatMix([ca red], [cb red], t);
      vc[1] = MgFloatMix([ca green], [cb green], t);
      vc[2] = MgFloatMix([ca blue], [cb blue], t);
      vc[3] = MgFloatMix([ca alpha], [cb alpha], t);

      return CGColorCreate(MgSRGBColorSpace(), vc);
    }
}

NSArray *
MgFloatArrayMix(NSArray *a, NSArray *b, double t)
{
  size_t count = [a count];
  if (count == 0 || [b count] != count)
    return t < .5 ? a : b;

  __unsafe_unretained id *a_values = STACK_ALLOC_ARC(id, count);
  __unsafe_unretained id *b_values = STACK_ALLOC_ARC(id, count);

  [a getObjects:a_values];
  [b getObjects:b_values];

  for (size_t i = 0; i < count; i++)
    a_values[i] = @(MgFloatMix([a_values[i] doubleValue], [b_values[i] doubleValue], t));

  NSArray *ret = [NSArray arrayWithObjects:a_values count:count];

  STACK_FREE(id, count, b_values);
  STACK_FREE(id, count, a_values);

  return ret;
}

NSArray *
MgColorArrayMix(NSArray *a, NSArray *b, double t)
{
  size_t count = [a count];
  if (count == 0 || [b count] != count)
    return t < .5 ? a : b;

  __unsafe_unretained id *a_values = STACK_ALLOC_ARC(id, count);
  __unsafe_unretained id *b_values = STACK_ALLOC_ARC(id, count);

  [a getObjects:a_values];
  [b getObjects:b_values];

  NSMutableArray *ret = [NSMutableArray arrayWithCapacity:count];

  for (size_t i = 0; i < count; i++)
    {
      CGColorRef c = MgColorMix((__bridge CGColorRef)a_values[i],
				(__bridge CGColorRef)b_values[i], t);
      [ret addObject:CFBridgingRelease(c)];
    }

  STACK_FREE(id, count, b_values);
  STACK_FREE(id, count, a_values);

  return ret;
}
