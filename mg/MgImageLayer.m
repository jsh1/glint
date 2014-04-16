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

#import "MgImageLayer.h"

#import "MgCoderExtensions.h"
#import "MgImageCALayer.h"
#import "MgImageLayerState.h"
#import "MgImageProvider.h"
#import "MgLayerInternal.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

#define STATE ((MgImageLayerState *)(self.state))

@implementation MgImageLayer

static NSMutableSet *image_provider_classes;

+ (Class)stateClass
{
  return [MgImageLayerState class];
}

- (Class)viewLayerClass
{
  if ([MgImageCALayer supportsLayer:self])
    return [MgImageCALayer class];
  else
    return [super viewLayerClass];
}

+ (void)registerImageProviderClass:(Class)cls
{
  if (image_provider_classes == nil)
    image_provider_classes = [[NSMutableSet alloc] init];

  [image_provider_classes addObject:cls];
}

+ (NSSet *)imageProviderClasses
{
  if (image_provider_classes == nil)
    [MgImageLayer registerImageProviderClass:[MgImageProvider class]];

  return image_provider_classes;
}

+ (BOOL)automaticallyNotifiesObserversOfImageProvider
{
  return NO;
}

- (id<MgImageProvider>)imageProvider
{
  return STATE.imageProvider;
}

- (void)setImageProvider:(id<MgImageProvider>)p
{
  MgImageLayerState *state = STATE;

  if (state.imageProvider != p)
    {
      [self willChangeValueForKey:@"imageProvider"];
      state.imageProvider = p;
      [self incrementVersion];
      [self didChangeValueForKey:@"imageProvider"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfInterpolationQuality
{
  return NO;
}

- (CGInterpolationQuality)interpolationQuality
{
  return STATE.interpolationQuality;
}

- (void)setInterpolationQuality:(CGInterpolationQuality)q
{
  MgImageLayerState *state = STATE;

  if (state.interpolationQuality != q)
    {
      [self willChangeValueForKey:@"interpolationQuality"];
      state.interpolationQuality = q;
      [self incrementVersion];
      [self didChangeValueForKey:@"interpolationQuality"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfCropRect
{
  return NO;
}

- (CGRect)cropRect
{
  return STATE.cropRect;
}

- (void)setCropRect:(CGRect)r
{
  MgImageLayerState *state = STATE;

  if (!CGRectEqualToRect(state.cropRect, r))
    {
      [self willChangeValueForKey:@"cropRect"];
      state.cropRect = r;
      [self incrementVersion];
      [self didChangeValueForKey:@"cropRect"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfCenterRect
{
  return NO;
}

- (CGRect)centerRect
{
  return STATE.centerRect;
}

- (void)setCenterRect:(CGRect)r
{
  MgImageLayerState *state = STATE;

  if (!CGRectEqualToRect(state.centerRect, r))
    {
      [self willChangeValueForKey:@"centerRect"];
      state.centerRect = r;
      [self incrementVersion];
      [self didChangeValueForKey:@"centerRect"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfRepeats
{
  return NO;
}

- (BOOL)repeats
{
  return STATE.repeats;
}

- (void)setRepeats:(BOOL)flag
{
  MgImageLayerState *state = STATE;

  if (state.repeats != flag)
    {
      [self willChangeValueForKey:@"repeats"];
      state.repeats = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"repeats"];
    }
}

- (void)_renderLayerWithState:(MgLayerRenderState *)rs
{
  CGImageRef im = [self.imageProvider mg_providedImage];
  bool release_im = false;

  CGRect crop = self.cropRect;
  if (!CGRectIsEmpty(crop))
    {
      im = CGImageCreateWithImageInRect(im, crop);
      release_im = true;
    }

  if (im != NULL)
    {
      /* We're assuming top-left geometry, so flip images to keep them
	 oriented the right way vertically. */

      CGContextSaveGState(rs->ctx);
      CGContextTranslateCTM(rs->ctx, 0, self.bounds.size.height);
      CGContextScaleCTM(rs->ctx, 1, -1);

      /* FIXME: implement 9-part and tiling.
	 FIXME: is interpolationQuality part of the gstate? */

      CGInterpolationQuality old_quality
        = CGContextGetInterpolationQuality(rs->ctx);

      CGContextSetInterpolationQuality(rs->ctx, self.interpolationQuality);

      CGContextDrawImage(rs->ctx, self.bounds, im);

      CGContextSetInterpolationQuality(rs->ctx, old_quality);

      CGContextRestoreGState(rs->ctx);

      if (release_im)
	CGImageRelease(im);
    }
}

- (void)_renderLayerMaskWithState:(MgLayerRenderState *)rs
{
  float alpha = rs->alpha * self.alpha;

  if (alpha != 1)
    {
      [super _renderLayerMaskWithState:rs];
      return;
    }

  /* FIXME: incorrect, assumes image is opaque. Could just call
     CGContextClipToMask() and hope it does the right thing? */

  CGContextClipToRect(rs->ctx, self.bounds);
}

@end
