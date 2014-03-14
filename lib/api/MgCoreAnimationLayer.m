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
   node graph to a layer tree. */

@implementation MgCoreAnimationLayer
{
  MgLayer *_layer;
  NSInteger _lastVersion;
  BOOL _addedObserver;
}

+ (id)defaultValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"needsDisplayOnBoundsChange"])
    return @YES;
  else if ([key isEqualToString:@"drawsAsynchronously"])
    return @YES;
  else
    return [super defaultValueForKey:key];
}

- (id)initWithLayer:(MgCoreAnimationLayer *)layer
{
  self = [super init];
  if (self == nil)
    return nil;

  _layer = layer->_layer;
  _lastVersion = layer->_lastVersion;

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

- (void)drawInContext:(CGContextRef)ctx
{
#if !TARGET_OS_IPHONE
  CGContextSaveGState(ctx);
  CGContextTranslateCTM(ctx, 0, self.bounds.size.height);
  CGContextScaleCTM(ctx, 1, -1);
#endif

  [_layer renderInContext:ctx]; 
  _lastVersion = _layer.version;

#if !TARGET_OS_IPHONE
  CGContextRestoreGState(ctx);
#endif
}

@end
