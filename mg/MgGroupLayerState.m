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

#import "MgActiveTransition.h"
#import "MgCoreGraphics.h"
#import "MgNodeTransition.h"

#define SUPERSTATE ((MgGroupLayerState *)(self.superstate))

@implementation MgGroupLayerState
{
  BOOL _passThrough;
  BOOL _flattensSublayers;

  struct {
    bool passThrough;
    bool flattensSublayers;
  } _defines;
}

- (void)setDefaults
{
  [super setDefaults];

  _passThrough = YES;
  _flattensSublayers = NO;

  _defines.passThrough = true;
  _defines.flattensSublayers = true;
}

- (BOOL)definesValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"passThrough"])
    return _defines.passThrough;
  else if ([key isEqualToString:@"flattensSublayers"])
    return _defines.flattensSublayers;
  else
    return [super definesValueForKey:key];
}

- (void)setDefinesValue:(BOOL)flag forKey:(NSString *)key
{
  if ([key isEqualToString:@"passThrough"])
    _defines.passThrough = flag;
  else if ([key isEqualToString:@"flattensSublayers"])
    _defines.flattensSublayers = flag;
  else
    [super setDefinesValue:flag forKey:key];
}

- (void)applyTransition:(MgActiveTransition *)trans atTime:(double)t
    to:(MgNodeState *)to_
{
  MgGroupLayerState *to = (MgGroupLayerState *)to_;
  double t_;

  [super applyTransition:trans atTime:t to:to];

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"passThrough"] : t;
  _passThrough = MgBoolMix(self.passThrough, to.passThrough, t_);
  _defines.passThrough = true;

  t_ = trans != nil ? [trans evaluateTime:t forKey:@"flattensSublayers"] : t;
  _flattensSublayers = MgBoolMix(self.flattensSublayers, to.flattensSublayers, t_);
  _defines.flattensSublayers = true;
}

- (BOOL)isPassThrough
{
  if (_defines.passThrough)
    return _passThrough;
  else
    return SUPERSTATE.passThrough;
}

- (void)setPassThrough:(BOOL)flag
{
  if (_defines.passThrough)
    _passThrough = flag;
  else
    SUPERSTATE.passThrough = flag;
}

- (BOOL)flattensSublayers
{
  if (_defines.flattensSublayers)
    return _flattensSublayers;
  else
    return SUPERSTATE.flattensSublayers;
}

- (void)setFlattensSublayers:(BOOL)flag
{
  if (_defines.flattensSublayers)
    _flattensSublayers = flag;
  else
    SUPERSTATE.flattensSublayers = flag;
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgGroupLayerState *copy = [super graphCopy:map];

  copy->_passThrough = _passThrough;
  copy->_flattensSublayers = _flattensSublayers;
  copy->_defines = _defines;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_defines.passThrough)
    [c encodeBool:_passThrough forKey:@"passThrough"];

  if (_defines.flattensSublayers)
    [c encodeBool:_flattensSublayers forKey:@"flattensSublayers"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"passThrough"])
    {
      _passThrough = [c decodeBoolForKey:@"passThrough"];
      _defines.passThrough = true;
    }

  if ([c containsValueForKey:@"flattensSublayers"])
    {
      _flattensSublayers = [c decodeBoolForKey:@"flattensSublayers"];
      _defines.flattensSublayers = true;
    }

  return self;
}

@end
