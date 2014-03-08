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

#import "YuBase.h"

typedef NS_ENUM(NSInteger, YuViewerAdornment)
{
  YuViewerAdornmentCornerRadius,
  YuViewerAdornmentResizeTopLeft,
  YuViewerAdornmentResizeTop,
  YuViewerAdornmentResizeTopRight,
  YuViewerAdornmentResizeBottomLeft,
  YuViewerAdornmentResizeBottom,
  YuViewerAdornmentResizeBottomRight,
  YuViewerAdornmentResizeLeft,
  YuViewerAdornmentResizeRight,
  YuViewerAdornmentAnchor,
  YuViewerAdornmentRotate,
  YuViewerAdornmentScale,
  YuViewerAdornmentSqueeze,
  YuViewerAdornmentSkew,
};

enum
{
  YuViewerAdornmentCount = YuViewerAdornmentSkew + 1,
};

typedef NS_OPTIONS(NSUInteger, YuViewerAdornmentMask)
{
  YuViewerAdornmentMaskCornerRadius = 1U << YuViewerAdornmentCornerRadius,
  YuViewerAdornmentMaskResizeTopLeft = 1U << YuViewerAdornmentResizeTopLeft,
  YuViewerAdornmentMaskResizeTop = 1U << YuViewerAdornmentResizeTop,
  YuViewerAdornmentMaskResizeTopRight = 1U << YuViewerAdornmentResizeTopRight,
  YuViewerAdornmentMaskResizeBottomLeft = 1U << YuViewerAdornmentResizeBottomLeft,
  YuViewerAdornmentMaskResizeBottom = 1U << YuViewerAdornmentResizeBottom,
  YuViewerAdornmentMaskResizeBottomRight = 1U << YuViewerAdornmentResizeBottomRight,
  YuViewerAdornmentMaskResizeLeft = 1U << YuViewerAdornmentResizeLeft,
  YuViewerAdornmentMaskResizeRight = 1U << YuViewerAdornmentResizeRight,
  YuViewerAdornmentMaskAnchor = 1U << YuViewerAdornmentAnchor,
  YuViewerAdornmentMaskRotate = 1U << YuViewerAdornmentRotate,
  YuViewerAdornmentMaskScale = 1U << YuViewerAdornmentScale,
  YuViewerAdornmentMaskSqueeze = 1U << YuViewerAdornmentSqueeze,
  YuViewerAdornmentMaskSkew = 1U << YuViewerAdornmentSkew,
};

@interface YuViewerOverlayNode : MgDrawingNode

@property(nonatomic, weak) YuViewerView *view;

@property(nonatomic, assign) YuViewerAdornmentMask adornmentMask;

- (void)update;

- (NSInteger)hitTest:(CGPoint)p inAdornmentsOfNode:(YuTreeNode *)node;

@end
