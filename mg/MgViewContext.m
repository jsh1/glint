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

#import "MgViewContext.h"

#import "MgLayerInternal.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#if FIXME_PRIVATE_API_USAGE
@interface CAFilter : NSObject
+ (id)filterWithType:(NSString *)str;
@end
#endif

@implementation MgViewContext
{
  MgLayer *_layer;

  CALayer<MgViewLayer> *_viewLayer;
}

+ (MgViewContext *)contextWithLayer:(MgLayer *)layer
{
  return [[self alloc] initWithLayer:layer];
}

- (id)initWithLayer:(MgLayer *)layer
{
  self = [super init];
  if (self == nil)
    return nil;

  _layer = layer;

  [_layer addObserver:self forKeyPath:@"version" options:0 context:nil];

  return self;
}

- (void)dealloc
{
  [_layer removeObserver:self forKeyPath:@"version"];
}

- (CALayer *)viewLayer
{
  if (_viewLayer == nil)
    {
      _viewLayer = [self makeViewLayerForLayer:_layer candidateLayer:nil];
      [_viewLayer update];
#if !TARGET_OS_IPHONE
      _viewLayer.geometryFlipped = YES;
#endif
    }

  return _viewLayer;
}

static id
blendModeFilter(CGBlendMode blend_mode)
{
  if (blend_mode == kCGBlendModeNormal)
    return nil;
  
#if FIXME_PRIVATE_API_USAGE
  NSString *filter = nil;

  /* See https://github.com/WebKit/webkit/blob/master/Source/WebCore/platform/graphics/ca/mac/PlatformCAFiltersMac.mm */
  
  switch (blend_mode)
    {
      extern NSString *kCAFilterMultiplyBlendMode,
      *kCAFilterScreenBlendMode, *kCAFilterOverlayBlendMode,
      *kCAFilterDarkenBlendMode, *kCAFilterLightenBlendMode,
      *kCAFilterColorDodgeBlendMode, *kCAFilterColorBurnBlendMode,
      *kCAFilterSoftLightBlendMode, *kCAFilterHardLightBlendMode,
      *kCAFilterDifferenceBlendMode, *kCAFilterExclusionBlendMode,
      *kCAFilterExclusionBlendMode, *kCAFilterClear, *kCAFilterCopy,
      *kCAFilterSourceIn, *kCAFilterSourceOut, *kCAFilterSourceAtop,
      *kCAFilterDestOver, *kCAFilterDestIn, *kCAFilterDestOut,
      *kCAFilterDestAtop, *kCAFilterXor, *kCAFilterPlusD,
      *kCAFilterPlusL;
      
    case kCGBlendModeMultiply:
      filter = kCAFilterMultiplyBlendMode;
      break;
    case kCGBlendModeScreen:
      filter = kCAFilterScreenBlendMode;
      break;
    case kCGBlendModeOverlay:
      filter = kCAFilterOverlayBlendMode;
      break;
    case kCGBlendModeDarken:
      filter = kCAFilterDarkenBlendMode;
      break;
    case kCGBlendModeLighten:
      filter = kCAFilterLightenBlendMode;
      break;
    case kCGBlendModeColorDodge:
      filter = kCAFilterColorDodgeBlendMode;
      break;
    case kCGBlendModeColorBurn:
      filter = kCAFilterColorBurnBlendMode;
      break;
    case kCGBlendModeSoftLight:
      filter = kCAFilterSoftLightBlendMode;
      break;
    case kCGBlendModeHardLight:
      filter = kCAFilterHardLightBlendMode;
      break;
    case kCGBlendModeDifference:
      filter = kCAFilterDifferenceBlendMode;
      break;
    case kCGBlendModeExclusion:
      filter = kCAFilterExclusionBlendMode;
      break;
    case kCGBlendModeClear:
      filter = kCAFilterClear;
      break;
    case kCGBlendModeCopy:
      filter = kCAFilterCopy;
      break;
    case kCGBlendModeSourceIn:
      filter = kCAFilterSourceIn;
      break;
    case kCGBlendModeSourceOut:
      filter = kCAFilterSourceOut;
      break;
    case kCGBlendModeSourceAtop:
      filter = kCAFilterSourceAtop;
      break;
    case kCGBlendModeDestinationOver:
      filter = kCAFilterDestOver;
      break;
    case kCGBlendModeDestinationIn:
      filter = kCAFilterDestIn;
      break;
    case kCGBlendModeDestinationOut:
      filter = kCAFilterDestOut;
      break;
    case kCGBlendModeDestinationAtop:
      filter = kCAFilterDestAtop;
      break;
    case kCGBlendModeXOR:
      filter = kCAFilterXor;
      break;
    case kCGBlendModePlusDarker:
      filter = kCAFilterPlusD;
      break;
    case kCGBlendModePlusLighter:
      filter = kCAFilterPlusL;
      break;
      
    case kCGBlendModeNormal:
    case kCGBlendModeHue:
    case kCGBlendModeSaturation:
    case kCGBlendModeColor:
    case kCGBlendModeLuminosity:
      break;
    }
  
  if (filter != nil)
    return [CAFilter filterWithType:filter];
  else
    return nil;

#else
  return nil;
#endif
}

- (void)updateViewLayer:(CALayer<MgViewLayer> *)layer
{
  MgLayer *src = layer.layer;

  double m22 = src.scale;
  double m11 = m22 * src.squeeze;
  double m12 = 0;
  double m21 = m11 * src.skew;

  double rotation = src.rotation;
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

  layer.bounds = src.bounds;
  layer.anchorPoint = src.anchor;
  layer.position = src.position;
  layer.affineTransform = CGAffineTransformMake(m11, m12, m21, m22, 0, 0);
  layer.opacity = src.alpha;
  layer.compositingFilter = blendModeFilter(src.blendMode);

  MgLayer *mask = src.mask;
  if (mask == nil)
    layer.mask = nil;
  else
    {
      CALayer<MgViewLayer> *view_layer = [self makeViewLayerForLayer:mask
					  candidateLayer:layer.mask];
      layer.mask = view_layer;
      [view_layer update];
    }
}

- (CALayer<MgViewLayer> *)makeViewLayerForLayer:(MgLayer *)src
    candidateLayer:(CALayer *)layer
{
  Class cls = [src viewLayerClass];

  if ([layer class] == cls && ((CALayer<MgViewLayer> *)layer).layer == src)
    return (CALayer<MgViewLayer> *)layer;

  CALayer<MgViewLayer> *view_layer = [[cls alloc] initWithMgLayer:src
				      viewContext:self];

  view_layer.delegate = self;

  return view_layer;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
     change:(NSDictionary *)dict context:(void *)ctx
{
  if ([keyPath isEqualToString:@"version"])
    {
      [_viewLayer update];
    }
}

/** CALayerDelegate methods. **/

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)key
{
  return (id)kCFNull;
}

@end
