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

#import "MgRectCALayer.h"

#import "MgRectLayer.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@implementation MgRectCALayer
{
  MgRectLayer *_layer;
  __weak MgViewContext *_viewContext;

  NSInteger _lastVersion;
}

- (id)initWithMgLayer:(MgLayer *)layer viewContext:(MgViewContext *)ctx
{
  self = [super init];
  if (self == nil)
    return nil;

  if (![layer isKindOfClass:[MgRectLayer class]])
    return nil;

  _layer = (MgRectLayer *)layer;
  _viewContext = ctx;

  [self setNeedsLayout];

  return self;
}

- (id)initWithLayer:(MgRectCALayer *)layer
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
}

- (void)layoutSublayers
{
  [_viewContext updateViewLayer:self];

  CGFloat radius = _layer.cornerRadius;
  CGRect bounds = _layer.bounds;

  self.cornerRadius = fmin(radius, fmin(fabs(bounds.size.width),
					fabs(bounds.size.height)) * .5);

  CGPathDrawingMode mode = _layer.drawingMode;

  if (mode != kCGPathStroke)
    self.backgroundColor = _layer.fillColor;
  else
    self.backgroundColor = NULL;

  if (mode >= kCGPathStroke)
    {
      self.borderColor = _layer.strokeColor;
      self.borderWidth = _layer.lineWidth;
    }
  else
    self.borderWidth = 0;
}

+ (NSDictionary *)animationMap
{
  static NSDictionary *map;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      NSMutableDictionary *dict = [[MgViewContext animationMap] mutableCopy];

      [dict addEntriesFromDictionary:@{
	 @"cornerRadius" : @"cornerRadius",
	 @"fillColor" : @"backgroundColor",
	 @"strokeColor" : @"borderColor",
	 @"lineWidth" : @"borderWidth",
       }];

      map = [dict copy];
    });

  return map;
}

@end
