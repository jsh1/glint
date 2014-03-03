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
  CGAffineTransform _affineTransform;
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
  _affineTransform = CGAffineTransformIdentity;
  _alpha = 1;
  _blendMode = kCGBlendModeNormal;

  return self;
}

- (void)dealloc
{
  for (MgDrawableNode *node in _contentNodes)
    [node removeReference:self];

  if (_maskNode != nil)
    [_maskNode removeReference:self];
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

+ (BOOL)automaticallyNotifiesObserversOfAffineTransform
{
  return NO;
}

- (CGAffineTransform)affineTransform
{
  return _affineTransform;
}

- (void)setAffineTransform:(CGAffineTransform)m
{
  if (!CGAffineTransformEqualToTransform(_affineTransform, m))
    {
      [self willChangeValueForKey:@"affineTransform"];
      _affineTransform = m;
      [self incrementVersion];
      [self didChangeValueForKey:@"affineTransform"];
    }
}

- (CGAffineTransform)frameAffineTransform
{
  const CGPoint *position = &_position;
  const CGPoint *anchor = &_anchor;
  const CGRect *bounds = &_bounds;

  CGFloat ax = bounds->origin.x + anchor->x * bounds->size.width;
  CGFloat ay = bounds->origin.y + anchor->y * bounds->size.height;

  CGAffineTransform m = CGAffineTransformTranslate(_affineTransform, -ax, -ay);
  m.tx += position->x;
  m.ty += position->y;

  return m;
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

- (BOOL)containsPoint:(CGPoint)p layerBounds:(CGRect)r
{
  /* Map point into our coordinate space. */

  CGAffineTransform m = CGAffineTransformInvert([self frameAffineTransform]);
  
  CGPoint lp = CGPointApplyAffineTransform(p, m);

  if (self.masksToBounds && !CGRectContainsPoint(self.bounds, lp))
    return NO;

  MgDrawableNode *mask = self.maskNode;
  if (mask != nil && ![mask containsPoint:p layerBounds:r])
    return NO;

  for (MgDrawableNode *node in self.contentNodes)
    {
      if ([node containsPoint:lp layerBounds:self.bounds])
	return YES;
    }

  return NO;
}

- (void)addNodesContainingPoint:(CGPoint)p toSet:(NSMutableSet *)set
    layerBounds:(CGRect)r;
{
  /* Map point into our coordinate space. */

  CGAffineTransform m = CGAffineTransformInvert([self frameAffineTransform]);
  
  CGPoint lp = CGPointApplyAffineTransform(p, m);

  if (self.masksToBounds && !CGRectContainsPoint(self.bounds, lp))
    return;

  MgDrawableNode *mask = self.maskNode;
  if (mask != nil && ![mask containsPoint:p layerBounds:r])
    return;

  for (MgDrawableNode *node in self.contentNodes)
    {
      [node addNodesContainingPoint:lp toSet:set layerBounds:self.bounds];
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

  CGAffineTransform m = [self frameAffineTransform];
  BOOL group = self.group;

  MgDrawableRenderState r = *rs;
  r.tnext = HUGE_VAL;
  r.bounds = self.bounds;
  r.cornerRadius = self.cornerRadius;
  r.alpha = group ? 1 : alpha;

  CGContextSaveGState(r.ctx);
  CGContextConcatCTM(r.ctx, m);
  CGContextSetAlpha(r.ctx, alpha);
  CGContextSetBlendMode(r.ctx, self.blendMode);

  if (self.masksToBounds)
    {
      if (r.cornerRadius == 0)
	CGContextClipToRect(r.ctx, r.bounds);
      else
	{
	  CGPathRef p = CGPathCreateWithRoundedRect(r.bounds, r.cornerRadius,
						    r.cornerRadius, NULL);
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
  copy->_affineTransform = _affineTransform;
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

  if (!CGAffineTransformIsIdentity(_affineTransform))
    [c mg_encodeCGAffineTransform:_affineTransform forKey:@"affineTransform"];

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

  if ([c containsValueForKey:@"affineTransform"])
    _affineTransform = [c mg_decodeCGAffineTransformForKey:@"affineTransform"];
  else
    _affineTransform = CGAffineTransformIdentity;

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
