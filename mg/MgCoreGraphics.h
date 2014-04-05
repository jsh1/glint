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

#import "MgBase.h"

MG_EXTERN_C_BEGIN

MG_EXTERN CGColorRef MgBlackColor(void);
MG_EXTERN CGColorRef MgWhiteColor(void);

MG_EXTERN CGColorRef MgCreateSRGBColor(CGFloat r, CGFloat g, CGFloat b,
    CGFloat a) CF_RETURNS_RETAINED;

MG_EXTERN CGColorSpaceRef MgSRGBColorSpace(void);

MG_EXTERN void MgContextSetLineDash(CGContextRef ctx, NSArray *pattern,
    CGFloat phase);

MG_EXTERN CGGradientRef MgCreateGradient(NSArray *colors, NSArray *locations)
    CF_RETURNS_RETAINED;

MG_EXTERN bool MgAffineTransformIsRectilinear(const CGAffineTransform *m);

MG_EXTERN void MgRectGetCorners(CGRect r, CGPoint p[4]);

MG_EXTERN CGPathRef MgPathCreateWithRoundRect(CGRect rect, CGFloat radius)
    CF_RETURNS_RETAINED;

MG_EXTERN CGImageRef MgImageCreateByDrawing(size_t w, size_t, bool opaque,
    void (^block)(CGContextRef ctx)) CF_RETURNS_RETAINED;

MG_EXTERN CFDataRef MgImageCreateData(CGImageRef im, CFStringRef type)
    CF_RETURNS_RETAINED;

MG_INLINE CGFloat MgFloatMix(CGFloat a, CGFloat b, double t) {
  return a + (b - a) * t;
}

MG_INLINE bool MgBoolMix(bool a, bool b, double t) {
  return t < .5 ? a : b;
}

MG_INLINE CGPoint MgPointMix(CGPoint a, CGPoint b, double t) {
  CGPoint c;
  c.x = MgFloatMix(a.x, b.x, t);
  c.y = MgFloatMix(a.y, b.y, t);
  return c;
}

MG_INLINE CGSize MgSizeMix(CGSize a, CGSize b, double t) {
  CGSize c;
  c.width = MgFloatMix(a.width, b.width, t);
  c.height = MgFloatMix(a.height, b.height, t);
  return c;
}

MG_EXTERN CGRect MgRectMix(CGRect a, CGRect b, double t);

MG_EXTERN CGColorRef MgColorMix(CGColorRef a, CGColorRef b, double t)
    CF_RETURNS_RETAINED;

MG_EXTERN NSArray *MgFloatArrayMix(NSArray *a, NSArray *b, double t);

MG_EXTERN NSArray *MgColorArrayMix(NSArray *a, NSArray *b, double t);

MG_EXTERN_C_END
