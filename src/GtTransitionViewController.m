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
#import "GtTreeNode.h"
#import "GtWindowController.h"

#import "AppKitExtensions.h"

@implementation GtTransitionViewController
{
  GtTreeNode *_moduleNode;
  MgModuleLayer *_currentModule;
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

  [self updateDocumentNode];

  [self.outlineView reloadData];
  [self.outlineView expandItem:nil expandChildren:YES];
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

  [self.outlineView reloadData];
  [self.fromTableView reloadData];
  [self.toTableView reloadData];

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

  /* FIXME: not right. */

  [self.fromTableView setSelectedRow:row];
  [self.toTableView setSelectedRow:row];
}

- (void)documentGraphDidChange:(NSNotification *)note
{
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

/** NSOutlineViewDataSource methods. **/

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
  return 0;
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)idx ofItem:(id)item
{
  return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
  return NO;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:
    (NSTableColumn *)col byItem:(id)item
{
  return nil;
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object
    forTableColumn:(NSTableColumn *)col byItem:(id)item
{
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

@end
