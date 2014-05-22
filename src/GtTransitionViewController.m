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

#define DRAG_THRESH 2

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

  _timelineStart = 0;
  _timelineScale = 400;

  _items = [[NSMutableArray alloc] init];

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
  for (NSTableColumn *col in [_tableView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];
  for (NSTableColumn *col in [_outlineView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];

  [self updateDocumentNode];

  [_items removeAllObjects];
  [_outlineView reloadData];
  [_outlineView expandItem:nil expandChildren:YES];
}

- (void)invalidate
{
  [_currentModule removeObserver:self forKeyPath:@"moduleStates"];
  [_currentModule removeObserver:self forKeyPath:@"moduleState"];
  _currentModule = nil;

  [self.windowController removeObserver:self forKeyPath:@"currentModule"];
  [self.document removeObserver:self forKeyPath:@"documentNode"];

  [_tableView setDelegate:nil];
  [_tableView setDataSource:nil];

  [_outlineView setDelegate:nil];
  [_outlineView setDataSource:nil];

  [super invalidate];
}

- (MgTransitionTiming *)defaultTiming
{
  static MgTransitionTiming *timing;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      /* Matches MgNode.m. But should be defined by document. */

      timing = [[MgTransitionTiming alloc] init];
      timing.duration = 1;
      timing.function = [[MgSpringFunction alloc] init];
    });

  return timing;
}

- (void)updateDocumentNode
{
  [_items removeAllObjects];
  [_outlineView reloadData];
  [_outlineView expandItem:nil expandChildren:YES];
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
  [_outlineView reloadData];
  [_outlineView expandItem:nil expandChildren:YES];
}

- (void)updateCurrentState
{
#if 0
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
  [_tableView setSelectedRow:row];
#endif

  [_tableView reloadData];
}

- (void)documentNodeDidChange:(NSNotification *)note
{
  NSDictionary *info = [note userInfo];

  if ([info[@"graphChanged"] boolValue])
    {
      [_items removeAllObjects];
      [_outlineView reloadData];
      [_outlineView expandItem:nil expandChildren:YES];
    }
  else
    [_outlineView reloadItem:info[@"treeItem"] reloadChildren:YES];
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
      [_tableView reloadData];
    }
  else if ([keyPath isEqualToString:@"moduleState"])
    {
      [self updateCurrentState];
    }
}

- (MgNodeTransition *)nodeTransition:(GtTreeNode *)tn
{
  return [self nodeTransition:tn onlyIfExists:NO];
}

- (MgNodeTransition *)nodeTransition:(GtTreeNode *)tn onlyIfExists:(BOOL)flag
{
  for (MgNodeTransition *trans in tn.node.transitions)
    {
      if (trans.from == _fromState && trans.to == _toState)
	return trans;
    }

  if (flag)
    return nil;

  MgNodeTransition *trans = [MgNodeTransition transition];

  trans.from = _fromState;
  trans.to = _toState;

  [self.document node:tn insertObject:trans
   atIndex:NSIntegerMax forKey:@"transitions"];

  return trans;
}

