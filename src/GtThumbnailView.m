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

#import "GtThumbnailView.h"

#import "GtColor.h"

#import "MgMacros.h"

@interface GtThumbnailViewImageLayer : CALayer
@end

@implementation GtThumbnailView
{
  id _image;				/* CGImageRef */
}

- (CGImageRef)image
{
  return (__bridge CGImageRef)_image;
}

- (void)setImage:(CGImageRef)image
{
  if (_image != (__bridge id)image)
    {
      _image = (__bridge id)image;
      [self setNeedsDisplay:YES];
    }
}

- (BOOL)wantsUpdateLayer
{
  return YES;
}

- (void)updateLayer
{
  CALayer *layer = [self layer];

  GtThumbnailViewImageLayer *image_layer = (id)[layer.sublayers firstObject];

  if (image_layer == nil)
    {
      image_layer = [GtThumbnailViewImageLayer layer];
      image_layer.delegate = [NSApp delegate];
      [layer addSublayer:image_layer];
    }

  CGImageRef image = self.image;

  if (image != NULL)
    {
      CGRect bounds = layer.bounds;

      CGFloat width = CGImageGetWidth(image);
      CGFloat height = CGImageGetHeight(image);

      CGFloat sx = bounds.size.width / width;
      CGFloat sy = bounds.size.height / height;

      CGRect frame = bounds;

      if (sy < sx)
	{
	  frame.size.width = width * sy;
	  frame.origin.x += floor((bounds.size.width - frame.size.width) * .5);
	}
      else
	{
	  frame.size.height = height * sx;
	  frame.origin.y += floor((bounds.size.height - frame.size.height) * .5);
	}

      image_layer.frame = frame;
      image_layer.contents = _image;
    }
}

@end

@implementation GtThumbnailViewImageLayer

+ (id)defaultValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"anchorPoint"])
    return BOX(CGPointZero);
  else if ([key isEqualToString:@"borderWidth"])
    return @1;
  else if ([key isEqualToString:@"borderColor"])
    return (__bridge id)[[GtColor thumbnailBorderColor] CGColor];
  else if ([key isEqualToString:@"backgroundColor"])
    return (__bridge id)[GtColor thumbnailBackgroundCGColor];
  else
    return [super defaultValueForKey:key];
}

@end
