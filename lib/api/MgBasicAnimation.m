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

#import "MgBasicAnimation.h"

#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgBasicAnimation
{
  NSString *_keyPath;
  id<NSSecureCoding> _fromValue;
  id<NSSecureCoding> _toValue;
}

+ (BOOL)automaticallyNotifiesObserversOfFromValue
{
  return NO;
}

- (id<NSSecureCoding>)fromValue
{
  return _fromValue;
}

- (void)setFromValue:(id<NSSecureCoding>)obj
{
  if (_fromValue != obj)
    {
      [self willChangeValueForKey:@"fromValue"];
      _fromValue = obj;
      [self incrementVersion];
      [self didChangeValueForKey:@"fromValue"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfToValue
{
  return NO;
}

- (id<NSSecureCoding>)toValue
{
  return _toValue;
}

- (void)setToValue:(id<NSSecureCoding>)obj
{
  if (_toValue != obj)
    {
      [self willChangeValueForKey:@"toValue"];
      _toValue = obj;
      [self incrementVersion];
      [self didChangeValueForKey:@"toValue"];
    }
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgBasicAnimation *copy = [super copyWithZone:zone];

  copy->_keyPath = [_keyPath copy];
  copy->_fromValue = _fromValue;
  copy->_toValue = _toValue;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_keyPath != nil)
    [c encodeObject:_keyPath forKey:@"keyPath"];

  if (_fromValue != nil)
    [c encodeObject:_fromValue forKey:@"fromValue"];

  if (_toValue != nil)
    [c encodeObject:_toValue forKey:@"toValue"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"keyPath"])
    _keyPath = [c decodeObjectOfClass:[NSString class] forKey:@"keyPath"];

  if ([c containsValueForKey:@"fromValue"])
    _fromValue = [c decodeObjectOfClass:[NSObject class] forKey:@"fromValue"];

  if ([c containsValueForKey:@"toValue"])
    _toValue = [c decodeObjectOfClass:[NSObject class] forKey:@"toValue"];

  return self;
}

@end
