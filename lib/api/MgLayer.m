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
#import "MgLayerState.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

#define STATE ((MgLayerState *)(self.state))

@implementation MgLayer
{
  MgLayer *_mask;
}

+ (Class)stateClass
{
  return [MgLayerState class];
}

+ (BOOL)automaticallyNotifiesObserversOfPosition
{
  return NO;
}

- (CGPoint)position
{
  return STATE.position;
}

- (void)setPosition:(CGPoint)p
{
  MgLayerState *state = STATE;

  if (!CGPointEqualToPoint(state.position, p))
    {
      [self willChangeValueForKey:@"position"];
      state.position = p;
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
  return STATE.anchor;
}

- (void)setAnchor:(CGPoint)p
{
  MgLayerState *state = STATE;

  if (!CGPointEqualToPoint(state.anchor, p))
    {
      [self willChangeValueForKey:@"anchor"];
      state.anchor = p;
      [self incrementVersion];
      [self didChangeValueForKey:@"anchor"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfSize
{
  return NO;
}

- (CGSize)size
{
  return STATE.size;
}

- (void)setSize:(CGSize)s
{
  MgLayerState *state = STATE;

  if (!CGSizeEqualToSize(state.size, s))
    {
      [self willChangeValueForKey:@"size"];
      state.size = s;
      [self incrementVersion];
      [self didChangeValueForKey:@"size"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfOrigin
{
  return NO;
}

- (CGPoint)origin
{
  return STATE.origin;
}

- (void)setOrigin:(CGPoint)p
{
  MgLayerState *state = STATE;

  if (!CGPointEqualToPoint(state.origin, p))
    {
      [self willChangeValueForKey:@"origin"];
      state.origin = p;
      [self incrementVersion];
      [self didChangeValueForKey:@"origin"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfScale
{
  return NO;
}

- (CGFloat)scale
{
  return STATE.scale;
}

- (void)setScale:(CGFloat)x
{
  MgLayerState *state = STATE;

  if (state.scale != x)
    {
      [self willChangeValueForKey:@"scale"];
      state.scale = x;
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
  return STATE.squeeze;
}

- (void)setSqueeze:(CGFloat)x
{
  MgLayerState *state = STATE;

  if (state.squeeze != x)
    {
      [self willChangeValueForKey:@"squeeze"];
      state.squeeze = x;
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
  return STATE.skew;
}

- (void)setSkew:(CGFloat)x
{
  MgLayerState *state = STATE;

  if (state.skew != x)
    {
      [self willChangeValueForKey:@"skew"];
      state.skew = x;
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
  return STATE.rotation;
}

- (void)setRotation:(double)x
{
  MgLayerState *state = STATE;

  if (state.rotation != x)
    {
      [self willChangeValueForKey:@"rotation"];
      state.rotation = x;
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

  double m22 = self.scale;
  double m11 = m22 * self.squeeze;
  double m12 = 0;
  double m21 = m11 * self.skew;

  double rotation = self.rotation;
  if (rotation != 0)
    {
      double sn = sin(rotation);
      double cs = cos(rotation);

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

  CGPoint position = self.position;
  CGPoint anchor = self.anchor;
  CGSize size = self.size;
  CGPoint origin = self.origin;

  double ax = origin.x + anchor.x * size.width;
  double ay = origin.y + anchor.y * size.height;

  double tx = m11 * -ax + m21 * -ay + position.x;
  double ty = m12 * -ax + m22 * -ay + position.y;

  return CGAffineTransformMake(m11, m12, m21, m22, tx, ty);
}

- (CGRect)bounds
{
  MgLayerState *state = STATE;

  return (CGRect){state.origin, state.size};
}  

- (void)setBounds:(CGRect)r
{
  self.origin = r.origin;
  self.size = r.size;
}

+ (BOOL)automaticallyNotifiesObserversOfAlpha
{
  return NO;
}

- (float)alpha
{
  return STATE.alpha;
}

- (void)setAlpha:(float)x
{
  MgLayerState *state = STATE;

  if (state.alpha != x)
    {
      [self willChangeValueForKey:@"alpha"];
      state.alpha = x;
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
  return STATE.blendMode;
}

- (void)setBlendMode:(CGBlendMode)x
{
  MgLayerState *state = STATE;

  if (state.blendMode != x)
    {
      [self willChangeValueForKey:@"blendMode"];
      state.blendMode = x;
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

- (CFTimeInterval)renderInContext:(CGContextRef)ctx
{
  return [self renderInContext:ctx presentationTime:CACurrentMediaTime()];
}

- (CFTimeInterval)renderInContext:(CGContextRef)ctx
    presentationTime:(CFTimeInterval)t;
{
  __block MgLayerRenderState rs;
  rs.time = t;
  rs.next_time = HUGE_VAL;
  rs.ctx = ctx;
  rs.alpha = 1;

  [self withPresentationTime:rs.time handler:^
    {
      [self _renderWithState:&rs];
    }];

  rs.next_time = fmax(rs.next_time, [self markPresentationTime:rs.time]);

  return rs.next_time;
}

- (void)_renderWithState:(MgLayerRenderState *)rs
{
  float alpha = rs->alpha * fmin(self.alpha, 1);
  if (!(alpha > 0))
    return;

  __block MgLayerRenderState r = *rs;
  r.alpha = alpha;

  CGContextSaveGState(r.ctx);

  CGContextConcatCTM(r.ctx, [self parentTransform]);

  MgLayer *mask = self.mask;
  if (mask != nil && mask.enabled)
    {
      MgLayerRenderState rm = r;
      rm.alpha = 1;

      [mask withPresentationTime:r.time handler:^
	{ 
	  rs->next_time = fmax(rs->next_time,
			       [mask markPresentationTime:r.time]);
	}];

      [mask markPresentationTime:r.time];
    }

  CGContextSetBlendMode(rs->ctx, self.blendMode);
  CGContextSetAlpha(rs->ctx, r.alpha);

  [self _renderLayerWithState:&r];

  CGContextRestoreGState(r.ctx);

  rs->next_time = r.next_time;
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

  rs->next_time = r.next_time;
}

- (void)_renderLayerMaskWithState:(MgLayerRenderState *)rs
{
  /* FIXME: render mask to an image and clip to it. */
}

- (CGImageRef)copyImage
{
  CGPoint origin = self.origin;
  CGSize size = self.size;

  return MgImageCreateByDrawing(size.width, size.height, false,
    ^(CGContextRef ctx)
    {
      CGContextTranslateCTM(ctx, 0, size.height);
      CGContextScaleCTM(ctx, 1, -1);
      CGContextTranslateCTM(ctx, origin.x, origin.y);
      CGAffineTransform m = [self parentTransform];
      CGContextConcatCTM(ctx, CGAffineTransformInvert(m));
      [self renderInContext:ctx];
    });
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgLayer *copy = [super graphCopy:map];

  if (_mask != nil)
    copy->_mask = [_mask mg_graphCopy:map];

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_mask != nil)
    [c encodeObject:_mask forKey:@"mask"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"mask"])
    {
      _mask = [c decodeObjectOfClass:[MgLayer class] forKey:@"mask"];
      [_mask addReference:self];
    }

  return self;
}

@end
