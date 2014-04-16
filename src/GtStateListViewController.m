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

#import "GtStateListViewController.h"

#import "GtDocument.h"
#import "GtStateListItemView.h"
#import "GtTreeNode.h"
#import "GtWindowController.h"

#import "AppKitExtensions.h"

static NSString *const GtStateListViewItemType = @"org.unfactored.gt-state-list-view-item";

@implementation GtStateListViewController
{
  GtTreeNode *_moduleNode;
  MgModuleLayer *_moduleLayer;

  NSArray *_dragItems;			/* NSArray<MgModuleState> */
  NSPasteboard *_dragPasteboard;
  NSDragOperation _dragOperation;

  NSInteger _ignoreSelection;
}

+ (NSString *)viewNibName
{
  return @"GtStateListView";
}

- (NSString *)title
{
  return @"States";
}

- (id)initWithWindowController:(GtWindowController *)windowController
{
  self = [super initWithWindowController:windowController];
  if (self == nil)
    return nil;

  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(documentNodeDidChange:)
   name:GtDocumentNodeDidChange object:self.document];

  [self.document addObserver:self forKeyPath:@"documentNode"
   options:0 context:NULL];

  [self.windowController addObserver:self forKeyPath:@"currentModule"
   options:0 context:NULL];

  return self;
}

