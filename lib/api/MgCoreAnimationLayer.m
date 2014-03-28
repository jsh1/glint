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

#import "MgCoreAnimationLayer.h"

#import "MgLayer.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/* FIXME: this is junk. Draws using CG, on the main thread, ignoring
   animations. Will be superseded by something that translates the
   node graph to a layer tree.

   Using a CA client-side animation to drive our rendering during
   Mg transitions, set up a property whose interpolated values will
   match the current presentation time. */

@interface MgCoreAnimationLayer ()
@property(nonatomic) double currentTime;
@end

#define LONG_TIME (3600*24*365*10)

@implementation MgCoreAnimationLayer
{
  MgLayer *_layer;
  double _currentTime;
  NSInteger _lastVersion;
  BOOL _addedObserver;
  BOOL _addedAnimation;

  __weak MgCoreAnimationLayer *_modelLayer;
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

- (id)initWithLayer:(MgCoreAnimationLayer *)layer
{
  self = [super init];
  if (self == nil)
    return nil;

  _layer = layer->_layer;
  _lastVersion = layer->_lastVersion;

  _modelLayer = layer;

  return self;
}

- (void)dealloc
{
  if (_addedObserver)
    [_layer removeObserver:self forKeyPath:@"version"];
}

+ (BOOL)automaticallyNotifiesObserversOfLayer
{
  return NO;
}

- (MgLayer *)layer
{
  return _layer;
}

- (void)setLayer:(MgLayer *)node
{
  if (_layer != node)
    {
      [self willChangeValueForKey:@"layer"];

      [_layer removeObserver:self forKeyPath:@"version"];

      _layer = node;
      _lastVersion = 0;

      [_layer addObserver:self forKeyPath:@"version" options:0 context:nil];

      _addedObserver = YES;
      
      [self setNeedsDisplay];

      [self didChangeValueForKey:@"layer"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
     change:(NSDictionary *)dict context:(void *)ctx
{
  if ([keyPath isEqualToString:@"version"])
    {
      if (_layer != nil && _layer.version != _lastVersion)
	[self setNeedsDisplay];
    }
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

- (void)drawInContext:(CGContextRef)ctx
{
  /* FIXME: -[CALayer modelLayer] seems to be broken for client-side
     animation copies?

     FIXME: and self.bounds seems to return CGRectZero, wtf!? */

  MgCoreAnimationLayer *model = _modelLayer;

  CFTimeInterval now;
  if (model == nil)
    {
      model = self;
      now = CACurrentMediaTime();
    }
  else
    {
      now = self.currentTime;
    }

#if !TARGET_OS_IPHONE
  CGContextSaveGState(ctx);
  CGContextTranslateCTM(ctx, 0, model.bounds.size.height);
  CGContextScaleCTM(ctx, 1, -1);
#endif

  MgLayer *layer = model->_layer;

  CFTimeInterval next = [layer renderInContext:ctx presentationTime:now]; 

  model->_lastVersion = layer.version;

  [model _updateCurrentTime:now nextTime:next];

#if !TARGET_OS_IPHONE
  CGContextRestoreGState(ctx);
#endif
}

@end
