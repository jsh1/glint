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

#import "MgGradientNode.h"

#import "MgCoderExtensions.h"
#import "MgCoreGraphics.h"
#import "MgDrawableNodeInternal.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgGradientNode
{
  NSArray *_colors;
  NSArray *_locations;
  BOOL _radial;
  CGPoint _startPoint;
  CGPoint _endPoint;
  CGFloat _startRadius;
  CGFloat _endRadius;
  BOOL _drawsBeforeStart;
  BOOL _drawsAfterEnd;

  /* Cached. */
  id _gradient;				/* CGGradientRef */
}

+ (BOOL)automaticallyNotifiesObserversOfColors
{
  return NO;
}

- (NSArray *)colors
{
  return _colors != nil ? _colors : @[];
}

- (void)setColors:(NSArray *)array
{
  if (_colors != array && ![_colors isEqual:array])
    {
      [self willChangeValueForKey:@"colors"];
      _colors = [array copy];
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
  return _locations != nil ? _locations : @[];
}

- (void)setLocations:(NSArray *)array
{
  if (_locations != array && ![_locations isEqual:array])
    {
      [self willChangeValueForKey:@"locations"];
      _locations = [array copy];
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
  return _radial;
}

- (void)setRadial:(BOOL)flag
{
  if (_radial != flag)
    {
      [self willChangeValueForKey:@"radial"];
      _radial = flag;
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
  return _startPoint;
}

- (void)setStartPoint:(CGPoint)p
{
  if (!CGPointEqualToPoint(_startPoint, p))
    {
      [self willChangeValueForKey:@"startPoint"];
      _startPoint = p;
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
  return _endPoint;
}

- (void)setEndPoint:(CGPoint)p
{
  if (!CGPointEqualToPoint(_endPoint, p))
    {
      [self willChangeValueForKey:@"endPoint"];
      _endPoint = p;
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
  return _startRadius;
}

- (void)setStartRadius:(CGFloat)x
{
  if (_startRadius != x)
    {
      [self willChangeValueForKey:@"startRadius"];
      _startRadius = x;
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
  return _endRadius;
}

- (void)setEndRadius:(CGFloat)x
{
  if (_endRadius != x)
    {
      [self willChangeValueForKey:@"endRadius"];
      _endRadius = x;
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
  return _drawsBeforeStart;
}

- (void)setDrawsBeforeStart:(BOOL)flag
{
  if (_drawsBeforeStart != flag)
    {
      [self willChangeValueForKey:@"drawsBeforeStart"];
      _drawsBeforeStart = flag;
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
  return _drawsAfterEnd;
}

- (void)setDrawsAfterEnd:(BOOL)flag
{
  if (_drawsAfterEnd != flag)
    {
      [self willChangeValueForKey:@"drawsAfterEnd"];
      _drawsAfterEnd = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"drawsAfterEnd"];
    }
}

- (BOOL)containsPoint:(CGPoint)p layerNode:(MgLayerNode *)node
{
  /* FIXME: implement this. */

  return YES;
}

- (void)_renderWithState:(MgDrawableRenderState *)rs
{
  if (_gradient == nil)
    {
      CGGradientRef g = MgCreateGradient((__bridge CFArrayRef)self.colors,
					 (__bridge CFArrayRef)self.locations);
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

/* FIXME: implement _renderMaskWithState: */

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgGradientNode *copy = [super copyWithZone:zone];

  copy->_colors = _colors;
  copy->_locations = _locations;
  copy->_radial = _radial;
  copy->_startPoint = _startPoint;
  copy->_endPoint = _endPoint;
  copy->_startRadius = _startRadius;
  copy->_endRadius = _endRadius;
  copy->_drawsBeforeStart = _drawsBeforeStart;
  copy->_drawsAfterEnd = _drawsAfterEnd;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_colors != nil)
    [c encodeObject:_colors forKey:@"colors"];

  if (_locations != nil)
    [c encodeObject:_locations forKey:@"locations"];

  if (_radial)
    [c encodeBool:_radial forKey:@"radial"];

  if (_startPoint.x != 0 || _startPoint.y != 0)
    [c mg_encodeCGPoint:_startPoint forKey:@"startPoint"];

  if (_endPoint.x != 0 || _endPoint.y != 0)
    [c mg_encodeCGPoint:_endPoint forKey:@"endPoint"];

  if (_startRadius != 0)
    [c encodeDouble:_startRadius forKey:@"startRadius"];

  if (_endRadius != 0)
    [c encodeDouble:_endRadius forKey:@"endRadius"];

  if (_drawsBeforeStart)
    [c encodeBool:_drawsBeforeStart forKey:@"drawsBeforeStart"];

  if (_drawsAfterEnd)
    [c encodeBool:_drawsAfterEnd forKey:@"drawsAfterEnd"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"colors"])
    _colors = [c decodeObjectOfClass:[NSArray class] forKey:@"colors"];

  if ([c containsValueForKey:@"locations"])
    _locations = [c decodeObjectOfClass:[NSArray class] forKey:@"locations"];

  if ([c containsValueForKey:@"radial"])
    _radial = [c decodeBoolForKey:@"radial"];

  if ([c containsValueForKey:@"startPoint"])
    _startPoint = [c mg_decodeCGPointForKey:@"startPoint"];

  if ([c containsValueForKey:@"endPoint"])
    _endPoint = [c mg_decodeCGPointForKey:@"endPoint"];

  if ([c containsValueForKey:@"startRadius"])
    _startRadius = [c decodeDoubleForKey:@"startRadius"];

  if ([c containsValueForKey:@"endRadius"])
    _endRadius = [c decodeDoubleForKey:@"endRadius"];

  if ([c containsValueForKey:@"drawsBeforeStart"])
    _drawsBeforeStart = [c decodeBoolForKey:@"drawsBeforeStart"];

  if ([c containsValueForKey:@"drawsAfterEnd"])
    _drawsAfterEnd = [c decodeBoolForKey:@"drawsAfterEnd"];

  return self;
}

@end
