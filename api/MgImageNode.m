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

#import "MgImageNode.h"

#import "MgCoderExtensions.h"
#import "MgDrawableNodeInternal.h"
#import "MgImageProvider.h"
#import "MgLayerNode.h"
#import "MgNodeInternal.h"

#import <Foundation/Foundation.h>

@implementation MgImageNode
{
  id<MgImageProvider> _imageProvider;
  CGRect _cropRect;
  CGRect _centerRect;
  BOOL _repeats;
}

static NSMutableSet *image_provider_classes;

+ (void)registerImageProviderClass:(Class)cls
{
  if (image_provider_classes == nil)
    image_provider_classes = [[NSMutableSet alloc] init];

  [image_provider_classes addObject:cls];
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _cropRect = CGRectNull;
  _centerRect = CGRectNull;

  return self;
}

+ (BOOL)automaticallyNotifiesObserversOfImageProvider
{
  return NO;
}

- (id<MgImageProvider>)imageProvider
{
  return _imageProvider;
}

- (void)setImageProvider:(id<MgImageProvider>)p
{
  if (_imageProvider != p)
    {
      [self willChangeValueForKey:@"imageProvider"];
      _imageProvider = p;
      [self incrementVersion];
      [self didChangeValueForKey:@"imageProvider"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfCropRect
{
  return NO;
}

- (CGRect)cropRect
{
  return _cropRect;
}

- (void)setCropRect:(CGRect)r
{
  if (!CGRectEqualToRect(_cropRect, r))
    {
      [self willChangeValueForKey:@"cropRect"];
      _cropRect = r;
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
  return _centerRect;
}

- (void)setCenterRect:(CGRect)r
{
  if (!CGRectEqualToRect(_centerRect, r))
    {
      [self willChangeValueForKey:@"centerRect"];
      _centerRect = r;
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
  return _repeats;
}

- (void)setRepeats:(BOOL)flag
{
  if (_repeats != flag)
    {
      [self willChangeValueForKey:@"repeats"];
      _repeats = flag;
      [self incrementVersion];
      [self didChangeValueForKey:@"repeats"];
    }
}

- (NSArray *)nodesContainingPoint:(CGPoint)p layerNode:(MgLayerNode *)node
{
  if (node != nil && CGRectContainsPoint(node.bounds, p))
    return [NSArray arrayWithObject:self];
  else
    return @[];
}

- (void)_renderWithState:(MgDrawableRenderState *)rs
{
  if (self.hidden || rs->layer == nil)
    return;

  CGImageRef im = [self.imageProvider mg_providedImage];
  bool release_im = false;

  CGRect crop = self.cropRect;
  if (!CGRectIsNull(crop))
    {
      im = CGImageCreateWithImageInRect(im, crop);
      release_im = true;
    }

  if (im != NULL)
    {
      /* We're assuming top-left geometry, so flip images to keep them
	 oriented the right way vertically. */

      CGContextSaveGState(rs->ctx);
      CGContextTranslateCTM(rs->ctx, 0, rs->layer.bounds.size.height);
      CGContextScaleCTM(rs->ctx, 1, -1);

      /* FIXME: implement 9-part and tiling. */

      CGContextDrawImage(rs->ctx, rs->layer.bounds, im);

      CGContextRestoreGState(rs->ctx);

      if (release_im)
	CGImageRelease(im);
    }
}

- (void)_renderMaskWithState:(MgDrawableRenderState *)rs
{
  /* FIXME: incorrect, assumes image is opaque. Could just call
     CGContextClipToMask() and hope it does the right thing? */

  CGContextClipToRect(rs->ctx, rs->layer.bounds);
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgImageNode *copy = [super copyWithZone:zone];

  copy->_imageProvider = _imageProvider;
  copy->_cropRect = _cropRect;
  copy->_centerRect = _centerRect;
  copy->_repeats = _repeats;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  if (_imageProvider != nil
      && [_imageProvider conformsToProtocol:@protocol(NSSecureCoding)])
    {
      [c encodeObject:_imageProvider forKey:@"imageProvider"];
    }

  if (!CGRectIsNull(_cropRect))
    [c mg_encodeCGRect:_cropRect forKey:@"cropRect"];

  if (!CGRectIsNull(_centerRect))
    [c mg_encodeCGRect:_centerRect forKey:@"centerRect"];

  if (_repeats)
    [c encodeBool:_repeats forKey:@"repeats"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  if (image_provider_classes == nil)
    [MgImageNode registerImageProviderClass:[MgImageProvider class]];

  if (image_provider_classes != nil
      && [c containsValueForKey:@"imageProvider"])
    {
      _imageProvider = [c decodeObjectOfClasses:image_provider_classes
			forKey:@"imageProvider"];
    }

  if ([c containsValueForKey:@"cropRect"])
    _cropRect = [c mg_decodeCGRectForKey:@"cropRect"];
  else
    _cropRect = CGRectNull;

  if ([c containsValueForKey:@"centerRect"])
    _centerRect = [c mg_decodeCGRectForKey:@"centerRect"];
  else
    _centerRect = CGRectNull;

  if ([c containsValueForKey:@"repeats"])
    _repeats = [c decodeBoolForKey:@"repeats"];

  return self;
}

@end
