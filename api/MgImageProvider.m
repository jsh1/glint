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

#import "MgImageProvider.h"

@implementation MgImageProvider
{
  id _image;				/* CGImageRef */
  id _imageSource;			/* CGImageSourceRef */
}

+ (instancetype)imageProviderWithImage:(CGImageRef)image
{
  if (image == NULL)
    return nil;

  MgImageProvider *p = [[self alloc] init];
  p->_image = (__bridge id)image;

  return p;
}

+ (instancetype)imageProviderWithURL:(NSURL *)url
{
  if (url == nil)
    return nil;

  CGImageSourceRef src
    = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);

  if (src == NULL)
    return nil;

  MgImageProvider *p = [[self alloc] init];
  p->_imageSource = CFBridgingRelease(src);

  return p;
}

- (CGImageRef)mg_providedImage
{
  if (_image != nil)
    {
      return (__bridge CGImageRef)_image;
    }
  else if (_imageSource != nil)
    {
      CGImageRef im = CGImageSourceCreateImageAtIndex(
			(__bridge CGImageSourceRef)_imageSource, 0, NULL);
      if (im != NULL)
	return (CGImageRef)CFAutorelease(im);
      else
	return NULL;
    }

  return NULL;
}


/** NSSecureCoding methods. **/

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)c
{
  NSLog(@"WARNING: MgImageProvider is ignoring -encodeWithCoder:");
}

- (id)initWithCoder:(NSCoder *)c
{
  return [self init];
}

@end
