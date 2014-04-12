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

#import "MgActiveTransition.h"
#import "MgBezierTimingFunction.h"
#import "MgFlatteningCALayer.h"
#import "MgLayerInternal.h"
#import "MgNodeState.h"
#import "MgTransitionTiming.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "MgMacros.h"

#if FIXME_PRIVATE_API_USAGE
@interface CAFilter : NSObject
+ (id)filterWithType:(NSString *)str;
@end
#endif

/* Define this to "1" to use the CG rendering path. */

#define FORCE_DRAWING 0

#define ANIMATION_KEY "org.unfactored.MgTransition"

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
      _viewLayer = [self makeViewLayerForLayer:_layer candidate:nil];
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
					  candidate:layer.mask];
      layer.mask = view_layer;
      [view_layer update];
    }

  CFTimeInterval now = CACurrentMediaTime();

  [src markPresentationTime:now];

  MgActiveTransition *transition = src.activeTransition;

  if (transition != nil)
    {
      /* FIXME: something better. */

      CAAnimationGroup *group = (id)[layer animationForKey:@ANIMATION_KEY];

      if (group != nil)
	{
	  NSInteger ident = [[group valueForKey:@"identifier"] integerValue];

	  if (transition.identifier != ident)
	    {
	      [layer removeAnimationForKey:@ANIMATION_KEY];
	      group = nil;
	    }
	}

      if (group == nil)
	{
	  group = [CAAnimationGroup animation];

	  group.beginTime = transition.begin;
	  group.duration = transition.duration;
	  group.speed = transition.speed;

	  if ([layer respondsToSelector:
	       @selector(makeAnimationsForTransition:)])
	    {
	      group.animations
	        = [layer makeAnimationsForTransition:transition];
	    }
	  else
	    {
	      group.animations = [self makeAnimationsForTransition:transition
				  viewLayer:layer];
	    }

	  group.removedOnCompletion = YES;
	  group.delegate = self;
	  [group setValue:src forKey:@"layer"];
	  [group setValue:@(transition.identifier) forKey:@"identifier"];

	  [layer addAnimation:group forKey:@ANIMATION_KEY];
	}
    }
  else
    [layer removeAnimationForKey:@ANIMATION_KEY];
}

- (CALayer<MgViewLayer> *)makeViewLayerForLayer:(MgLayer *)src
    candidate:(CALayer *)layer
{
  Class cls = (!FORCE_DRAWING ? [src viewLayerClass]
	       : [MgFlatteningCALayer class]);

  if ([layer class] == cls && ((CALayer<MgViewLayer> *)layer).layer == src)
    return (CALayer<MgViewLayer> *)layer;

  CALayer<MgViewLayer> *view_layer = [[cls alloc] initWithMgLayer:src
				      viewContext:self];

  view_layer.delegate = self;

  return view_layer;
}

- (NSArray *)makeViewLayersForLayers:(NSArray *)array
    candidates:(NSArray *)layers culler:(BOOL (^)(MgLayer *src))pred
{
  NSInteger count = [array count];

  if (count == 0)
    return @[];

  __unsafe_unretained MgLayer **src_layers = STACK_ALLOC_ARC(MgLayer *, count);
  __unsafe_unretained Class *src_classes = STACK_ALLOC_ARC(Class, count);

  if (src_layers != NULL && src_classes != NULL)
    {
      NSInteger actual_count = 0;

      for (MgLayer *src in array)
	{
	  if (!pred || !pred(src))
	    {
	      src_layers[actual_count] = src;
	      if (!FORCE_DRAWING)
		src_classes[actual_count] = [src viewLayerClass];
	      else
		src_classes[actual_count] = [MgFlatteningCALayer class];
	      actual_count++;
	    }
	}

      BOOL finished = NO;

      /* First pass just checks for nothing changing, the common case. */
	  
      if ([layers count] == actual_count)
	{
	  finished = YES;

	  for (NSInteger i = 0; i < actual_count; i++)
	    {
	      CALayer<MgViewLayer> *layer = layers[i];

	      if (layer.layer != src_layers[i]
		  || [layer class] != src_classes[i])
		{
		  finished = NO;
		  break;
		}
	    }
	}

      /* Next pass rebuilds the array, reusing existing layers where
	 possible. */

      if (!finished)
	{
	  NSMapTable *map = [NSMapTable strongToStrongObjectsMapTable];

	  for (CALayer<MgViewLayer> *layer in layers)
	    {
	      [map setObject:layer forKey:layer.layer];
	    }

	  NSMutableArray *new_layers = [NSMutableArray array];

	  for (NSInteger i = 0; i < actual_count; i++)
	    {
	      MgLayer *src = src_layers[i];

	      CALayer<MgViewLayer> *layer = [map objectForKey:src];

	      if (layer == nil
		  || layer.layer != src_layers[i]
		  || [layer class] != src_classes[i])
		{
		  layer = [[src_classes[i] alloc] initWithMgLayer:
			   src_layers[i] viewContext:self];
		  layer.delegate = self;
		}
	      else
		[map removeObjectForKey:src];

	      [new_layers addObject:layer];
	    }

	  layers = new_layers;
	}
    }
  else
    layers = @[];

  STACK_FREE(MgLayer *, count, src_layers);
  STACK_FREE(Class, count, src_classes);

  return layers;
}

