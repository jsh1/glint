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

#import "MgCoderExtensions.h"

#import <Foundation/Foundation.h>

@implementation NSCoder (MgCoderExtensions)

- (void)mg_encodeCGPoint:(CGPoint)p forKey:(NSString *)key
{
  [self encodeObject:[NSValue valueWithBytes:&p objCType:@encode(CGPoint)] forKey:key];
}

- (void)mg_encodeCGSize:(CGSize)s forKey:(NSString *)key
{
  [self encodeObject:[NSValue valueWithBytes:&s objCType:@encode(CGSize)] forKey:key];
}

- (void)mg_encodeCGRect:(CGRect)r forKey:(NSString *)key
{
  [self encodeObject:[NSValue valueWithBytes:&r objCType:@encode(CGRect)] forKey:key];
}

- (void)mg_encodeCGAffineTransform:(CGAffineTransform)m forKey:(NSString *)key
{
  [self encodeObject:[NSValue valueWithBytes:&m objCType:@encode(CGAffineTransform)] forKey:key];
}

struct mgColorComponents
{
  CGFloat rgba[4];
};

- (void)mg_encodeCGColor:(CGColorRef)c forKey:(NSString *)key
{
  /* Need an intermediary that can serialize the color. CIColor
     doesn't handle pattern colors, but should be okay otherwise. */

  [self encodeObject:[CIColor colorWithCGColor:c] forKey:key];
}

- (void)mg_encodeCGPath:(CGPathRef)p forKey:(NSString *)key
{
  /* FIXME: implement this. */
}

static BOOL
decodeType(NSCoder *c, NSString *key, const char *type, void *ptr)
{
  NSValue *v = [c decodeObjectOfClass:[NSValue class] forKey:key];
  if (strcmp([v objCType], type) != 0)
    return NO;
  [v getValue:ptr];
  return YES;
}

- (CGPoint)mg_decodeCGPointForKey:(NSString *)key
{
  CGPoint p;
  if (decodeType(self, key, @encode(CGPoint), &p))
    return p;
  else
    return CGPointZero;
}

- (CGSize)mg_decodeCGSizeForKey:(NSString *)key
{
  CGSize s;
  if (decodeType(self, key, @encode(CGSize), &s))
    return s;
  else
    return CGSizeZero;
}

- (CGRect)mg_decodeCGRectForKey:(NSString *)key
{
  CGRect r;
  if (decodeType(self, key, @encode(CGRect), &r))
    return r;
  else
    return CGRectNull;
}

- (CGAffineTransform)mg_decodeCGAffineTransformForKey:(NSString *)key
{
  CGAffineTransform m;
  if (decodeType(self, key, @encode(CGAffineTransform), &m))
    return m;
  else
    return CGAffineTransformIdentity;
}

- (CGColorRef)mg_decodeCGColorForKey:(NSString *)key
{
  CIColor *tem = [self decodeObjectOfClass:[CIColor class] forKey:key];
  if (tem != nil)
    return CGColorCreate([tem colorSpace], [tem components]);
  else
    return NULL;
}

- (CGPathRef)mg_decodeCGPathForKey:(NSString *)key
{
  /* FIXME: implement this. */

  return NULL;
}

@end
