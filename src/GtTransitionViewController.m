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

#import "GtTransitionViewController.h"

#import "GtDocument.h"
#import "GtTransitionTimingView.h"
#import "GtTreeNode.h"
#import "GtWindowController.h"

#import "AppKitExtensions.h"

@implementation GtTransitionViewController
{
  NSMutableArray *_items;
}

+ (NSString *)viewNibName
{
  return @"GtTransitionView";
}

- (NSString *)title
{
  return @"Transitions";
}

- (id)initWithWindowController:(GtWindowController *)windowController
{
  self = [super initWithWindowController:windowController];
  if (self == nil)
    return nil;

  _items = [[NSMutableArray alloc] init];

  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(documentGraphDidChange:)
   name:GtDocumentGraphDidChange object:self.document];
  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(documentNodeDidChange:)
   name:GtDocumentNodeDidChange object:self.document];

  [self.document addObserver:self forKeyPath:@"documentNode" options:0
   context:NULL];
  [self.windowController addObserver:self forKeyPath:@"currentModule"
   options:0 context:NULL];

  [self updateCurrentModule];

  return self;
}

- (void)viewDidLoad
{
  for (NSTableColumn *col in [self.outlineView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];
  for (NSTableColumn *col in [self.fromTableView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];
  for (NSTableColumn *col in [self.toTableView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];

  [self updateDocumentNode];

  [_items removeAllObjects];
  [self.outlineView reloadData];
}

- (void)invalidate
{
  [_currentModule removeObserver:self forKeyPath:@"moduleStates"];
  [_currentModule removeObserver:self forKeyPath:@"moduleState"];
  _currentModule = nil;

  [self.windowController removeObserver:self forKeyPath:@"currentModule"];
  [self.document removeObserver:self forKeyPath:@"documentNode"];

  [self.outlineView setDelegate:nil];
  [self.outlineView setDataSource:nil];

  [self.fromTableView setDelegate:nil];
  [self.fromTableView setDataSource:nil];

  [self.toTableView setDelegate:nil];
  [self.toTableView setDataSource:nil];

  [super invalidate];
}

- (void)updateDocumentNode
{
  [_items removeAllObjects];
  [self.outlineView reloadData];

  [self.outlineView expandItem:nil expandChildren:YES];
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

  [self updateCurrentState];

  [_items removeAllObjects];
  [self.outlineView reloadData];
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

  /* FIXME: not right. */

  _fromState = _toState = state;
  [self.fromTableView setSelectedRow:row];
  [self.toTableView setSelectedRow:row];

  [self.fromTableView reloadData];
  [self.toTableView reloadData];
}

- (void)documentGraphDidChange:(NSNotification *)note
{
  [_items removeAllObjects];
  [self.outlineView reloadData];
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
  else if ([keyPath isEqualToString:@"currentModule"])
    {
      [self updateCurrentModule];
    }
  else if ([keyPath isEqualToString:@"moduleStates"])
    {
      [self.fromTableView reloadData];
      [self.toTableView reloadData];
    }
  else if ([keyPath isEqualToString:@"moduleState"])
    {
      [self updateCurrentState];
    }
}

static BOOL
showNodeStateForState(MgNodeState *st, MgModuleState *from, MgModuleState *to)
{
  MgModuleState *moduleState = st.moduleState;

  return ((from != nil && moduleState == from)
	  || (to != nil && moduleState == to));
}

static BOOL
showNodeForState(GtTreeNode *tn, MgModuleState *from, MgModuleState *to)
{
  for (MgNodeState *st in tn.node.states)
    {
      if (showNodeStateForState(st, from, to))
	return YES;
    }

  /* FIXME: yow! */

  for (GtTreeNode *child in tn.children)
    {
      if (showNodeForState(child, from, to))
	return YES;
    }

  return NO;
}

/** NSOutlineViewDataSource methods. **/

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
  if (_fromState == _toState)
    return 0;

  if (item == nil)
    item = _moduleNode;

  if (![item isKindOfClass:[GtTreeNode class]])
    return 0;

  NSInteger count = 0;

  for (GtTreeNode *tn in ((GtTreeNode *)item).children)
    {
      if (showNodeForState(tn, _fromState, _toState))
	count++;
    }

  for (MgNodeState *st in ((GtTreeNode *)item).node.states)
    {
      if (showNodeStateForState(st, _fromState, _toState))
	{
	  for (NSString *key in [[st class] allProperties])
	    {
	      if ([st definesValueForKey:key])
		count++;
	    }
	}
    }

  return count;
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)idx ofItem:(id)item
{
  if (item == nil)
    item = _moduleNode;

  if (![item isKindOfClass:[GtTreeNode class]])
    return nil;

  for (GtTreeNode *tn in ((GtTreeNode *)item).children)
    {
      if (showNodeForState(tn, _fromState, _toState)
	  && idx-- == 0)
	return tn;
    }

  for (MgNodeState *st in ((GtTreeNode *)item).node.states)
    {
      if (showNodeStateForState(st, _fromState, _toState))
	{
	  for (NSString *key in [[st class] allProperties])
	    {
	      if ([st definesValueForKey:key] && idx-- == 0)
		{
		  NSArray *data = @[item, key];
		  [_items addObject:data];
		  return data;
		}
	    }
	}
    }

  return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
  return item == nil || [item isKindOfClass:[GtTreeNode class]];
}

/** NSOutlineViewDelegate methods. **/

- (NSView *)outlineView:(NSOutlineView *)ov
    viewForTableColumn:(NSTableColumn *)col item:(id)item
{
  NSString *ident = [col identifier];

  if (item == nil)
    item = _moduleNode;

  if ([ident isEqualToString:@"name"])
    {
      NSTextField *label
        = [ov makeViewWithIdentifier:@"name.label" owner:self];

      if (label == nil)
	{
	  label = [[NSTextField alloc] initWithFrame:NSZeroRect];

	  [label setFont:[NSFont systemFontOfSize:
			  [NSFont smallSystemFontSize]]];
	  [[label cell] setVerticallyCentered:YES];
	  [label setEditable:NO];
	  [label setDrawsBackground:NO];
	  [label setBordered:NO];

	  label.identifier = @"name.label";
	}

      if ([item isKindOfClass:[GtTreeNode class]])
	[label setObjectValue:((GtTreeNode *)item).node.name];
      else if ([item isKindOfClass:[NSArray class]])
	[label setObjectValue:item[1]];

      return label;
    }
  else if ([ident isEqualToString:@"timing"])
    {
      GtTransitionTimingView *view
        = [ov makeViewWithIdentifier:@"timing.view" owner:self];

      if (view == nil)
	{
	  view = [[GtTransitionTimingView alloc] initWithFrame:NSZeroRect];
	  view.controller = self;
	  view.identifier = @"timing.view";
	}

      if ([item isKindOfClass:[GtTreeNode class]])
	{
	  view.treeNode = item;
	  view.key = nil;
	}
      else if ([item isKindOfClass:[NSArray class]])
	{
	  view.treeNode = item[0];
	  view.key = item[1];
	}

      return view;
    }

  return nil;
}

/** NSTableViewDataSource methods. **/

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv
{
  return 1 + [_currentModule.moduleStates count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:
    (NSTableColumn *)col row:(NSInteger)row
{
  if (row == 0)
    return @"Any";

  MgModuleState *state = _currentModule.moduleStates[row-1];

  return state.name;
}

/** NSTableViewDelegate methods. **/

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
  NSTableView *tv = [note object];
  NSInteger row = [tv selectedRow];

  if (tv == self.fromTableView)
    {
      if (row == 0)
	_fromState = nil;
      else
	_fromState = _currentModule.moduleStates[row-1];
    }
  else if (tv == self.toTableView)
    {
      if (row == 0)
	_toState = nil;
      else
	_toState = _currentModule.moduleStates[row-1];
    }

  [_items removeAllObjects];
  [self.outlineView reloadData];
}

@end
