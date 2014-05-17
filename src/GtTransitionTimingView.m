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

#import "GtTransitionTimingView.h"

#import "GtColor.h"
#import "GtTransitionViewController.h"

@interface MgFunction (GtTransitionTimingView)
- (void)drawInRect:(NSRect)r;
@end

@implementation GtTransitionTimingView
{
  NSBackgroundStyle _backgroundStyle;
}

- (NSBackgroundStyle)backgroundStyle
{
  return _backgroundStyle;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)style
{
  _backgroundStyle = style;
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)r
{
  GtTransitionViewController *controller = self.controller;

  MgNodeTransition *trans
    = [controller nodeTransition:self.treeNode onlyIfExists:YES];
  MgTransitionTiming *timing = [trans timingForKey:self.key];

  BOOL using_default = timing == nil;

  if (using_default)
    timing = controller.defaultTiming;

  double begin = timing.begin;
  double duration = timing.duration;
  MgFunction *function = timing.function;

  double start = controller.timelineStart;
  double scale = controller.timelineScale;

  NSRect bounds = self.bounds;

  NSRect timingR;
  timingR.origin.x = bounds.origin.x + round((begin - start) * scale);
  timingR.origin.y = bounds.origin.y + 1;
  timingR.size.width = round(duration * scale);
  timingR.size.height = bounds.size.height - 1;

  if (!using_default)
    {
      [[GtColor timelineItemFillColor] setFill];
      [NSBezierPath fillRect:timingR];
    }

  if (!using_default || _backgroundStyle != NSBackgroundStyleDark)
    [[GtColor timelineItemStrokeColor] setStroke];
  else
    [[NSColor whiteColor] setStroke];

  [function drawInRect:NSInsetRect(timingR, 2.5, 2.5)];
  [NSBezierPath strokeRect:NSInsetRect(timingR, .5, .5)];
}

@end

@implementation MgFunction (GtTransitionTimingView)

- (void)drawInRect:(NSRect)r
{
  NSBezierPath *path = [NSBezierPath bezierPath];

  [path moveToPoint:r.origin];

  /* FIXME: could use fewer path segments by calculating path control
     points to make a cubic interpolation of the points, but this is
     easy and good enough for now.. */

  double interval = 5 / r.size.width;

  for (double t = 0; t < 1; t += interval)
    {
      double ts = [self evaluateScalar:t];

      CGPoint p1 = CGPointMake(t, ts);
      NSPoint c1 = NSMakePoint(r.origin.x + p1.x * r.size.width,
			       r.origin.y + p1.y * r.size.height);

      [path lineToPoint:c1];
    }

  [path stroke];
}

@end

@implementation MgBezierTimingFunction (GtTransitionTimingView)

- (void)drawInRect:(NSRect)r
{
  CGPoint p0 = self.p0;
  CGPoint p1 = self.p1;

  NSPoint c0 = r.origin;
  NSPoint c1 = NSMakePoint(r.origin.x + p0.x * r.size.width,
			   r.origin.y + p0.y * r.size.height);
  NSPoint c2 = NSMakePoint(r.origin.x + p1.x * r.size.width,
			   r.origin.y + p1.y * r.size.height);
  NSPoint c3 = NSMakePoint(c0.x + r.size.width, c0.y + r.size.height);

  NSBezierPath *path = [NSBezierPath bezierPath];

  [path moveToPoint:c0];
  [path curveToPoint:c3 controlPoint1:c1 controlPoint2:c2];

  [path stroke];
}

@end