- (BOOL)mouseDown:(NSEvent *)e inTimingView:(GtTransitionTimingView *)view
    dragMode:(GtTransitionViewControllerDragMode)mode
{
  BOOL dragging = NO;

  NSPoint p0 = [view convertPoint:[e locationInWindow] fromView:nil];

  NSInteger col = [_outlineView columnWithIdentifier:@"timing"];

  NSIndexSet *sel = [_outlineView selectedRowIndexes];

  NSMapTable *item_map = [NSMapTable strongToStrongObjectsMapTable];

  for (NSInteger idx = [sel firstIndex]; idx != NSNotFound;
       idx = [sel indexGreaterThanIndex:idx])
    {
      NSArray *item = [_outlineView itemAtRow:idx];
      if (![item isKindOfClass:[NSArray class]])
	continue;

      GtTreeNode *tn = item[0];
      NSString *key = item[1];

      MgNodeTransition *trans = [self nodeTransition:tn onlyIfExists:NO];

      MgTransitionTiming *timing = [trans timingForKey:key];
      if (timing == nil)
	timing = self.defaultTiming;

      [item_map setObject:timing forKey:item];
    }

  while (1)
    {
      [CATransaction flush];

      e = [[view window] nextEventMatchingMask:NSAnyEventMask];
      if ([e type] != NSLeftMouseDragged)
	break;

      NSPoint p1 = [view convertPoint:[e locationInWindow] fromView:nil];

      CGFloat dx = round(p1.x - p0.x);

      if (!dragging && fabs(dx) > DRAG_THRESH)
	dragging = YES;

      if (!dragging)
	continue;

      for (NSArray *item in item_map)
	{
	  GtTreeNode *tn = item[0];
	  NSString *key = item[1];

	  MgNodeTransition *trans = [self nodeTransition:tn onlyIfExists:NO];

	  MgTransitionTiming *timing = [item_map objectForKey:item];

	  double begin = timing.begin;
	  double dur = timing.duration;

	  double scale_r = 1 / _timelineScale;

	  switch (mode)
	    {
	    case GtTransitionViewControllerDragNone:
	      break;

	    case GtTransitionViewControllerDragStart:
	      begin += dx * scale_r;
	      dur -= dx * scale_r;
	      break;

	    case GtTransitionViewControllerDragEnd:
	      dur += dx * scale_r;
	      break;
	      
	    case GtTransitionViewControllerDragInside:
	      begin += dx * scale_r;
	      break;
	    }

	  if (begin != timing.begin || dur != timing.duration)
	    {
	      timing = [timing copy];
	      timing.begin = begin;
	      timing.duration = dur;
	    }

	  [self.document node:tn transition:trans
	   setTiming:timing forKey:key];
	}

      /* FIXME: this shouldn't be necessary..? */

      [_outlineView enumerateAvailableRowViewsUsingBlock:^
       (NSTableRowView *rowView, NSInteger row)
         {
	   if ([sel containsIndex:row])
	     {
	       [[rowView viewAtColumn:col] setNeedsDisplay:YES];
	     }
	 }];
    }

  return dragging;
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
  if ([tn.node isKindOfClass:[MgModuleLayer class]])
    return NO;

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

  /* FIXME: cache this set somewhere? */

  NSMutableSet *set = [[NSMutableSet alloc] init];

  for (MgNodeState *st in ((GtTreeNode *)item).node.states)
    {
      if (showNodeStateForState(st, _fromState, _toState))
	{
	  for (NSString *key in [[st class] allProperties])
	    {
	      if ([st definesValueForKey:key])
		[set addObject:key];
	    }
	}
    }

  count += [set count];

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

  NSMutableSet *set = [[NSMutableSet alloc] init];

  for (MgNodeState *st in ((GtTreeNode *)item).node.states)
    {
      if (showNodeStateForState(st, _fromState, _toState))
	{
	  for (NSString *key in [[st class] allProperties])
	    {
	      if ([st definesValueForKey:key])
		[set addObject:key];
	    }
	}
    }

  for (NSString *key in [[set allObjects] sortedArrayUsingSelector:
			 @selector(caseInsensitiveCompare:)])
    {
      if (idx-- == 0)
	{
	  NSArray *data = @[item, key];
	  [_items addObject:data];
	  return data;
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
        = [ov makeViewWithIdentifier:ident owner:self];

      [[label cell] setVerticallyCentered:YES];

      if ([item isKindOfClass:[GtTreeNode class]])
	[label setObjectValue:((GtTreeNode *)item).node.name];
      else if ([item isKindOfClass:[NSArray class]])
	[label setObjectValue:item[1]];

      return label;
    }
  else if ([ident isEqualToString:@"timing"]
	   && [item isKindOfClass:[NSArray class]])
    {
      GtTransitionTimingView *view
	= [ov makeViewWithIdentifier:ident owner:self];

      view.treeNode = item[0];
      view.key = item[1];

      return view;
    }

  return nil;
}

- (NSIndexSet *)outlineView:(NSOutlineView *)ov
     selectionIndexesForProposedSelection:(NSIndexSet *)indexes
{
  NSMutableIndexSet *ret = [NSMutableIndexSet indexSet];

  for (NSInteger idx = [indexes firstIndex]; idx != NSNotFound;
       idx = [indexes indexGreaterThanIndex:idx])
    {
      id item = [ov itemAtRow:idx];
      if ([item isKindOfClass:[NSArray class]])
	[ret addIndex:idx];
    }

  return ret;
}

/** NSTableViewDataSource methods. **/

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv
{
  return [_currentModule.moduleStates count] * 2;
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:
    (NSTableColumn *)col row:(NSInteger)row
{
  NSInteger state_idx = row >> 1;
  BOOL any = (row & 1) == 0;

  if ([[col identifier] isEqualToString:@"to"])
    any = !any;

  if (any)
    return @"Any";

  MgModuleState *state = _currentModule.moduleStates[state_idx];
  return state.name;
}

/** NSTableViewDelegate methods. **/

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
  NSTableView *tv = [note object];
  NSInteger row = [tv selectedRow];

  NSInteger state_idx = row >> 1;
  BOOL from_any = (row & 1) == 0;

  MgModuleState *state = _currentModule.moduleStates[state_idx];
  
  if (from_any)
    _fromState = nil, _toState = state;
  else
    _fromState = state, _toState = nil;

  [_items removeAllObjects];
  [_outlineView reloadData];
  [_outlineView expandItem:nil expandChildren:YES];
}

@end
