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
      Class cls = [[_layer class] viewLayerClass];
      _viewLayer = [[cls alloc] initWithMgLayer:_layer];
      [_viewLayer update];
    }

  return _viewLayer;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
     change:(NSDictionary *)dict context:(void *)ctx
{
  if ([keyPath isEqualToString:@"version"])
    {
      [_viewLayer update];
    }
}

@end
