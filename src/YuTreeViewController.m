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
   addObserver:self selector:@selector(documentNodeChanged:)
   name:YuDocumentNodeDidChange object:self.controller.document];

  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(selectionChanged:)
   name:YuWindowControllerSelectionDidChange object:self.controller];

  for (NSTableColumn *col in [self.outlineView tableColumns])
    [[col dataCell] setVerticallyCentered:YES];

  [self documentNodeChanged:nil];

  [self.outlineView reloadData];
  [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)documentNodeChanged:(NSNotification *)note
{
  MgNode *rootNode = self.controller.document.documentNode;

  _tree = [[YuTreeNode alloc] initWithNode:rootNode parent:nil];

  [self.outlineView reloadData];
  [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)selectionChanged:(NSNotification *)note
{
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
    return _tree;
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
}

@end
