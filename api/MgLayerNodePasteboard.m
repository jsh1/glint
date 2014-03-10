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

#if TARGET_OS_MAC

#import "MgLayerNode.h"
#import "MgNodePasteboard.h"

#import "MgCoreGraphics.h"

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <AppKit/AppKit.h>

@interface MgLayerNode (MgNodePasteboard)
@end

@implementation MgLayerNode (MgNodePasteboard)

/** NSPasteboardWriting methods. **/

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pboard
{
  return [[super writableTypesForPasteboard:pboard]
	  arrayByAddingObject:@"public.png"];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
  if (UTTypeConformsTo((__bridge CFStringRef)type, kUTTypeImage))
    {
      CGRect bounds = self.bounds;

      CGImageRef im = MgImageCreateByDrawing(bounds.size.width,
		bounds.size.height, false, ^(CGContextRef ctx)
	{
	  CGContextTranslateCTM(ctx, 0, bounds.size.height);
	  CGContextScaleCTM(ctx, 1, -1);
	  CGContextTranslateCTM(ctx, bounds.origin.x, bounds.origin.y);
	  CGAffineTransform m = [self parentTransform];
	  CGContextConcatCTM(ctx, CGAffineTransformInvert(m));
	  [self renderInContext:ctx atTime:0];
	});

      NSMutableData *data = [NSMutableData data];

      CGImageDestinationRef dest = CGImageDestinationCreateWithData(
			(__bridge CFMutableDataRef)data,
			(__bridge CFStringRef)type, 1, NULL);

      if (dest != NULL)
	{
	  CGImageDestinationAddImage(dest, im, NULL);
	  CGImageDestinationFinalize(dest);
	  CFRelease(dest);
	}

      CGImageRelease(im);

      return data;
    }

  return [super pasteboardPropertyListForType:type];
}

@end

#endif /* TARGET_OS_MAC */
