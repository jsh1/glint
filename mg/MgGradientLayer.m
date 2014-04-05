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

#import "MgGradientLayer.h"

#import "MgCoderExtensions.h"
#import "MgCoreGraphics.h"
#import "MgGradientLayerState.h"
#import "MgLayerInternal.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

#define STATE ((MgGradientLayerState *)(self.state))

@implementation MgGradientLayer
{
  /* Cached. */
  id _gradient;				/* CGGradientRef */
}

+ (Class)stateClass
{
  return [MgGradientLayerState class];
}

+ (BOOL)automaticallyNotifiesObserversOfColors
{
  return NO;
}

- (void)setState:(MgNodeState *)state
{
  _gradient = nil;
  [super setState:state];
}

- (NSArray *)colors
{
  return STATE.colors;
}

- (void)setColors:(NSArray *)array
{
  MgGradientLayerState *state = STATE;

  if (state.colors != array && ![state.colors isEqual:array])
    {
      [self willChangeValueForKey:@"colors"];
      state.colors = [array copy];
      _gradient = nil;
      [self incrementVersion];
      [self didChangeValueForKey:@"colors"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfLocations
{
  return NO;
}

- (NSArray *)locations
{
  return STATE.locations;
}

- (void)setLocations:(NSArray *)array
{
  MgGradientLayerState *state = STATE;

  if (state.locations != array && ![state.locations isEqual:array])
    {
      [self willChangeValueForKey:@"locations"];
      state.locations = [array copy];
      _gradient = nil;
      [self incrementVersion];
      [self didChangeValueForKey:@"locations"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfRadial
{
  return NO;
}

- (BOOL)isRadial
{
  return STATE.radial;
}

- (void)setRadial:(BOOL)flag
{
  MgGradientLayerState *state = STATE;

  if (state.radial != flag)
    {
      [self willChangeValueForKey:@"radial"];
      state.radial = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"radial"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfStartPoint
{
  return NO;
}

- (CGPoint)startPoint
{
  return STATE.startPoint;
}

- (void)setStartPoint:(CGPoint)p
{
  MgGradientLayerState *state = STATE;

  if (!CGPointEqualToPoint(state.startPoint, p))
    {
      [self willChangeValueForKey:@"startPoint"];
      state.startPoint = p;
      [self incrementVersion];
      [self didChangeValueForKey:@"startPoint"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfEndPoint
{
  return NO;
}

- (CGPoint)endPoint
{
  return STATE.endPoint;
}

- (void)setEndPoint:(CGPoint)p
{
  MgGradientLayerState *state = STATE;

  if (!CGPointEqualToPoint(state.endPoint, p))
    {
      [self willChangeValueForKey:@"endPoint"];
      state.endPoint = p;
      [self incrementVersion];
      [self didChangeValueForKey:@"endPoint"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfStartRadius
{
  return NO;
}

- (CGFloat)startRadius
{
  return STATE.startRadius;
}

- (void)setStartRadius:(CGFloat)x
{
  MgGradientLayerState *state = STATE;

  if (state.startRadius != x)
    {
      [self willChangeValueForKey:@"startRadius"];
      state.startRadius = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"startRadius"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfEndRadius
{
  return NO;
}

- (CGFloat)endRadius
{
  return STATE.endRadius;
}

- (void)setEndRadius:(CGFloat)x
{
  MgGradientLayerState *state = STATE;

  if (state.endRadius != x)
    {
      [self willChangeValueForKey:@"endRadius"];
      state.endRadius = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"endRadius"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfDrawsBeforeStart
{
  return NO;
}

- (BOOL)drawsBeforeStart
{
  return STATE.drawsBeforeStart;
}

- (void)setDrawsBeforeStart:(BOOL)flag
{
  MgGradientLayerState *state = STATE;

  if (state.drawsBeforeStart != flag)
    {
      [self willChangeValueForKey:@"drawsBeforeStart"];
      state.drawsBeforeStart = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"drawsBeforeStart"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfDrawsAfterEnd
{
  return NO;
}

- (BOOL)drawsAfterEnd
{
  return STATE.drawsAfterEnd;
}

- (void)setDrawsAfterEnd:(BOOL)flag
{
  MgGradientLayerState *state = STATE;

  if (state.drawsAfterEnd != flag)
    {
      [self willChangeValueForKey:@"drawsAfterEnd"];
      state.drawsAfterEnd = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"drawsAfterEnd"];
    }
}

- (BOOL)contentContainsPoint:(CGPoint)lp
{
  /* FIXME: implement this. */

  return YES;
}

- (void)_renderLayerWithState:(MgLayerRenderState *)rs
{
  if (_gradient == nil)
    {
      CGGradientRef g = MgCreateGradient(self.colors, self.locations);
      _gradient = CFBridgingRelease(g);
    }

  CGGradientRef grad = (__bridge CGGradientRef)_gradient;
  if (grad == NULL)
    return;

  CGGradientDrawingOptions options = 0;
  if (self.drawsBeforeStart)
    options |= kCGGradientDrawsBeforeStartLocation;
  if (self.drawsAfterEnd)
    options |= kCGGradientDrawsAfterEndLocation;

  if (!self.radial)
    {
      CGContextDrawLinearGradient(rs->ctx, grad, self.startPoint,
				  self.endPoint, options);
    }
  else
    {
      CGContextDrawRadialGradient(rs->ctx, grad, self.startPoint,
				  self.startRadius, self.endPoint,
				  self.endRadius, options);
    }
}

/* FIXME: implement _renderLayerMaskWithState: */

@end
