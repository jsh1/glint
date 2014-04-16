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

#import "GtInspectorViewController.h"

#import "GtInspectorControl.h"
#import "GtInspectorItem.h"

#define LABEL_HEIGHT 22

#import "AppKitExtensions.h"

@implementation GtInspectorViewController
{
  GtInspectorItem *_inspectorTree;
  NSInteger _valueColumnIndex;
}

+ (NSString *)viewNibName
{
  return @"GtInspectorView";
}

- (void)viewDidLoad
{
  NSInteger colIndex = 0;
  for (NSTableColumn *col in [_outlineView tableColumns])
    {
      if ([[col identifier] isEqualToString:@"value"])
	_valueColumnIndex = colIndex;
      [[col dataCell] setVerticallyCentered:YES];
      colIndex++;
    }

  [_outlineView setSelectionHighlightStyle:
   NSTableViewSelectionHighlightStyleNone];
}

- (void)invalidate
{
  [_outlineView setDelegate:nil];
  [_outlineView setDataSource:nil];

  [super invalidate];
}

- (GtInspectorItem *)inspectorTree
{
  return _inspectorTree;
}

- (void)setInspectorTree:(GtInspectorItem *)item
{
  if (_inspectorTree != item)
    {
      _inspectorTree = item;

      [self reloadData];
      [self expandToplevelItems];
    }
  else
    [self reloadValues];
}

- (void)reloadData
{
  [_outlineView reloadData];
}

- (void)reloadValues
{
  NSOutlineView *view = _outlineView;

  NSInteger count = [view numberOfRows];

  for (NSInteger i = 0; i < count; i++)
    {
      GtInspectorControl *control = [view viewAtColumn:_valueColumnIndex
				     row:i makeIfNecessary:NO];
      if (control != nil)
	{
	  assert(control.item == [view itemAtRow:i]);
	  control.objectValue = [self inspectedValueForKey:control.item.key];
	}
    }
}

- (void)expandToplevelItems
{
  [_outlineView expandItem:_inspectorTree];

  for (GtInspectorItem *subitem in _inspectorTree.subitems)
    [_outlineView expandItem:subitem];
}

/** GtInspectorDelegate methods. **/

- (id)inspectedValueForKey:(NSString *)key
{
  return nil;
}

- (void)setInspectedValue:(id)value forKey:(NSString *)key
{
}

/** NSOutlineViewDataSource methods. **/

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item_
{
  GtInspectorItem *item = item_;

  if (item == nil)
    item = _inspectorTree;

  return [item.subitems count];
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)idx ofItem:(id)item_
{
  GtInspectorItem *item = item_;

  if (item == nil)
    item = _inspectorTree;

  return item.subitems[idx];
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item_
{
  GtInspectorItem *item = item_;

  return [item.subitems count] != 0;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:
    (NSTableColumn *)col byItem:(id)item_
{
  GtInspectorItem *item = item_;
  NSString *ident = [col identifier];

  if ([ident isEqualToString:@"key"])
    {
      return item.displayName;
    }
  else if ([ident isEqualToString:@"value"])
    {
      if (item.key != nil)
	return [self inspectedValueForKey:item.key];
    }

  return nil;
}

/** NSOutlineViewDelegate methods. **/

- (CGFloat)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item_
{
  GtInspectorItem *item = item_;

  CGFloat control_height = [GtInspectorControl controlHeightForItem:item];

  return MAX(control_height, LABEL_HEIGHT);
}

- (NSView *)outlineView:(NSOutlineView *)ov
    viewForTableColumn:(NSTableColumn *)col item:(id)item_
{
  GtInspectorItem *item = item_;

  if ([[col identifier] isEqualToString:@"key"])
    {
      NSString *ident = @"key.textField";

      NSTextField *label = [ov makeViewWithIdentifier:ident owner:self];

      if (label == nil)
	{
	  label = [[NSTextField alloc] initWithFrame:NSZeroRect];

	  [label setFont:[NSFont systemFontOfSize:
			  [NSFont smallSystemFontSize]]];
	  [[label cell] setVerticallyCentered:YES];
	  [label setEditable:NO];
	  [label setDrawsBackground:NO];
	  [label setBordered:NO];

	  label.identifier = @"key.textField";
	}

      return label;
    }
  else
    {
      return [GtInspectorControl controlForItem:item delegate:self];
    }
}

@end
