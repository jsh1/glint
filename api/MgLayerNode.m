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

#import "MgLayerNode.h"

#import "MgCoderExtensions.h"
#import "MgDrawableNodeInternal.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgLayerNode
{
  CGPoint _position;
  CGPoint _anchor;
  CGRect _bounds;
  CGFloat _cornerRadius;
  CGFloat _scale;
  CGFloat _squeeze;
  CGFloat _skew;
  double _rotation;
  BOOL _group;
  float _alpha;
  CGBlendMode _blendMode;
  BOOL _masksToBounds;
  MgDrawableNode *_maskNode;
  NSMutableArray *_contentNodes;
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _anchor = CGPointMake((CGFloat).5, (CGFloat).5);
  _bounds = CGRectNull;
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

+ (BOOL)automaticallyNotifiesObserversOfCornerRadius
{
  return NO;
}

- (CGFloat)cornerRadius
{
  return _cornerRadius;
}

- (void)setCornerRadius:(CGFloat)x
{
  if (_cornerRadius != x)
    {
      [self willChangeValueForKey:@"cornerRadius"];
      _cornerRadius = x;
      [self incrementVersion];
      [self didChangeValueForKey:@"cornerRadius"];
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
	                              [ sc sq  sc sk sq ]
	(%o48)                        [                 ]
	                              [   0       sc    ]
	(%i49) 
	
	(%i50) rotate;
	                                 [ cs  - sn ]
	(%o50)                           [          ]
	                                 [ sn   cs  ]
	(%i51) scale . squeeze . skew . rotate;
	                  [ sc (sk sn + cs) sq  sc (cs sk - sn) sq ]
	(%o51)            [                                        ]
	                  [       sc sn               cs sc        ]
	
     of course that might be backwards. */

  double m22 = _scale;
  double m21 = 0;
  double m11 = m22 * _squeeze;
  double m12 = m11 * _skew;

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

+ (BOOL)automaticallyNotifiesObserversOfGroup
{
  return NO;
}

- (BOOL)group
{
  return _group;
}

- (void)setGroup:(BOOL)flag
{
  if (_group != flag)
    {
      [self willChangeValueForKey:@"group"];
      _group = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"group"];
    }
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

+ (BOOL)automaticallyNotifiesObserversOfMasksToBounds
{
  return NO;
}

- (BOOL)masksToBounds
{
  return _masksToBounds;
}

- (void)setMasksToBounds:(BOOL)flag
{
  if (_masksToBounds != flag)
    {
      [self willChangeValueForKey:@"masksToBounds"];
      _masksToBounds = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"masksToBounds"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfMaskNode
{
  return NO;
}

- (MgDrawableNode *)maskNode
{
  return _maskNode;
}

- (void)setMaskNode:(MgDrawableNode *)node
{
  if (_maskNode != node)
    {
      [self willChangeValueForKey:@"maskNode"];
      [_maskNode removeReference:self];
      _maskNode = node;
      [_maskNode addReference:self];
      [self incrementVersion];
      [self didChangeValueForKey:@"maskNode"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfContentNodes
{
  return NO;
}

- (NSArray *)contentNodes
{
  return _contentNodes != nil ? _contentNodes : [NSArray array];
}

- (void)setContentNodes:(NSArray *)array
{
  if (_contentNodes != array && ![_contentNodes isEqual:array])
    {
      [self willChangeValueForKey:@"contentNodes"];

      for (MgDrawableNode *node in _contentNodes)
	[node removeReference:self];

      _contentNodes = [array copy];

      for (MgDrawableNode *node in _contentNodes)
	[node addReference:self];

      [self incrementVersion];
      [self didChangeValueForKey:@"contentNodes"];
    }
}

- (void)addContentNode:(MgDrawableNode *)node
{
  [self insertContentNode:node atIndex:NSIntegerMax];
}

- (void)removeContentNode:(MgDrawableNode *)node
{
  while (true)
    {
      NSInteger idx = [_contentNodes indexOfObjectIdenticalTo:node];
      if (idx == NSNotFound)
	break;

      [self removeContentNodeAtIndex:idx];
    }
}

- (void)insertContentNode:(MgDrawableNode *)node atIndex:(NSInteger)idx
{
  if (_contentNodes == nil)
    _contentNodes = [[NSMutableArray alloc] init];

  if (idx > [_contentNodes count])
    idx = [_contentNodes count];

  [self willChangeValueForKey:@"contentNodes"];

  [_contentNodes insertObject:node atIndex:idx];
  [node addReference:self];

  [self incrementVersion];
  [self didChangeValueForKey:@"contentNodes"];
}

- (void)removeContentNodeAtIndex:(NSInteger)idx
{
  if (idx < [_contentNodes count])
    {
      [self willChangeValueForKey:@"contentNodes"];

      [_contentNodes[idx] removeReference:self];
      [_contentNodes removeObjectAtIndex:idx];

      [self incrementVersion];
      [self didChangeValueForKey:@"contentNodes"];
    }
}

- (void)foreachNode:(void (^)(MgNode *node))block
{
  [super foreachNode:block];

  for (MgDrawableNode *node in _contentNodes)
    block(node);

  if (_maskNode != nil)
    block(_maskNode);
}

- (BOOL)containsPoint:(CGPoint)p layerNode:(MgLayerNode *)node
{
  /* Map point into our coordinate space. */

  CGAffineTransform m = CGAffineTransformInvert([self parentTransform]);
  
  CGPoint lp = CGPointApplyAffineTransform(p, m);

  if (self.masksToBounds && !CGRectContainsPoint(self.bounds, lp))
    return NO;

  MgDrawableNode *mask = self.maskNode;
  if (mask != nil && ![mask containsPoint:p layerNode:node])
    return NO;

  for (MgDrawableNode *node in self.contentNodes)
    {
      if ([node containsPoint:lp layerNode:self])
	return YES;
    }

  return NO;
}

- (void)addNodesContainingPoint:(CGPoint)p toSet:(NSMutableSet *)set
    layerNode:(MgLayerNode *)node
{
  /* Map point into our coordinate space. */

  CGAffineTransform m = CGAffineTransformInvert([self parentTransform]);
  
  CGPoint lp = CGPointApplyAffineTransform(p, m);

  if (self.masksToBounds && !CGRectContainsPoint(self.bounds, lp))
    return;

  MgDrawableNode *mask = self.maskNode;
  if (mask != nil && ![mask containsPoint:p layerNode:node])
    return;

  for (MgDrawableNode *node in self.contentNodes)
    {
      [node addNodesContainingPoint:lp toSet:set layerNode:self];
    }
}

/** Rendering. **/

- (void)renderWithState:(MgDrawableRenderState *)rs
{
  if (self.hidden)
    return;

  float alpha = rs->alpha * fmin(self.alpha, 1);

  if (!(alpha > 0))
    return;

  if ([self.contentNodes count] == 0)
    return;

  BOOL group = self.group;

  MgDrawableRenderState r = *rs;
  r.tnext = HUGE_VAL;
  r.layer = self;
  r.alpha = group ? 1 : alpha;

  CGContextSaveGState(r.ctx);
  CGContextConcatCTM(r.ctx, [self parentTransform]);
  CGContextSetAlpha(r.ctx, alpha);
  CGContextSetBlendMode(r.ctx, self.blendMode);

  if (self.masksToBounds)
    {
      CGFloat radius = self.cornerRadius;
      if (radius == 0)
	CGContextClipToRect(r.ctx, self.bounds);
      else
	{
	  CGPathRef p = CGPathCreateWithRoundedRect(self.bounds,
						    radius, radius, NULL);
	  CGContextBeginPath(r.ctx);
	  CGContextAddPath(r.ctx, p);
	  CGPathRelease(p);
	  CGContextClip(r.ctx);
	}
    }

  /* FIXME: ignoring maskNode. */

  if (group)
    CGContextBeginTransparencyLayer(r.ctx, NULL);

  for (MgDrawableNode *node in self.contentNodes)
    [node renderWithState:&r];

  if (group)
    CGContextEndTransparencyLayer(r.ctx);

  CGContextRestoreGState(r.ctx);

  if (r.tnext < rs->tnext)
    rs->tnext = r.tnext;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgLayerNode *copy = [super copyWithZone:zone];

  copy->_position = _position;
  copy->_anchor = _anchor;
  copy->_bounds = _bounds;
  copy->_cornerRadius = _cornerRadius;
  copy->_scale = _scale;
  copy->_squeeze = _squeeze;
  copy->_skew = _skew;
  copy->_rotation = _rotation;
  copy->_group = _group;
  copy->_alpha = _alpha;
  copy->_blendMode = _blendMode;
  copy->_masksToBounds = _masksToBounds;
  copy->_maskNode = _maskNode;

  if ([_contentNodes count] != 0)
    {
      for (MgDrawableNode *node in _contentNodes)
	[node addReference:copy];

      copy->_contentNodes = [_contentNodes copy];
    }

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

  if (_cornerRadius != 0)
    [c encodeDouble:_cornerRadius forKey:@"cornerRadius"];

  if (_scale != 1)
    [c encodeDouble:_scale forKey:@"scale"];

  if (_squeeze != 1)
    [c encodeDouble:_squeeze forKey:@"squeeze"];

  if (_skew != 0)
    [c encodeDouble:_skew forKey:@"skew"];

  if (_rotation != 0)
    [c encodeDouble:_rotation forKey:@"rotation"];

  if (_group)
    [c encodeBool:_group forKey:@"group"];

  if (_alpha != 1)
    [c encodeFloat:_alpha forKey:@"alpha"];

  if (_blendMode != kCGBlendModeNormal)
    [c encodeInt:_blendMode forKey:@"blendMode"];

  if (_masksToBounds)
    [c encodeBool:_masksToBounds forKey:@"masksToBounds"];

  if (_maskNode != nil)
    [c encodeObject:_maskNode forKey:@"maskNode"];

  if ([_contentNodes count] != 0)
    [c encodeObject:_contentNodes forKey:@"contentNodes"];
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

  if ([c containsValueForKey:@"cornerRadius"])
    _cornerRadius = [c decodeDoubleForKey:@"cornerRadius"];

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

  if ([c containsValueForKey:@"group"])
    _group = [c decodeBoolForKey:@"group"];

  if ([c containsValueForKey:@"alpha"])
    _alpha = [c decodeFloatForKey:@"alpha"];
  else
    _alpha = 1;

  if ([c containsValueForKey:@"blendMode"])
    _blendMode = (CGBlendMode)[c decodeIntForKey:@"blendMode"];
  else
    _blendMode = kCGBlendModeNormal;

  if ([c containsValueForKey:@"masksToBounds"])
    _masksToBounds = [c decodeBoolForKey:@"maskNode"];

  if ([c containsValueForKey:@"maskNode"])
    {
      _maskNode = [c decodeObjectOfClass:[MgDrawableNode class]
		   forKey:@"maskNode"];
      [_maskNode addReference:self];
    }

  if ([c containsValueForKey:@"contentNodes"])
    {
      NSArray *array = [c decodeObjectOfClass:[NSArray class]
			forKey:@"contentNodes"];

      BOOL valid = YES;
      for (id obj in array)
	{
	  if (![obj isKindOfClass:[MgDrawableNode class]])
	    {
	      valid = NO;
	      break;
	    }
	}

      if (valid)
	{
	  _contentNodes = [array copy];

	  for (MgDrawableNode *node in _contentNodes)
	    [node addReference:self];
	}
    }

  return self;
}

@end
