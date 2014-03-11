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

#import "GtBase.h"

typedef NS_ENUM(NSInteger, GtViewerAdornment)
{
  GtViewerAdornmentCornerRadius,
  GtViewerAdornmentResizeTopLeft,
  GtViewerAdornmentResizeTop,
  GtViewerAdornmentResizeTopRight,
  GtViewerAdornmentResizeBottomLeft,
  GtViewerAdornmentResizeBottom,
  GtViewerAdornmentResizeBottomRight,
  GtViewerAdornmentResizeLeft,
  GtViewerAdornmentResizeRight,
  GtViewerAdornmentAnchor,
  GtViewerAdornmentRotate,
  GtViewerAdornmentScale,
  GtViewerAdornmentSqueeze,
  GtViewerAdornmentSkew,
};

enum
{
  GtViewerAdornmentCount = GtViewerAdornmentSkew + 1,
};

typedef NS_OPTIONS(NSUInteger, GtViewerAdornmentMask)
{
  GtViewerAdornmentMaskCornerRadius = 1U << GtViewerAdornmentCornerRadius,
  GtViewerAdornmentMaskResizeTopLeft = 1U << GtViewerAdornmentResizeTopLeft,
  GtViewerAdornmentMaskResizeTop = 1U << GtViewerAdornmentResizeTop,
  GtViewerAdornmentMaskResizeTopRight = 1U << GtViewerAdornmentResizeTopRight,
  GtViewerAdornmentMaskResizeBottomLeft = 1U << GtViewerAdornmentResizeBottomLeft,
  GtViewerAdornmentMaskResizeBottom = 1U << GtViewerAdornmentResizeBottom,
  GtViewerAdornmentMaskResizeBottomRight = 1U << GtViewerAdornmentResizeBottomRight,
  GtViewerAdornmentMaskResizeLeft = 1U << GtViewerAdornmentResizeLeft,
  GtViewerAdornmentMaskResizeRight = 1U << GtViewerAdornmentResizeRight,
  GtViewerAdornmentMaskAnchor = 1U << GtViewerAdornmentAnchor,
  GtViewerAdornmentMaskRotate = 1U << GtViewerAdornmentRotate,
  GtViewerAdornmentMaskScale = 1U << GtViewerAdornmentScale,
  GtViewerAdornmentMaskSqueeze = 1U << GtViewerAdornmentSqueeze,
  GtViewerAdornmentMaskSkew = 1U << GtViewerAdornmentSkew,
};

@interface GtViewerOverlayNode : MgDrawingLayer

@property(nonatomic, weak) GtViewerView *view;

@property(nonatomic, assign) GtViewerAdornmentMask adornmentMask;

- (void)update;

- (NSInteger)hitTest:(CGPoint)p inAdornmentsOfNode:(GtTreeNode *)node;

@end
