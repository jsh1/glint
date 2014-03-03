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

#import "MgBase.h"

/* Note: this object will be encoded along with any MgImageNode
   instances that refer to it, but only if it conforms to the
   NSSecureCoding protocol. We don't force this as many applications
   won't be serializing the objects. Caveat emptor! */

@protocol MgImageProvider <NSObject>

/* Should return the image that the receiver represents. */

- (CGImageRef)mg_providedImage;

@end

@interface MgImageProvider : NSObject <MgImageProvider, NSSecureCoding>

+ (instancetype)imageProviderWithImage:(CGImageRef)image;
+ (instancetype)imageProviderWithURL:(NSURL *)url;

/* These all return nil if result is not immediately available. */

@property(nonatomic, assign, readonly) CGImageRef image;
@property(nonatomic, copy, readonly) NSURL *URL;
@property(nonatomic, copy, readonly) NSData *imageData;

@end
