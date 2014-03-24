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
#import "GtTreeNode.h"
#import "GtWindowController.h"

#import "AppKitExtensions.h"

static NSString *const GtStateListViewItemType = @"org.unfactored.gt-state-list-view-item";

@implementation GtStateListViewController
{
  GtTreeNode *_moduleNode;
  MgModuleLayer *_currentModule;

  NSArray *_dragItems;			/* NSArray<MgModuleState> */
  NSPasteboard *_dragPasteboard;
  NSDragOperation _dragOperation;
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

  [self.windowController addObserver:self forKeyPath:@"currentModule"
   options:0 context:NULL];

  return self;
}

- (void)viewDidLoad
{
  [self.tableView registerForDraggedTypes:@[GtStateListViewItemType]];

  for (NSTableColumn *col in [self.tableView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];

  [self updateCurrentModule];
}

- (void)invalidate
{
  [_currentModule removeObserver:self forKeyPath:@"moduleStates"];
  [_currentModule removeObserver:self forKeyPath:@"moduleState"];

  [self.windowController removeObserver:self forKeyPath:@"currentModule"];

  _moduleNode = nil;
  _currentModule = nil;

  [super invalidate];
}

- (void)updateCurrentModule
{
  [_currentModule removeObserver:self forKeyPath:@"moduleStates"];
  [_currentModule removeObserver:self forKeyPath:@"moduleState"];

  _moduleNode = self.windowController.currentModule;
  _currentModule = (id)_moduleNode.node;

  [_currentModule addObserver:self forKeyPath:@"moduleStates"
   options:0 context:NULL];
  [_currentModule addObserver:self forKeyPath:@"moduleState"
   options:0 context:NULL];

  [self.tableView reloadData];
  [self updateCurrentState];
}

- (void)updateCurrentState
{
  MgModuleState *state = _currentModule.moduleState;

  NSInteger row = 0;

  if (state != nil)
    {
      row = [_currentModule.moduleStates indexOfObjectIdenticalTo:state];
      if (row == NSNotFound)
	return;
      row = row + 1;
    }

  [self.tableView setSelectedRow:row];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"currentModule"])
    {
      [self updateCurrentModule];
    }
  else if ([keyPath isEqualToString:@"moduleStates"])
    {
      [self.tableView reloadData];
    }
  else if ([keyPath isEqualToString:@"moduleState"])
    {
      [self updateCurrentState];
    }
}

/** NSTableViewDataSource methods. **/

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv
{
  return 1 + [_currentModule.moduleStates count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:
    (NSTableColumn *)col row:(NSInteger)row
{
  NSString *ident = [col identifier];

  if (row == 0)
    {
      if ([ident isEqualToString:@"name"])
	return @"Base State";
      else
	return nil;
    }

  id value = [_currentModule.moduleStates[row-1] valueForKey:ident];

  if ([ident isEqualToString:@"superstate"])
    value = [(MgModuleState *)value name];

  return value;
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)value
    forTableColumn:(NSTableColumn *)col row:(NSInteger)row
{
  if (row == 0)
    return;

  NSString *ident = [col identifier];

  if ([ident isEqualToString:@"superstate"])
    value = [_currentModule moduleStateWithName:value];

  [self.document module:_currentModule
   state:_currentModule.moduleStates[row-1] setValue:value forKey:ident];
}

/** NSTableViewDelegate methods. **/

- (BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:
    (NSTableColumn *)col row:(NSInteger)row
{
  return row > 0;
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
  NSInteger row = [self.tableView selectedRow];

  MgModuleState *state = nil;
  if (row > 0)
    state = _currentModule.moduleStates[row-1];

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
	[items addObject:_currentModule.moduleStates[idx-1]];
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