- (void)viewDidLoad
{
  [_tableView registerForDraggedTypes:@[GtStateListViewItemType]];

  for (NSTableColumn *col in [_tableView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];

  [_rowHeightSlider setDoubleValue:self.rowHeight];

  [self updateCurrentModule];
}

- (void)invalidate
{
  [_moduleLayer removeObserver:self forKeyPath:@"moduleStates"];
  [_moduleLayer removeObserver:self forKeyPath:@"moduleState"];

  [self.document removeObserver:self forKeyPath:@"documentNode"];

  [self.windowController removeObserver:self forKeyPath:@"currentModule"];

  [_tableView setDelegate:nil];
  [_tableView setDataSource:nil];

  _moduleNode = nil;
  _moduleLayer = nil;

  [super invalidate];
}

- (void)updateCurrentModule
{
  [_moduleLayer removeObserver:self forKeyPath:@"moduleStates"];
  [_moduleLayer removeObserver:self forKeyPath:@"moduleState"];

  _moduleNode = self.windowController.currentModule;
  _moduleLayer = (id)_moduleNode.node;

  [_moduleLayer addObserver:self forKeyPath:@"moduleStates"
   options:0 context:NULL];
  [_moduleLayer addObserver:self forKeyPath:@"moduleState"
   options:0 context:NULL];

  _ignoreSelection++;
  [_tableView reloadData];
  _ignoreSelection--;

  [self updateCurrentState];
}

- (void)updateCurrentState
{
  MgModuleState *state = _moduleLayer.moduleState;

  NSInteger row = 0;

  if (state != nil)
    {
      row = [_moduleLayer.moduleStates indexOfObjectIdenticalTo:state];
      if (row == NSNotFound)
	return;
      row = row + 1;
    }

  [_tableView setSelectedRow:row];
}

- (void)state:(MgModuleState *)state setValue:(id)value forKey:(NSString *)key
{
  if ([key isEqualToString:@"superstate.name"])
    {
      value = [_moduleLayer moduleStateWithName:value];
      key = @"superstate";
    }

  [self.document module:_moduleLayer state:state setValue:value forKey:key];
}

- (void)documentNodeDidChange:(NSNotification *)note
{
  NSDictionary *info = [note userInfo];

  GtTreeNode *tn = info[@"treeNode"];
  MgModuleState *state = tn.node.state.moduleState;

  [_tableView enumerateAvailableRowViewsUsingBlock:^
    (NSTableRowView *rowView, NSInteger row)
    {
      MgModuleState *row_state = (row == 0 ? nil
				  : _moduleLayer.moduleStates[row-1]);

      if (state == row_state || [row_state isDescendantOf:state])
	{
	  GtStateListItemView *view = [rowView viewAtColumn:0];
	  [view invalidateThumbnail];
	}
    }];
}

- (void)invalidateThumbnails
{
  [_tableView enumerateAvailableRowViewsUsingBlock:^
    (NSTableRowView *rowView, NSInteger row)
    {
      GtStateListItemView *view
	= [_tableView viewAtColumn:0 row:row makeIfNecessary:NO];

      if (view != nil)
	[view invalidateThumbnail];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"documentNode"])
    {
      [self updateCurrentModule];
      [self invalidateThumbnails];
    }
  else if ([keyPath isEqualToString:@"currentModule"])
    {
      [self updateCurrentModule];
    }
  else if ([keyPath isEqualToString:@"moduleStates"])
    {
      [_tableView reloadData];
    }
  else if ([keyPath isEqualToString:@"moduleState"])
    {
      [self updateCurrentState];
    }
}

- (CGFloat)rowHeight
{
  return [_tableView rowHeight];
}

- (void)setRowHeight:(CGFloat)h
{
  [_tableView setRowHeight:h];
  [_rowHeightSlider setDoubleValue:h];
  [self invalidateThumbnails];
}

- (IBAction)controlAction:(id)sender
{
  if (sender == _rowHeightSlider)
    {
      self.rowHeight = [sender doubleValue];
    }
}

- (void)addSavedViewState:(NSMutableDictionary *)dict
{
  NSString *ident = [self identifier];
  if (ident == nil)
    return;

  dict[ident] = @{
    @"rowHeight" : @(self.rowHeight),
  };

  [super addSavedViewState:dict];
}

- (void)applySavedViewState:(NSDictionary *)dict
{
  NSString *ident = [self identifier];
  if (ident == nil)
    return;

  NSDictionary *state = dict[ident];
  if (state != nil)
    {
      CGFloat row_height = [state[@"rowHeight"] doubleValue];
      if (row_height > 0)
	self.rowHeight = row_height;
    }

  [super applySavedViewState:dict];
}

/** NSTableViewDataSource methods. **/

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv
{
  return 1 + [_moduleLayer.moduleStates count];
}

/** NSTableViewDelegate methods. **/

- (NSView *)tableView:(NSTableView *)tv
    viewForTableColumn:(NSTableColumn *)col row:(NSInteger)row
{
  GtStateListItemView *view
    = [tv makeViewWithIdentifier:[col identifier] owner:self];

  if (row == 0)
    view.state = nil;
  else
    view.state = _moduleLayer.moduleStates[row-1];

  return view;
}

- (BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:
    (NSTableColumn *)col row:(NSInteger)row
{
  return row > 0;
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
  if (_ignoreSelection > 0)
    return;

  NSInteger row = [_tableView selectedRow];

  MgModuleState *state = nil;
  if (row > 0)
    state = _moduleLayer.moduleStates[row-1];

  [self.document node:_moduleNode setValue:state forKey:@"moduleState"];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)indexes
    toPasteboard:(NSPasteboard *)pboard
{
  NSMutableArray *items = [NSMutableArray array];

  for (NSInteger idx = [indexes firstIndex]; idx != NSNotFound;
       idx = [indexes indexGreaterThanIndex:idx])
    {
      if (idx > 0)
	[items addObject:_moduleLayer.moduleStates[idx-1]];
    }

  [pboard declareTypes:@[GtStateListViewItemType] owner:self];

  _dragItems = [items copy];
  _dragPasteboard = pboard;

  return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv
    validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row
    proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
  /* FIXME: implement this. */

#if 0
  NSPasteboard *pboard = [info draggingPasteboard];
#endif

  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info
    row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
  /* FIXME: implement this. */

#if 0
  NSPasteboard *pboard = [info draggingPasteboard];
#endif

  return NO;
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
