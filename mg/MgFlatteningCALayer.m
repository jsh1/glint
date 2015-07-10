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

#import "MgFlatteningCALayer.h"

#import "MgLayer.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define LONG_TIME (3600*24*365*10)

@implementation MgFlatteningCALayer
{
  MgLayer *_layer;
  __weak MgViewContext *_viewContext;

  double _currentTime;
  NSInteger _lastVersion;
  BOOL _addedAnimation;

  __weak MgFlatteningCALayer *_modelLayer;
}

@synthesize currentTime = _currentTime;

+ (id)defaultValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"needsDisplayOnBoundsChange"])
    return @YES;
  else if ([key isEqualToString:@"drawsAsynchronously"])
    return @YES;
  else
    return [super defaultValueForKey:key];
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
  if ([key isEqualToString:@"currentTime"])
    return YES;
  else
    return [super needsDisplayForKey:key];
}

- (id)initWithMgLayer:(MgLayer *)layer viewContext:(MgViewContext *)ctx
{
  self = [super init];
  if (self == nil)
    return nil;

  _layer = layer;
  _viewContext = ctx;

  return self;
}

- (id)initWithLayer:(MgFlatteningCALayer *)layer
{
  self = [super init];
  if (self == nil)
    return nil;

  _layer = layer->_layer;
  _lastVersion = layer->_lastVersion;

  _modelLayer = layer;

  return self;
}

- (MgLayer *)layer
{
  return _layer;
}

- (MgViewContext *)viewContext
{
  return _viewContext;
}

- (void)update
{
  NSInteger version = _layer.version;

  if (version != _lastVersion)
    {
      _lastVersion = version;

      [self setNeedsLayout];
      [self setNeedsDisplay];
    }
}

- (void)layoutSublayers
{
  [_viewContext updateViewLayer:self];

  self.position = _layer.position;
  self.bounds = _layer.bounds;
}

- (void)drawInContext:(CGContextRef)ctx
{
  /* FIXME: -[CALayer modelLayer] seems to be broken for client-side
     animation copies?

     FIXME: and self.bounds seems to return CGRectZero, wtf!? */

  MgFlatteningCALayer *model = _modelLayer;

  CFTimeInterval now;
  if (model == nil)
    model = self;

  if (model == self)
    now = [self convertTime:CACurrentMediaTime() fromLayer:nil];
  else
    now = self.currentTime;

  MgLayer *layer = model->_layer;

  CFTimeInterval next = [layer renderInContext:ctx scale:self.contentsScale
			 presentationTime:now];

  [model _updateCurrentTime:now nextTime:next];
}

- (void)_updateCurrentTime:(CFTimeInterval)t nextTime:(CFTimeInterval)tn
{
  if (isfinite(tn))
    {
      if (!_addedAnimation)
	{
	  CABasicAnimation *anim = [CABasicAnimation animation];
	  anim.keyPath = @"currentTime";
	  anim.beginTime = t;
	  anim.duration = LONG_TIME;
	  anim.fromValue = @(t);
	  anim.toValue = @(t + LONG_TIME);
	  [self addAnimation:anim forKey:@"currentTime"];
	  _addedAnimation = YES;
	}
    }
  else
    {
      if (_addedAnimation)
	{
	  [self removeAnimationForKey:@"currentTime"];
	  _addedAnimation = NO;
	}
    }
}

@end
