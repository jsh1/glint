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

#import "GtNumberFormatter.h"

@implementation GtNumberFormatter
{
  GtNumberType _type;
}

- (NSString *)stringForObjectValue:(id)obj
{
  if (obj == nil)
    return @"n/a";

  const char *suffix = "";
  double value = [obj doubleValue];

  int frac_prec = 1;

  switch (_type)
    {
    case GtNumberTypeUnknown:
      break;

    case GtNumberTypePixels:
      suffix = " px";
      break;

    case GtNumberTypeAngle:
      suffix = "°";
      value = value * (180 / M_PI);
      break;

    case GtNumberTypePercentage:
      suffix = "%";
      value = value * 100;
      break;
    }

  double mul = __exp10(frac_prec);

  double rounded_value = round(value * mul) / mul;

  if (floor(rounded_value) == rounded_value)
    frac_prec = 0;

  char buf[256];
  snprintf(buf, sizeof(buf), "%.*f%s", frac_prec, rounded_value, suffix);

  return [[NSString alloc] initWithUTF8String:buf];
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string
    errorDescription:(out NSString **)error
{
  const char *str = [string UTF8String];
  char *end = NULL;
  double value = strtod(str, &end);

  switch (_type)
    {
    case GtNumberTypeAngle:
      value = value * (M_PI / 180);
      break;

    case GtNumberTypePercentage:
      value = value * 0.01;
      break;

    default:
      break;
    }

  *obj = [NSNumber numberWithDouble:value];

  return YES;
}


@end
