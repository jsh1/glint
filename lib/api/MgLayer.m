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

#import "MgLayerInternal.h"

#import "MgCoderExtensions.h"
#import "MgCoreGraphics.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgLayer
{
  CGPoint _position;
  CGPoint _anchor;
  CGRect _bounds;
  CGFloat _scale;
  CGFloat _squeeze;
  CGFloat _skew;
  double _rotation;
  float _alpha;
  CGBlendMode _blendMode;
  MgLayer *_mask;
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _anchor = CGPointMake((CGFloat).5, (CGFloat).5);
  _bounds = CGRectZero;
  _scale = 1;
  _squeeze = 1;

  _alpha = 1;
  _blendMode = kCGBlendModeNormal;

  return self;
}

+ (BOOL)automaticallyNotifiesObserversOfPosition
{
  return NO;
}

- (CGPoint)position
{
  return _position;
}

- (void)setPosition:(CGPoint)p
{
  if (!CGPointEqualToPoint(_position, p))
    {
      [self willChangeValueForKey:@"position"];
      _position = p;
      [self incrementVersion];
      [self didChangeValueForKey:@"position"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfAnchor
{
  return NO;
}

- (CGPoint)anchor
{
  return _anchor;
}

- (void)setAnchor:(CGPoint)p
{
  if (!CGPointEqualToPoint(_anchor, p))
    {
      [self willChangeValueForKey:@"anchor"];
      _anchor = p;
      [self incrementVersion];
      [self didChangeValueForKey:@"anchor"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfBounds
{
  return NO;
}

- (CGRect)bounds
{
  return _bounds;
}

- (void)setBounds:(CGRect)r
{
  if (!CGRectEqualToRect(_bounds, r))
    {
      [self willChangeValueForKey:@"bounds"];
      _bounds = r;
      [self incrementVersion];
      [self didChangeValueForKey:@"bounds"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfScale
{
  return NO;
}

- (CGFloat)scale
{
  return _scale;
}

- (void)setScale:(CGFloat)x
{
  if (_scale != x)
    {
      [self willChangeValueForKey:@"scale"];
      _scale = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"scale"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfSqueeze
{
  return NO;
}

- (CGFloat)squeeze
{
  return _squeeze;
}

- (void)setSqueeze:(CGFloat)x
{
  if (_squeeze != x)
    {
      [self willChangeValueForKey:@"squeeze"];
      _squeeze = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"squeeze"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfSkew
{
  return NO;
}

- (CGFloat)skew
{
  return _skew;
}

- (void)setSkew:(CGFloat)x
{
  if (_skew != x)
    {
      [self willChangeValueForKey:@"skew"];
      _skew = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"skew"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfRotation
{
  return NO;
}

- (double)rotation
{
  return _rotation;
}

- (void)setRotation:(double)x
{
  if (_rotation != x)
    {
      [self willChangeValueForKey:@"rotation"];
      _rotation = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"rotation"];
    }
}

- (CGAffineTransform)parentTransform
{
  /* Letting Maxima do my dirty work for me:

	(%i45) scale;
	                                  [ sc  0  ]
	(%o45)                            [        ]
	                                  [ 0   sc ]
	(%i46) squeeze;
	                                   [ sq  0 ]
	(%o46)                             [       ]
	                                   [ 0   1 ]
	(%i47) skew;
	                                   [ 1  sk ]
	(%o47)                             [       ]
	                                   [ 0  1  ]
	(%i48) scale . squeeze . skew;
	                                 [ sc sq  0  ]
	(%o48)                           [           ]
	                                 [ sc sk  sc ]

	(%i50) rotate;
	                                 [ cs  - sn ]
	(%o50)                           [          ]
	                                 [ sn   cs  ]
	(%i51) scale . squeeze . skew . rotate;
	                     [    cs sc sq        - sc sn sq    ]
	(%o51)               [                                  ]
	                     [ sc (sn + cs sk)  sc (cs - sk sn) ]
	
     of course that might be backwards. */

  double m22 = _scale;
  double m11 = m22 * _squeeze;
  double m12 = 0;
  double m21 = m11 * _skew;

  if (_rotation != 0)
    {
      double sn = sin(_rotation);
      double cs = cos(_rotation);

      double m11_ = m11 * cs  + m12 * sn;
      double m12_ = m11 * -sn + m12 * cs;
      double m21_ = m21 * cs  + m22 * sn;
      double m22_ = m21 * -sn + m22 * cs;

      m11 = m11_;
      m12 = m12_;
      m21 = m21_;
      m22 = m22_;
    }

  /* For m' = translation(-ax, -ay) . m:

	(%i52) matrix([1, 0, 0], [0, 1, 0], [-ax, -ay, 1])
		. matrix([ma, mb, 0], [mc, md, 0], [0, 0, 1]);

	                    [       ma               mb         0 ]
	                    [                                     ]
	(%o52)              [       mc               md         0 ]
	                    [                                     ]
	                    [ - ay mc - ax ma  - ay md - ax mb  1 ]

     and the easy one: m' = m . translation(position.x, position.y). */

  double ax = _bounds.origin.x + _anchor.x * _bounds.size.width;
  double ay = _bounds.origin.y + _anchor.y * _bounds.size.height;

  double tx = m11 * -ax + m21 * -ay + _position.x;
  double ty = m12 * -ax + m22 * -ay + _position.y;

  return CGAffineTransformMake(m11, m12, m21, m22, tx, ty);
}

+ (BOOL)automaticallyNotifiesObserversOfAlpha
{
  return NO;
}

- (float)alpha
{
  return _alpha;
}

- (void)setAlpha:(float)x
{
  if (_alpha != x)
    {
      [self willChangeValueForKey:@"alpha"];
      _alpha = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"alpha"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfBlendMode
{
  return NO;
}

- (CGBlendMode)blendMode
{
  return _blendMode;
}

- (void)setBlendMode:(CGBlendMode)x
{
  if (_blendMode != x)
    {
      [self willChangeValueForKey:@"blendMode"];
      _blendMode = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"blendMode"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfMask
{
  return NO;
}

- (MgLayer *)mask
{
  return _mask;
}

- (void)setMask:(MgLayer *)node
{
  if (_mask != node)
    {
      [self willChangeValueForKey:@"mask"];
      [_mask removeReference:self];
      _mask = node;
      [_mask addReference:self];
      [self incrementVersion];
      [self didChangeValueForKey:@"mask"];
    }
}

- (void)foreachNode:(void (^)(MgNode *node))block
{
  if (_mask != nil)
    block(_mask);

  [super foreachNode:block];
}

- (void)foreachNodeAndAttachmentInfo:(void (^)(MgNode *node,
    NSString *parentKey, NSInteger parentIndex))block
{
  if (_mask != nil)
    block(_mask, @"mask", NSNotFound);

  [super foreachNodeAndAttachmentInfo:block];
}

- (CGPoint)convertPointToParent:(CGPoint)p
{
  CGAffineTransform m = [self parentTransform];
  return CGPointApplyAffineTransform(p, m);
}

- (CGPoint)convertPointFromParent:(CGPoint)p
{
  CGAffineTransform m = CGAffineTransformInvert([self parentTransform]);
  return CGPointApplyAffineTransform(p, m);
}

- (BOOL)containsPoint:(CGPoint)p
{
  CGPoint lp = [self convertPointFromParent:p];

  MgLayer *mask = self.mask;
  if (mask != nil && ![mask containsPoint:lp])
    return NO;

  if (CGRectContainsPoint(self.bounds, lp))
    return YES;

  if ([self contentContainsPoint:lp])
    return YES;

  return NO;
}

- (BOOL)contentContainsPoint:(CGPoint)lp
{
  return NO;
}

/** Rendering. **/

- (void)renderInContext:(CGContextRef)ctx
{
  MgLayerRenderState rs;
  rs.ctx = ctx;
  rs.alpha = 1;

  [self _renderWithState:&rs];
}

- (void)_renderWithState:(MgLayerRenderState *)rs
{
  float alpha = rs->alpha * fmin(self.alpha, 1);
  if (!(alpha > 0))
    return;

  MgLayerRenderState r = *rs;
  r.alpha = alpha;

  CGContextSaveGState(r.ctx);

  CGContextConcatCTM(r.ctx, [self parentTransform]);

  MgLayer *mask = self.mask;
  if (mask != nil && mask.enabled)
    {
      MgLayerRenderState rm = r;
      rm.alpha = 1;

      [mask _renderMaskWithState:&rm];
    }

  CGContextSetBlendMode(rs->ctx, self.blendMode);
  CGContextSetAlpha(rs->ctx, r.alpha);

  [self _renderLayerWithState:&r];

  CGContextRestoreGState(r.ctx);
}

- (void)_renderLayerWithState:(MgLayerRenderState *)rs
{
}

- (void)_renderMaskWithState:(MgLayerRenderState *)rs
{
  float alpha = rs->alpha * fmin(self.alpha, 1);
  if (!(alpha > 0))
    {
      CGContextClipToRect(rs->ctx, CGRectNull);
      return;
    }

  MgLayerRenderState r = *rs;
  r.alpha = alpha;

  CGAffineTransform m = [self parentTransform];
  CGContextConcatCTM(r.ctx, m);

  [self _renderLayerMaskWithState:&r];

  CGContextConcatCTM(r.ctx, CGAffineTransformInvert(m));
}

- (void)_renderLayerMaskWithState:(MgLayerRenderState *)rs
{
  /* FIXME: render mask to an image and clip to it. */
}

- (CGImageRef)copyImage
{
  CGRect bounds = self.bounds;

  return MgImageCreateByDrawing(bounds.size.width, bounds.size.height, false,
    ^(CGContextRef ctx)
    {
      CGContextTranslateCTM(ctx, 0, bounds.size.height);
      CGContextScaleCTM(ctx, 1, -1);
      CGContextTranslateCTM(ctx, bounds.origin.x, bounds.origin.y);
      CGAffineTransform m = [self parentTransform];
      CGContextConcatCTM(ctx, CGAffineTransformInvert(m));
      [self renderInContext:ctx];
    });
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgLayer *copy = [super copyWithZone:zone];

  copy->_position = _position;
  copy->_anchor = _anchor;
  copy->_bounds = _bounds;
  copy->_scale = _scale;
  copy->_squeeze = _squeeze;
  copy->_skew = _skew;
  copy->_rotation = _rotation;
  copy->_alpha = _alpha;
  copy->_blendMode = _blendMode;
  copy->_mask = _mask;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_position.x != 0 || _position.y != 0)
    [c mg_encodeCGPoint:_position forKey:@"position"];

  if (_anchor.x != (CGFloat).5 || _anchor.y != (CGFloat).5)
    [c mg_encodeCGPoint:_anchor forKey:@"anchor"];

  if (!CGRectIsNull(_bounds))
    [c mg_encodeCGRect:_bounds forKey:@"bounds"];

  if (_scale != 1)
    [c encodeDouble:_scale forKey:@"scale"];

  if (_squeeze != 1)
    [c encodeDouble:_squeeze forKey:@"squeeze"];

  if (_skew != 0)
    [c encodeDouble:_skew forKey:@"skew"];

  if (_rotation != 0)
    [c encodeDouble:_rotation forKey:@"rotation"];

  if (_alpha != 1)
    [c encodeFloat:_alpha forKey:@"alpha"];

  if (_blendMode != kCGBlendModeNormal)
    [c encodeInt:_blendMode forKey:@"blendMode"];

  if (_mask != nil)
    [c encodeObject:_mask forKey:@"mask"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"position"])
    _position = [c mg_decodeCGPointForKey:@"position"];

  if ([c containsValueForKey:@"anchor"])
    _anchor = [c mg_decodeCGPointForKey:@"anchor"];
  else
    _anchor = CGPointMake((CGFloat).5, (CGFloat).5);

  if ([c containsValueForKey:@"bounds"])
    _bounds = [c mg_decodeCGRectForKey:@"bounds"];
  else
    _bounds = CGRectNull;

  if ([c containsValueForKey:@"scale"])
    _scale = [c decodeDoubleForKey:@"scale"];
  else
    _scale = 1;

  if ([c containsValueForKey:@"squeeze"])
    _squeeze = [c decodeDoubleForKey:@"squeeze"];
  else
    _squeeze = 1;

  if ([c containsValueForKey:@"skew"])
    _skew = [c decodeDoubleForKey:@"skew"];

  if ([c containsValueForKey:@"rotation"])
    _rotation = [c decodeDoubleForKey:@"rotation"];

  if ([c containsValueForKey:@"alpha"])
    _alpha = [c decodeFloatForKey:@"alpha"];
  else
    _alpha = 1;

  if ([c containsValueForKey:@"blendMode"])
    _blendMode = (CGBlendMode)[c decodeIntForKey:@"blendMode"];
  else
    _blendMode = kCGBlendModeNormal;

  if ([c containsValueForKey:@"mask"])
    {
      _mask = [c decodeObjectOfClass:[MgLayer class] forKey:@"mask"];
      [_mask addReference:self];
    }

  return self;
}

@end
