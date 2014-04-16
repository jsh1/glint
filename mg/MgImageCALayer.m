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

#import "MgImageCALayer.h"

#import "MgImageLayer.h"
#import "MgImageProvider.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@implementation MgImageCALayer
{
  MgImageLayer *_layer;
  __weak MgViewContext *_viewContext;

  NSInteger _lastVersion;
}

+ (BOOL)supportsLayer:(MgImageLayer *)layer
{
  return !layer.repeats;
}

- (id)initWithMgLayer:(MgLayer *)layer viewContext:(MgViewContext *)ctx
{
  self = [super init];
  if (self == nil)
    return nil;

  if (![layer isKindOfClass:[MgImageLayer class]])
    return nil;

  _layer = (MgImageLayer *)layer;
  _viewContext = ctx;

  [self setNeedsLayout];

  return self;
}

- (id)initWithLayer:(MgImageCALayer *)layer
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

  CGImageRef image = [_layer.imageProvider mg_providedImage];

  if (image != NULL)
    {
      self.contents = (__bridge id)image;

      CGInterpolationQuality quality = _layer.interpolationQuality;
                      
      NSString *min_filter = nil, *mag_filter = nil;
      switch (quality)
	{
	case kCGInterpolationNone:
	  min_filter = mag_filter = kCAFilterNearest;
	  break;

	case kCGInterpolationLow:
	  min_filter = mag_filter = kCAFilterLinear;
	  break;

	case kCGInterpolationDefault:
	case kCGInterpolationMedium:
	case kCGInterpolationHigh:
	  min_filter = kCAFilterTrilinear;
	  mag_filter = kCAFilterLinear;
	  break;
	}

      self.minificationFilter = min_filter;
      self.magnificationFilter = mag_filter;

      CGRect crop = _layer.cropRect;
      CGRect center = _layer.centerRect;

      bool crop_empty = CGRectIsEmpty(crop);
      bool center_empty = CGRectIsEmpty(center);

      double width_r = 0, height_r = 0;

      if (!crop_empty || !center_empty)
	{
	  width_r = 1./CGImageGetWidth(image);
	  height_r = 1./CGImageGetHeight(image);
	}

      if (!crop_empty)
	{
	  self.contentsRect = CGRectMake(crop.origin.x * width_r,
					 crop.origin.y * height_r,
					 crop.size.width * width_r,
					 crop.size.height * height_r);
	}
      else
	self.contentsRect = CGRectMake(0, 0, 1, 1);

      if (!center_empty)
	{
	  self.contentsCenter = CGRectMake(center.origin.x * width_r,
					   center.origin.y * height_r,
					   center.size.width * width_r,
					   center.size.height * height_r);
	}
      else
	self.contentsCenter = CGRectMake(0, 0, 1, 1);
    }
  else
    self.contents = nil;
}

@end
