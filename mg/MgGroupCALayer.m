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

#import "MgActiveTransition.h"
#import "MgGroupLayer.h"
#import "MgLayerState.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

static void
layoutSublayers(CALayer *self, MgGroupLayer *layer, MgViewContext *ctx)
{
  NSArray *old_sublayers = self.sublayers;

  NSArray *new_sublayers
    = [ctx makeViewLayersForLayers:layer.sublayers
       candidates:old_sublayers culler:^BOOL (MgLayer *src)
        {
	  float alpha = src.alpha;

	  MgActiveTransition *trans = src.activeTransition;
	  if (trans != nil)
	    alpha = fmaxf(alpha, ((MgLayerState *)trans.fromState).alpha);

	  return !(alpha > 0);
	}];

  if (new_sublayers != old_sublayers)
    self.sublayers = new_sublayers;

  for (CALayer<MgViewLayer> *layer in new_sublayers)
    [layer update];
}

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

  layoutSublayers(self, _layer, _viewContext);
}

@end

/* FIXME: it sucks that this is a verbatim copy of the above class, but
   I'm resisting macroizing it. */

@implementation MgGroupCATransformLayer
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

- (id)initWithLayer:(MgGroupCATransformLayer *)layer
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

  layoutSublayers(self, _layer, _viewContext);
}

@end
