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

#import <QuartzCore/CoreAnimation.h>

#define ANIMATION_KEY @"org.unfactored.animationBlock"

@implementation CATransaction (CoreAnimationExtensions)

+ (void)animationBlock:(void (^)())thunk
{
  [self animationProperties:nil block:thunk];
}

+ (void)animationProperties:(NSDictionary *)dict block:(void (^)())thunk
{                       
  /* Note we set our main property before calling +begin, to ensure an
     implicit transaction is already active, which in turn will stop
     the following +commit from actually pushing anything to the render
     tree (unless something within the call to thunk() called +flush).
     Yes, the CATransaction API is confusing. Mea culpa. */

  BOOL inBlock = [[self valueForKey:ANIMATION_KEY] boolValue];

  if (!inBlock)
    [self setValue:@YES forKey:ANIMATION_KEY];

  [CATransaction begin];

  for (NSString *key in dict)
    [self setValue:[dict objectForKey:key] forKey:key];

  thunk();

  [CATransaction commit];

  if (!inBlock)
    [self setValue:@NO forKey:ANIMATION_KEY];
}

+ (id)actionForLayer:(CALayer *)layer forKey:(NSString *)key
{
  if ([[self valueForKey:ANIMATION_KEY] boolValue])
    return nil;
  else
    return [NSNull null];
}

@end
