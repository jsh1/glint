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

#import "MgPathCALayer.h"

#import "MgPathLayer.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@implementation MgPathCALayer
{
  MgPathLayer *_layer;
  __weak MgViewContext *_viewContext;

  NSInteger _lastVersion;
}

- (id)initWithMgLayer:(MgLayer *)layer viewContext:(MgViewContext *)ctx
{
  self = [super init];
  if (self == nil)
    return nil;

  if (![layer isKindOfClass:[MgPathLayer class]])
    return nil;

  _layer = (MgPathLayer *)layer;
  _viewContext = ctx;

  [self setNeedsLayout];

  return self;
}

- (id)initWithLayer:(MgPathCALayer *)layer
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

  self.path = _layer.path;

  CGPathDrawingMode mode = _layer.drawingMode;

  if (mode != kCGPathStroke)
    {
      self.fillColor = _layer.fillColor;
      if (mode == kCGPathFill || mode == kCGPathFillStroke)
	self.fillRule = kCAFillRuleNonZero;
      else
	self.fillRule = kCAFillRuleEvenOdd;
    }
  else
    self.fillColor = NULL;

  if (mode >= kCGPathStroke)
    {
      self.strokeColor = _layer.strokeColor;
      self.lineWidth = _layer.lineWidth;
      self.miterLimit = _layer.miterLimit;

      switch (_layer.lineCap)
	{
	case kCGLineCapButt:
	  self.lineCap = kCALineCapButt;
	  break;
	case kCGLineCapRound:
	  self.lineCap = kCALineCapRound;
	  break;
	case kCGLineCapSquare:
	  self.lineCap = kCALineCapSquare;
	  break;
	}

      switch (_layer.lineJoin)
	{
	case kCGLineJoinMiter:
	  self.lineJoin = kCALineJoinMiter;
	  break;
	case kCGLineJoinRound:
	  self.lineJoin = kCALineJoinRound;
	  break;
	case kCGLineJoinBevel:
	  self.lineJoin = kCALineJoinBevel;
	  break;
	}

      self.lineDashPhase = _layer.lineDashPhase;
      self.lineDashPattern = _layer.lineDashPattern;
    }
  else
    self.strokeColor = NULL;
}

+ (NSDictionary *)animationMap
{
  static NSDictionary *map;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      NSMutableDictionary *dict = [[MgViewContext animationMap] mutableCopy];

      [dict addEntriesFromDictionary:@{
	 @"path" : @"path",
	 @"fillColor" : @"backgroundColor",
	 @"strokeColor" : @"borderColor",
	 @"lineWidth" : @"borderWidth",
	 @"miterLimit" : @"miterLimit",
	 @"lineDashPhase" : @"lineDashPhase",
	 @"lineDashPattern" : @"lineDashPattern",
       }];

      map = [dict copy];
    });

  return map;
}

@end
