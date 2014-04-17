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

#import "MgValueExtensions.h"

#import "MgCoreGraphics.h"

#import "MgMacros.h"

@implementation NSObject (MgValueExtensions)

- (id)mg_mixWith:(id)toValue at:(double)t
{
  CFTypeID type = CFGetTypeID((__bridge CFTypeRef)self);

  if (type == CGColorGetTypeID())
    {
      return CFBridgingRelease(MgColorMix((__bridge CGColorRef)self,
					  (__bridge CGColorRef)toValue, t));
    }
  else
    return t < .5 ? self : toValue;
}

@end

@implementation NSNumber (MgValueExtensions)

- (id)mg_mixWith:(id)toValue at:(double)t
{
  return @(MgFloatMix([self doubleValue], [toValue doubleValue], t));
}

@end

@implementation NSValue (MgValueExtensions)

- (id)mg_mixWith:(id)toValue at:(double)t
{
  const char *type = [self objCType];

  if (strcmp(type, @encode(CGPoint)) == 0)
    {
      CGPoint p1, p2;
      UNBOX(self, p1);
      UNBOX(toValue, p2);
      p1 = MgPointMix(p1, p2, t);
      return BOX(p1);
    }
  else if (strcmp(type, @encode(CGSize)) == 0)
    {
      CGSize s1, s2;
      UNBOX(self, s1);
      UNBOX(toValue, s2);
      s1 = MgSizeMix(s1, s2, t);
      return BOX(s1);
    }
  else if (strcmp(type, @encode(CGRect)) == 0)
    {
      CGRect r1, r2;
      UNBOX(self, r1);
      UNBOX(toValue, r2);
      r1 = MgRectMix(r1, r2, t);
      return BOX(r1);
    }
  else
    return [super mg_mixWith:toValue at:t];
}

@end
