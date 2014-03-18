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

#import "GtTreeView.h"

#import "GtAppDelegate.h"

#import "AppKitExtensions.h"

@implementation GtTreeView

/* The standard NSOutlineView context menu doesn't give us an easy way
   to switch the "clickedRow" into our selection state, so just override
   it with our own menu logic. */

- (void)mouseDown:(NSEvent *)e
{
  if (([e modifierFlags] & NSControlKeyMask) != 0)
    [self showContextMenuWithEvent:e];
  else
    [super mouseDown:e];
}

- (void)rightMouseDown:(NSEvent *)e
{
  [self showContextMenuWithEvent:e];
}

- (void)showContextMenuWithEvent:(NSEvent *)e
{
  NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];

  NSInteger row = [self rowAtPoint:p];

  if (row >= 0 && ![[self selectedRowIndexes] containsIndex:row])
    [self setSelectedRow:row];

  [(GtAppDelegate *)[NSApp delegate]
   showObjectContextMenuWithEvent:e forView:self];
}

@end
