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

#import "GtDocument.h"
#import "GtInspectorControl.h"
#import "GtInspectorItem.h"
#import "GtTreeNode.h"
#import "GtWindowController.h"

#define LABEL_HEIGHT 22

#import "AppKitExtensions.h"

@implementation GtInspectorViewController
{
  NSArray *_selection;			/* NSArray<GtTreeNode> */
  Class _inspectorClass;
  GtInspectorItem *_inspectorTree;
  NSInteger _valueColumnIndex;
}

+ (NSString *)viewNibName
{
  return @"GtInspectorView";
}

- (NSString *)title
{
  return @"Inspector";
}

- (void)viewDidLoad
{
  [self.windowController addObserver:self forKeyPath:@"selection" options:0
   context:NULL];

  NSInteger colIndex = 0;
  for (NSTableColumn *col in [self.outlineView tableColumns])
    {
      if ([[col identifier] isEqualToString:@"value"])
	_valueColumnIndex = colIndex;
      [[col dataCell] setVerticallyCentered:YES];
      colIndex++;
    }

  [self.outlineView setSelectionHighlightStyle:
   NSTableViewSelectionHighlightStyleNone];

  [self updateSelection];

  [self.outlineView expandItem:nil expandChildren:NO];
}

- (void)invalidate
{
  [self.windowController removeObserver:self forKeyPath:@"selection"];

  for (GtTreeNode *tn in _selection)
    [tn.node removeObserver:self forKeyPath:@"version"];

  _selection = nil;

  [super invalidate];
}

static size_t
class_depth(Class c)
{
  size_t depth = 0;
  while (c != Nil)
    {
      c = [c superclass];
      depth++;
    }
  return depth;
}

static Class
common_superclass(Class c1, Class c2)
{
  if (c1 == Nil)
    return c2;
  if (c2 == Nil)
    return c1;
  if (c1 == c2)
    return c1;

  size_t c1_depth = class_depth(c1);
  size_t c2_depth = class_depth(c2);

  while (c1_depth > c2_depth)
    c1 = [c1 superclass], c1_depth--;
  while (c2_depth > c1_depth)
    c2 = [c2 superclass], c2_depth--;

  while (c1 != c2)
    {
      c1 = [c1 superclass];
      c2 = [c2 superclass];
    }

  return c1;
}

- (void)updateSelection
{
  NSArray *selection = self.windowController.selection;

  if ([_selection isEqual:selection])
    return;

  for (GtTreeNode *tn in _selection)
    [tn.node removeObserver:self forKeyPath:@"version"];

  _selection = [selection copy];

  for (GtTreeNode *tn in _selection)
    [tn.node addObserver:self forKeyPath:@"version" options:0 context:NULL];

  Class cls = Nil;

  for (GtTreeNode *tn in _selection)
    {
      Class tn_class = [tn.node class];

      if (cls == Nil)
	cls = tn_class;
      else
	cls = common_superclass(cls, tn_class);
    }

  if (![cls isSubclassOfClass:[MgNode class]])
    cls = Nil;

  _inspectorClass = cls;
  _inspectorTree = [GtInspectorItem inspectorTreeForClass:cls];

  [self.outlineView reloadData];

  for (GtInspectorItem *subitem in _inspectorTree.subitems)
    [self.outlineView expandItem:subitem];
}

- (void)updateValues
{
  NSOutlineView *view = self.outlineView;

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

- (id)inspectedValueForKey:(NSString *)key
{
  NSInteger count = [_selection count];

  if (count == 0)
    return nil;

  id value = [((GtTreeNode *)_selection[0]).node valueForKey:key];

  if (count > 1)
    {
      for (NSInteger i = 1; i < count; i++)
	{
	  id value_i = [((GtTreeNode *)_selection[i]).node valueForKey:key];

	  if (value != value_i && ![value isEqual:value_i])
	    return nil;
	}
    }

  return value;
}

- (void)setInspectedValue:(id)value forKey:(NSString *)key
{
  GtDocument *document = self.document;

  for (GtTreeNode *tn in _selection)
    {
      [document node:tn setValue:value forKey:key];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"selection"])
    {
      [self updateSelection];
    }
  else if ([keyPath isEqualToString:@"version"])
    {
      [self updateValues];
    }
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
      return [GtInspectorControl controlForItem:item controller:self];
    }
}

@end
