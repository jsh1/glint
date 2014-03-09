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

#import "YuTreeViewController.h"

#import "YuDocument.h"
#import "YuTreeNode.h"
#import "YuWindowController.h"

#import "AppKitExtensions.h"

@implementation YuTreeViewController

+ (NSString *)viewNibName
{
  return @"YuTreeView";
}

- (void)viewDidLoad
{
  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(documentGraphDidChange:)
   name:YuDocumentGraphDidChange object:self.controller.document];

  [self.controller.document addObserver:self forKeyPath:@"documentNode"
   options:0 context:NULL];

  [self.controller addObserver:self forKeyPath:@"selection" options:0
   context:NULL];

  for (NSTableColumn *col in [self.outlineView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];

  [self updateDocumentNode];
  [self updateSelection];

  [self.outlineView reloadData];
  [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)invalidate
{
  [self.controller.document removeObserver:self forKeyPath:@"documentNode"];
  [self.controller removeObserver:self forKeyPath:@"selection"];

  [super invalidate];
}

- (void)updateDocumentNode
{
  [self.outlineView reloadData];
  [self.outlineView expandItem:nil expandChildren:YES];
}

static void
expandItem(NSOutlineView *ov, YuTreeNode *tn)
{
  if (tn != nil)
    {
      expandItem(ov, tn.parent);
      [ov expandItem:tn];
    }
}

- (void)updateSelection
{
  NSArray *selection = self.controller.selection;

  for (YuTreeNode *tn in selection)
    expandItem(self.outlineView, tn.parent);

  [self.outlineView setSelectedItems:selection];
}

- (void)documentGraphDidChange:(NSNotification *)node
{
  [self.outlineView reloadData];
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
    return 1;
  else
    return [((YuTreeNode *)item).children count];
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)idx ofItem:(id)item
{
  if (item == nil)
    return self.controller.tree;
  else
    return ((YuTreeNode *)item).children[idx];
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
  return !((YuTreeNode *)item).leaf;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:
    (NSTableColumn *)col byItem:(id)item
{
  NSString *ident = [col identifier];

  return [((YuTreeNode *)item).node valueForKey:ident];
}

/** NSOutlineViewDelegate methods. **/

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
  self.controller.selection = [self.outlineView selectedItems];
}

@end
