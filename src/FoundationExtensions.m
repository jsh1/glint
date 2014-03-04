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

#import "FoundationExtensions.h"

#import "MgMacros.h"

/* IMPORTANT NOTE: this file is always compiled with ARC disabled. */

@implementation NSObject (FoundationExtensions)

- (void)performVoidSelector:(SEL)sel withObject:(id)arg
{
  [self performSelector:sel withObject:arg];
}

@end

@implementation NSString (FoundationExtensions)

- (BOOL)isEqualToString:(NSString *)str caseInsensitive:(BOOL)flag
{
  NSStringCompareOptions opts = flag ? NSCaseInsensitiveSearch : 0;

  return [self compare:str options:opts] == NSOrderedSame;
}

- (BOOL)hasPrefix:(NSString *)str caseInsensitive:(BOOL)flag
{
  if (!flag)
    return [self hasPrefix:str];

  NSStringCompareOptions opts
    = NSAnchoredSearch | (flag ? NSCaseInsensitiveSearch : 0);

  return [self rangeOfString:str options:opts].length != 0;
}

- (BOOL)hasPathPrefix:(NSString *)path
{
  return [self hasPathPrefix:path caseInsensitive:NO];
}

- (BOOL)hasPathPrefix:(NSString *)path caseInsensitive:(BOOL)flag
{
  NSInteger l1 = [self length];
  NSInteger l2 = [path length];

  if (l2 == 0)
    return YES;
  else if (l1 == l2)
    return [self isEqualToString:path caseInsensitive:flag];
  else if (l2 > l1)
    return NO;
  else
    return ([self characterAtIndex:l2] == '/'
	    && [self hasPrefix:path caseInsensitive:flag]);
}

- (NSString *)stringByRemovingPathPrefix:(NSString *)path
{
  return [self stringByRemovingPathPrefix:path caseInsensitive:NO];
}

- (NSString *)stringByRemovingPathPrefix:(NSString *)path
    caseInsensitive:(BOOL)flag
{
  NSInteger l1 = [self length];
  NSInteger l2 = [path length];

  if (l2 == 0)
    return self;
  else if (l1 == l2)
    return [self isEqualToString:path caseInsensitive:flag] ? @"" : self;
  else if (l2 > l1)
    return self;
  else
    return (([self characterAtIndex:l2] == '/'
	     && [self hasPrefix:path caseInsensitive:flag])
	    ? [self substringFromIndex:l2+1] : self);
}

@end

@implementation NSArray (FoundationExtensions)

- (NSArray *)mappedArray:(id (^)(id))f
{
  NSInteger count = [self count];
  if (count == 0)
    return [NSArray array];

  __unsafe_unretained id *objects = STACK_ALLOC(id, count);

  NSInteger i = 0;
  for (id obj in self)
    objects[i++] = f(obj);

  NSArray *ret = [NSArray arrayWithObjects:objects count:count];

  STACK_FREE(id, count, objects);

  return ret;
}

- (NSArray *)filteredArray:(BOOL (^)(id))f
{
  NSInteger count = [self count];
  if (count == 0)
    return [NSArray array];
  
  __unsafe_unretained id *objects = STACK_ALLOC(id, count);

  NSInteger idx = 0;
  for (id obj in self)
    {
      if (f(obj))
	objects[idx++] = obj;
    }

  NSArray *ret;
  if (idx == 0)
    ret = [NSArray array];
  else
    ret = [NSArray arrayWithObjects:objects count:idx];

  STACK_FREE(id, count, objects);

  return ret;
}

- (NSInteger)indexOfString:(NSString *)str1 caseInsensitive:(BOOL)flag
{
  NSInteger idx = 0;

  for (NSString *str2 in self)
    {
      if ([str1 isEqualToString:str2 caseInsensitive:flag])
	return idx;
      idx++;
    }

  return NSNotFound;
}

- (BOOL)containsString:(NSString *)str caseInsensitive:(BOOL)flag
{
  return [self indexOfString:str caseInsensitive:flag] != NSNotFound;
}

@end

@implementation NSSet (FoundationExtensions)

- (NSSet *)mappedSet:(id (^)(id))f
{
  NSInteger count = [self count];
  if (count == 0)
    return [NSSet set];

  __unsafe_unretained id *objects = STACK_ALLOC(id, count);

  NSInteger i = 0;
  for (id obj in self)
    objects[i++] = f(obj);

  NSSet *ret = [NSSet setWithObjects:objects count:count];

  STACK_FREE(id, count, objects);

  return ret;
}

- (NSSet *)filteredSet:(BOOL (^)(id))f
{
  NSInteger count = [self count];
  if (count == 0)
    return [NSSet set];
  
  __unsafe_unretained id *objects = STACK_ALLOC(id, count);

  NSInteger idx = 0;
  for (id obj in self)
    {
      if (f(obj))
	objects[idx++] = obj;
    }

  NSSet *ret;
  if (idx == 0)
    ret = [NSSet set];
  else
    ret = [NSSet setWithObjects:objects count:idx];

  STACK_FREE(id, count, objects);

  return ret;
}

@end
