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

#import "GtTreeViewController.h"

#import "GtDocument.h"
#import "GtTreeNode.h"
#import "GtWindowController.h"

#import "AppKitExtensions.h"

static NSString *const GtTreeViewItemType = @"org.unfactored.gt-tree-view-item";

@implementation GtTreeViewController
{
  NSArray *_dragItems;			/* NSArray<GtTreeNode> */
  NSPasteboard *_dragPasteboard;
  NSDragOperation _dragOperation;
}

+ (NSString *)viewNibName
{
  return @"GtTreeView";
}

- (NSString *)title
{
  return @"Objects";
}

- (id)initWithWindowController:(GtWindowController *)windowController
{
  self = [super initWithWindowController:windowController];
  if (self == nil)
    return nil;

  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(documentGraphDidChange:)
   name:GtDocumentGraphDidChange object:self.document];
  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(documentNodeDidChange:)
   name:GtDocumentNodeDidChange object:self.document];

  [self.document addObserver:self forKeyPath:@"documentNode" options:0
   context:NULL];

  [self.windowController addObserver:self forKeyPath:@"selection" options:0
   context:NULL];

  return self;
}

- (void)viewDidLoad
{
  [self.outlineView registerForDraggedTypes:
   @[GtTreeViewItemType, MgNodeType, MgArchiveType,
     (id)kUTTypeFileURL, (id)kUTTypeImage]];

  for (NSTableColumn *col in [self.outlineView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];

  [self updateDocumentNode];
  [self updateSelection];

  [self.outlineView reloadData];
  [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)invalidate
{
  [self.document removeObserver:self forKeyPath:@"documentNode"];
  [self.windowController removeObserver:self forKeyPath:@"selection"];

  [super invalidate];
}

- (void)updateDocumentNode
{
  [self.outlineView reloadData];
  [self.outlineView expandItem:nil expandChildren:YES];
}

static void
expandItem(NSOutlineView *ov, GtTreeNode *tn)
{
  if (tn != nil)
    {
      expandItem(ov, tn.parent);
      [ov expandItem:tn];
    }
}

- (void)updateSelection
{
  NSArray *selection = self.windowController.selection;

  for (GtTreeNode *tn in selection)
    expandItem(self.outlineView, tn.parent);

  [self.outlineView setSelectedItems:selection];
}

- (void)documentGraphDidChange:(NSNotification *)note
{
  [self.outlineView reloadData];
  [self.outlineView setSelectedItems:self.windowController.selection];
}

- (void)documentNodeDidChange:(NSNotification *)note
{
  NSDictionary *info = [note userInfo];

  [self.outlineView reloadItem:info[@"treeItem"]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"documentNode"])
    {
      [self updateDocumentNode];
    }
  else if ([keyPath isEqualToString:@"selection"])
    {
      [self updateSelection];
    }
}

/** NSOutlineViewDataSource methods. **/

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
  if (item == nil)
    item = self.windowController.tree;

  return [((GtTreeNode *)item).children count];
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)idx ofItem:(id)item
{
  if (item == nil)
    item = self.windowController.tree;

  return ((GtTreeNode *)item).children[idx];
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
  return !((GtTreeNode *)item).leaf;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:
    (NSTableColumn *)col byItem:(id)item
{
  NSString *ident = [col identifier];

  return [((GtTreeNode *)item).node valueForKey:ident];
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object
    forTableColumn:(NSTableColumn *)col byItem:(id)item
{
  NSString *ident = [col identifier];

  [self.document node:item setValue:object forKey:ident];
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items
    toPasteboard:(NSPasteboard *)pboard
{
  [pboard declareTypes:@[GtTreeViewItemType] owner:self];

  _dragItems = [items copy];
  _dragPasteboard = pboard;

  return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov
    validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item
    proposedChildIndex:(NSInteger)idx
{
  NSPasteboard *pboard = [info draggingPasteboard];
  NSDragOperation op = NSDragOperationNone;

  GtTreeNode *parent = item != nil ? item : self.windowController.tree;

  while (parent != nil && ![parent.node isKindOfClass:[MgGroupLayer class]])
    {
      if ([parent.parentKey isEqualToString:@"sublayers"])
	idx = parent.parentIndex;
      else
	idx = NSNotFound;

      parent = parent.parent;
    }

  if (![parent.node isKindOfClass:[MgGroupLayer class]])
    return NSDragOperationNone;

  if (idx < 0 || idx == NSNotFound)
    idx = [parent.children count];

  /* FIXME: support dropping images into libraries as well. */

  NSString *type = [pboard availableTypeFromArray:[ov registeredDraggedTypes]];

  if ([type isEqualToString:GtTreeViewItemType])
    {
      if (_dragItems == nil)
	op = NSDragOperationNone;
      else
	op = NSDragOperationMove;
    }
  else
    {
      op = NSDragOperationCopy;
    }

  if (op != NSDragOperationNone)
    {
      if (parent == self.windowController.tree)
	parent = nil;
      [ov setDropItem:parent dropChildIndex:idx];
    }

  _dragOperation = op;
  return op;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id<NSDraggingInfo>)info
    item:(id)item childIndex:(NSInteger)idx
{
  NSPasteboard *pboard = [info draggingPasteboard];
  GtDocument *document = self.document;

  GtTreeNode *parent = item != nil ? item : self.windowController.tree;

  NSString *type = [pboard availableTypeFromArray:@[GtTreeViewItemType]];

  if (idx < 0 || idx == NSNotFound)
    idx = [parent.children count];

  if ([type isEqualToString:GtTreeViewItemType])
    {
      if (_dragItems == nil)
	return NO;

      for (GtTreeNode *tn in _dragItems)
	{
	  [document removeTreeNodeFromParent:tn];

	  NSString *key = nil;
	  if ([tn.node isKindOfClass:[MgLayer class]])
	    key = @"sublayers";
	  else
	    continue;

	  [document node:parent insertObject:tn.node atIndex:idx forKey:key];
	}

      return YES;
    }
  else
    {
      CGPoint p = document.documentCenter;

      if ([parent.node isKindOfClass:[MgLayer class]])
	{
	  CGRect r = ((MgLayer *)parent.node).bounds;
	  p = CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r));
	}

      return [document addObjectsFromPasteboard:pboard asImages:NO
	      atDocumentPoint:p intoNode:parent atIndex:idx];
    }
}

/** NSOutlineViewDelegate methods. **/

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
  self.windowController.selection = [self.outlineView selectedItems];
}

/** NSPasteboardOwner methods. **/

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
}

- (void)pasteboardChangedOwner:(NSPasteboard *)sender
{
  if (_dragPasteboard == sender)
    {
      _dragItems = nil;
      _dragPasteboard = nil;
      _dragOperation = NSDragOperationNone;
    }
}

@end
