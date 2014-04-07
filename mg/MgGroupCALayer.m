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

#import "MgGroupCALayer.h"

#import "MgGroupLayer.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@implementation MgGroupCALayer
{
  MgGroupLayer *_layer;
  __weak MgViewContext *_viewContext;

  NSInteger _lastVersion;
}

- (id)initWithMgLayer:(MgLayer *)layer viewContext:(MgViewContext *)ctx
{
  self = [super init];
  if (self == nil)
    return nil;

  if (![layer isKindOfClass:[MgGroupLayer class]])
    return nil;

  _layer = (MgGroupLayer *)layer;
  _viewContext = ctx;

  [self setNeedsLayout];

  return self;
}

- (id)initWithLayer:(MgGroupCALayer *)layer
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

  /* FIXME: handle "group" property somehow. */

  NSMapTable *map = [NSMapTable strongToStrongObjectsMapTable];

  for (CALayer<MgViewLayer> *layer in self.sublayers)
    {
      [map setObject:layer forKey:layer.layer];
    }

  NSMutableArray *sublayers = [NSMutableArray array];

  for (MgLayer *src in _layer.sublayers)
    {
      if (src.enabled)
	{
	  [sublayers addObject:[_viewContext makeViewLayerForLayer:src
				candidateLayer:[map objectForKey:src]]];
	}
    }

  self.sublayers = sublayers;

  for (CALayer<MgViewLayer> *layer in sublayers)
    [layer update];
}

@end
