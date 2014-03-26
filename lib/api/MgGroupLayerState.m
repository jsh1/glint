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

#import "MgGroupLayerState.h"

#import <Foundation/Foundation.h>

#import "MgNodeTransition.h"

#define SUPERSTATE ((MgGroupLayerState *)(self.superstate))

@implementation MgGroupLayerState
{
  BOOL _group;

  struct {
    bool group;
  } _defines;
}

- (void)setDefaults
{
  [super setDefaults];

  _group = NO;

  _defines.group = true;
}

- (BOOL)definesValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"group"])
    return _defines.group;
  else
    return [super definesValueForKey:key];
}

- (void)setDefinesValue:(BOOL)flag forKey:(NSString *)key
{
  if ([key isEqualToString:@"group"])
    _defines.group = flag;
  else
    [super setDefinesValue:flag forKey:key];
}

- (void)applyTransition:(MgNodeTransition *)trans atTime:(double)t
    to:(MgNodeState *)to_
{
  MgGroupLayerState *to = (MgGroupLayerState *)to_;
  double t_;

  [super applyTransition:trans atTime:t to:to];

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"group"] : t;
  _group = t_ < .5 ? self.group : to.group;
  _defines.group = true;
}

- (BOOL)isGroup
{
  if (_defines.group)
    return _group;
  else
    return SUPERSTATE.group;
}

- (void)setGroup:(BOOL)flag
{
  if (_defines.group)
    _group = flag;
  else
    SUPERSTATE.group = flag;
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgGroupLayerState *copy = [super graphCopy:map];

  copy->_group = _group;
  copy->_defines = _defines;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_defines.group)
    [c encodeBool:_group forKey:@"group"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"group"])
    {
      _group = [c decodeBoolForKey:@"group"];
      _defines.group = true;
    }

  return self;
}

@end
