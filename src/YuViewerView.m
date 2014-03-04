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

#import "YuViewerView.h"

#import "YuDocument.h"
#import "YuViewerViewController.h"

#import "MgLayer.h"

@implementation YuViewerView
{
  MgLayer *_nodeLayer;
}

- (id)initWithFrame:(NSRect)r
{
  self = [super initWithFrame:r];
  if (self == nil)
    return nil;

  _viewScale = 1;

  return self;
}

- (BOOL)wantsUpdateLayer
{
  return YES;
}

- (void)updateLayer
{
  CALayer *layer = [self layer];

  layer.backgroundColor = [[NSColor darkGrayColor] CGColor];

  if (_nodeLayer == nil)
    {
      _nodeLayer = [MgLayer layer];
      _nodeLayer.delegate = [NSApp delegate];
      _nodeLayer.anchorPoint = CGPointZero;
      [layer addSublayer:_nodeLayer];
    }

  YuDocument *document = self.controller.document;
  CGSize doc_size = document.documentSize;
  CGPoint origin = self.viewOrigin;
  CGFloat scale = self.viewScale;

  _nodeLayer.rootNode = document.rootNode;
  _nodeLayer.affineTransform = CGAffineTransformMakeScale(scale, scale);
  _nodeLayer.bounds = CGRectMake(0, 0, doc_size.width, doc_size.height);
  _nodeLayer.position = origin;
}

- (void)setNeedsUpdate
{
  [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
  return YES;
}

@end