+ (NSDictionary *)animationMap
{
  static NSDictionary *map;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      /* FIXME: why do we need to negate the values being used in
	 the transform.rotation.z key-path? Seems like a bug somewhere.
	 Ideally would use [CAValueFunction rotateZ], but would need
	 to get the right concatenation behavior somehow. */

      MgViewAnimationBlock rotation_block = ^(MgViewContext *ctx,
	  CALayer<MgViewLayer> *layer, NSString *key, MgTransitionTiming
	  *timing, id fromValue, id toValue)
	{	
	  fromValue = @(-[fromValue doubleValue]);
	  toValue = @(-[toValue doubleValue]);

	  return [ctx makeAnimationForTiming:timing
		  key:@"transform.rotation.z" from:fromValue to:toValue];
	};

      /* FIXME: no way to handle skew directly? */

      map = @{
	@"position" : @"position",
	@"anchor" : @"anchorPoint",
	@"size" : @"bounds.size",
	@"origin" : @"bounds.origin",
	@"alpha" : @"opacity",
	@"scale" : @"transform.scale.xy",
	@"squeeze" : @"transform.scale.x",
	@"rotation" : rotation_block,
      };
    });

  return map;
}

- (NSMutableArray *)makeAnimationsForTransition:(MgActiveTransition *)trans
    viewLayer:(CALayer<MgViewLayer> *)layer
{
  MgLayer *src = layer.layer;
  NSSet *properties = trans.properties;
  MgNodeState *from_state = trans.fromState;
  MgNodeState *to_state = src.state;

  NSDictionary *map = nil;
  if ([[layer class] respondsToSelector:@selector(animationMap)])
    map = [[layer class] animationMap];
  else
    map = [[self class] animationMap];

  NSMutableArray *animations = [NSMutableArray array];

  for (NSString *key in [[[src class] stateClass] allProperties])
    {
      if (![properties containsObject:key])
	continue;

      id map_value = map[key];
      if (map_value == nil)
	continue;

      MgTransitionTiming *timing = [trans timingForKey:key];
      if (timing == nil || !timing.enabled)
	continue;

      /* FIXME: this is wrong -- we should query the value of the CA
	 property in from/to versions of the view-layer, not the Mg key
	 in the source object. */

      id from_value = [from_state valueForKey:key];
      id to_value = [to_state valueForKey:key];

      CAAnimation *anim = nil;

      if ([map_value isKindOfClass:[NSString class]])
	{
	  anim = [self makeAnimationForTiming:timing
		  key:map_value from:from_value to:to_value];
	}
      else
	{
	  anim = ((MgViewAnimationBlock)map_value)(self, layer, key, timing,
						   from_value, to_value);
	}

      if (anim != nil)
	[animations addObject:anim];
    }

  return animations;
}

- (CAAnimation *)makeAnimationForTiming:(MgTransitionTiming *)timing
    key:(NSString *)key from:(id)fromValue to:(id)toValue
{
  CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:key];

  anim.beginTime = timing.begin;
  anim.duration = timing.duration;
  anim.fillMode = kCAFillModeBackwards;
  anim.fromValue = fromValue;
  anim.toValue = toValue;

  MgFunction *fun = timing.function;

  if (fun != nil)
    {
      if ([fun isKindOfClass:[MgBezierTimingFunction class]])
	{
	  CGPoint p1 = ((MgBezierTimingFunction *)fun).p0;
	  CGPoint p2 = ((MgBezierTimingFunction *)fun).p1;

	  CAMediaTimingFunction *fun
	    = [[CAMediaTimingFunction alloc]
	       initWithControlPoints:p1.x :p1.y :p2.x :p2.y];

	  anim.timingFunction = fun;
	}
      else
	NSLog(@"FIXME: unsupported timing function: %@", fun);
    }

  return anim;
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
  return (__bridge id)kCFNull;
}

/** CAAnimationDelegate methods. **/

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
  /* Try to remove the transition. */

  MgLayer *layer = [anim valueForKey:@"layer"];

  [layer markPresentationTime:CACurrentMediaTime()];
}

@end
