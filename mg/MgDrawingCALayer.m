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

#import "MgDrawingCALayer.h"

#import "MgDrawingLayerInternal.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@implementation MgDrawingCALayer
{
  MgDrawingLayer *_layer;
  __weak MgViewContext *_viewContext;

  NSInteger _lastVersion;
  NSInteger _lastDrawingVersion;

  CGContextRef _context;
  CGFloat _contextScale;
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

- (id)initWithMgLayer:(MgLayer *)layer viewContext:(MgViewContext *)ctx
{
  self = [super init];
  if (self == nil)
    return nil;

  if (![layer isKindOfClass:[MgDrawingLayer class]])
    return nil;

  _layer = (MgDrawingLayer *)layer;
  _viewContext = ctx;

  [self setNeedsLayout];

  return self;
}

- (id)initWithLayer:(MgDrawingCALayer *)layer
{
  self = [super init];
  if (self == nil)
    return nil;

  _layer = layer->_layer;
  _lastVersion = layer->_lastVersion;

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
    }

  NSInteger drawingVersion = _layer.drawingVersion;

  if (drawingVersion != _lastDrawingVersion)
    {
      _lastDrawingVersion = drawingVersion;

      [self setNeedsDisplay];
    }
}

- (void)layoutSublayers
{
  [_viewContext updateViewLayer:self];

  self.opaque = _layer.opaque;
}

- (void)drawInContext:(CGContextRef)ctx
{
  _context = ctx;
  _contextScale = self.contentsScale;

  [_layer drawWithState:self];

  _context = NULL;
  _contextScale = 0;
}

/** MgDrawingState methods. **/

- (CGContextRef)context
{
  return _context;
}

- (CGFloat)contextScale
{
  return _contextScale;
}

@end
